// siri_mic_bridge — HCI nhdr text (packetlogger convert -s -f nhdr) on stdin,
// PCM s16le 48kHz mono on stdout. ACL/L2CAP/ATT reassembly + Opus decode
// for the Siri Remote audio channel (ATT notify handle, default 0x0035).
//
//   sudo packetlogger convert -s -f nhdr | ./siri_mic_bridge [DEVICE_NAME] > out.pcm

const std = @import("std");

extern fn opus_decoder_create(Fs: c_int, channels: c_int, @"error": *c_int) ?*anyopaque;
extern fn opus_decoder_destroy(st: ?*anyopaque) void;
extern fn opus_decode(st: ?*anyopaque, data: [*c]const u8, len: c_int, pcm: [*c]i16, frame_size: c_int, decode_fec: c_int) c_int;

const MAX_L2CAP = 2048;

const Pending = struct {
    l2cap_len: usize,
    buf: [MAX_L2CAP]u8,
    len: usize,
};

var line_buf: [8192]u8 = undefined;
var hex_raw: [4096]u8 = undefined;
var pending: Pending = undefined;
var have_pending = false;

fn hexNib(c: u8) ?u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => null,
    };
}

fn processAtt(dec: ?*anyopaque, att: []const u8, att_handle: u16, out: anytype, stats: anytype) void {
    if (att.len < 8 or att[0] != 0x1B) return; // Handle Value Notification only
    const h = @as(u16, att[1]) | (@as(u16, att[2]) << 8);
    if (h != att_handle) return;
    const v = att[3..];
    if (v.len < 6) return;
    const seq = @as(u16, v[2]) | (@as(u16, v[3]) << 8);
    const olen = v[4];
    if (v.len < 5 + @as(usize, olen)) return;
    const frame = v[5 .. 5 + olen];
    var pcm_buf: [4096]i16 = undefined;
    const n = opus_decode(dec, frame.ptr, @intCast(frame.len), &pcm_buf, pcm_buf.len, 0);
    if (n <= 0) return;
    stats.frames += 1;
    stats.last_seq = seq;
    // session boundary: the remote restarts seq at 0 on every mic-button press
    if (wav_file != null and session_frames > 0 and last_seq_in_session != null and seq < last_seq_in_session.?) {
        openSessionWav() catch {};
    }
    last_seq_in_session = seq;
    session_frames += 1;
    const bytes = std.mem.sliceAsBytes(pcm_buf[0..@intCast(n)]);
    out.writeAll(bytes) catch {};
    if (wav_file) |f| {
        f.seekFromEnd(0) catch {};
        f.writeAll(bytes) catch {};
        wav_bytes += bytes.len;
        wavWriteHeader();
    }
}

fn feedAcl(dec: ?*anyopaque, conn: u16, pb: u8, payload: []const u8, att_handle: u16, out: anytype, stats: anytype) void {
    _ = conn;
    if (pb == 0x1 or have_pending) {
        if (!have_pending) return; // orphan continuation
        if (pending.len + payload.len > MAX_L2CAP) {
            have_pending = false;
            return;
        }
        @memcpy(pending.buf[pending.len .. pending.len + payload.len], payload);
        pending.len += payload.len;
        if (pending.len >= pending.l2cap_len) {
            processAtt(dec, pending.buf[0..pending.l2cap_len], att_handle, out, stats);
            have_pending = false;
        }
        return;
    }
    if (payload.len < 4) return;
    const l2len = @as(usize, payload[0]) | (@as(usize, payload[1]) << 8);
    const cid = @as(u16, payload[2]) | (@as(u16, payload[3]) << 8);
    const body = payload[4..];
    if (body.len < l2len) {
        if (l2len > MAX_L2CAP) return;
        pending.l2cap_len = l2len;
        @memcpy(pending.buf[0..body.len], body);
        pending.len = body.len;
        have_pending = true;
        return;
    }
    if (cid != 0x0004) return;
    processAtt(dec, body[0..l2len], att_handle, out, stats);
}

var wav_file: ?std.fs.File = null;
var wav_bytes: u64 = 0;
var session_idx: u32 = 0;
var session_frames: u64 = 0;
var last_seq_in_session: ?u16 = null;
var link_path_buf: [4096]u8 = undefined;
var link_path: []const u8 = &.{};
var stem_buf: [4000]u8 = undefined;
var stem: []const u8 = &.{};
var real_path_buf: [4096]u8 = undefined;

fn wavWriteHeader() void {
    const f = wav_file orelse return;
    const save = f.getPos() catch 0;
    f.seekTo(0) catch return;
    var hdr: [44]u8 = undefined;
    @memcpy(hdr[0..4], "RIFF");
    std.mem.writeInt(u32, hdr[4..8], @intCast(@min(wav_bytes + 36, 0xFFFFFFFF)), .little);
    @memcpy(hdr[8..12], "WAVE");
    @memcpy(hdr[12..16], "fmt ");
    std.mem.writeInt(u32, hdr[16..20], 16, .little);
    std.mem.writeInt(u16, hdr[20..22], 1, .little); // PCM
    std.mem.writeInt(u16, hdr[22..24], 1, .little); // mono
    std.mem.writeInt(u32, hdr[24..28], 48000, .little);
    std.mem.writeInt(u32, hdr[28..32], 48000 * 2, .little);
    std.mem.writeInt(u16, hdr[32..34], 2, .little);
    std.mem.writeInt(u16, hdr[34..36], 16, .little);
    @memcpy(hdr[36..40], "data");
    std.mem.writeInt(u32, hdr[40..44], @intCast(@min(wav_bytes, 0xFFFFFFFF)), .little);
    f.writeAll(&hdr) catch {};
    f.seekTo(save) catch {};
}

fn openSessionWav() !void {
    if (wav_file) |f| {
        f.close();
        wav_file = null;
    }
    session_idx += 1;
    wav_bytes = 0;
    session_frames = 0;
    last_seq_in_session = null;
    const real = std.fmt.bufPrint(&real_path_buf, "{s}_{d}.wav", .{ stem, session_idx }) catch return;
    wav_file = std.fs.cwd().createFile(real, .{ .truncate = true }) catch null;
    wavWriteHeader();
    // repoint the stable link at the live session file (atomic via rename)
    if (link_path.len > 0) {
        var tmp_buf: [4096]u8 = undefined;
        const tmp = std.fmt.bufPrint(&tmp_buf, "{s}.tmp", .{link_path}) catch return;
        std.posix.unlink(tmp) catch {};
        std.posix.symlink(real, tmp) catch return;
        std.posix.rename(tmp, link_path) catch {};
    }
}

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    const device = args.next() orelse "C08SD0RX2330";
    var att_handle: u16 = 0x0035;
    var wav_path: ?[]const u8 = null;
    while (args.next()) |a| {
        if (std.mem.eql(u8, a, "--wav")) {
            wav_path = args.next();
        } else {
            att_handle = try std.fmt.parseInt(u16, a, 0);
        }
    }
    if (wav_path) |p| {
        // p is the stable link name; sessions land as <stem>_<n>.wav beside it
        if (std.mem.endsWith(u8, p, ".wav")) {
            stem = stem_buf[0 .. p.len - 4];
            @memcpy(stem_buf[0 .. p.len - 4], p[0 .. p.len - 4]);
        } else {
            stem = stem_buf[0..p.len];
            @memcpy(stem_buf[0..p.len], p);
        }
        link_path = link_path_buf[0..p.len];
        @memcpy(link_path_buf[0..p.len], p);
        std.posix.unlink(link_path) catch {};
        try openSessionWav();
    }

    var oerr: c_int = 0;
    const dec = opus_decoder_create(48000, 1, &oerr) orelse return error.OpusInit;
    defer opus_decoder_destroy(dec);
    if (oerr != 0) return error.OpusInit;

    const stdin = std.fs.File.stdin();

    var out_buf: [8192]u8 = undefined;
    var out_w = std.fs.File.stdout().writer(&out_buf);
    const out = &out_w.interface;

    var stats = struct { frames: usize = 0, last_seq: u16 = 0 }{};

    var carry: [4096]u8 = undefined;
    var carry_len: usize = 0;
    var read_buf: [8192]u8 = undefined;

    while (true) {
        const n = try stdin.read(&read_buf);
        if (n == 0) break;
        var start: usize = 0;
        var i: usize = 0;
        while (i < n) : (i += 1) {
            if (read_buf[i] != '\n') continue;
            var line: []u8 = undefined;
            if (carry_len > 0) {
                const total = carry_len + (i - start);
                if (total <= carry.len) {
                    @memcpy(carry[carry_len..total], read_buf[start..i]);
                    line = carry[0..total];
                } else {
                    line = carry[0..carry_len];
                }
                carry_len = 0;
            } else {
                line = read_buf[start..i];
            }
            start = i + 1;
            handleLine(line, device, dec, att_handle, out, &stats);
        }
        if (start < n) {
            const rem = n - start;
            if (carry_len + rem <= carry.len) {
                @memcpy(carry[carry_len .. carry_len + rem], read_buf[start..n]);
                carry_len += rem;
            }
        }
    }
    if (carry_len > 0) handleLine(carry[0..carry_len], device, dec, att_handle, out, &stats);
    try out.flush();
    std.debug.print("siri_mic_bridge: {d} frames decoded, last seq {d}\n", .{ stats.frames, stats.last_seq });
}

fn handleLine(line: []const u8, device: []const u8, dec: ?*anyopaque, att_handle: u16, out: anytype, stats: anytype) void {
        // "Oct 23 16:32:53.577  C08SD0RX2330  0x0053  RECV  53 20 ..."
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        _ = it.next(); // month
        _ = it.next(); // day
        _ = it.next(); // time
        const dev = it.next() orelse return;
        _ = it.next(); // conn handle field
        const dir = it.next() orelse return;
        if (!std.mem.eql(u8, dev, device)) return;
        if (!std.mem.eql(u8, dir, "RECV")) return;

        var raw_len: usize = 0;
        while (it.next()) |tok| {
            if (tok.len != 2) break;
            const hi = hexNib(tok[0]) orelse break;
            const lo = hexNib(tok[1]) orelse break;
            if (raw_len >= hex_raw.len) break;
            hex_raw[raw_len] = (hi << 4) | lo;
            raw_len += 1;
        }
        if (raw_len < 4) return;
        const acl_hdr = @as(u16, hex_raw[0]) | (@as(u16, hex_raw[1]) << 8);
        const conn = acl_hdr & 0x0FFF;
        const pb: u8 = @intCast((acl_hdr >> 12) & 0x3);
        const dlen = @as(usize, hex_raw[2]) | (@as(usize, hex_raw[3]) << 8);
        const avail = @min(dlen, raw_len - 4);
        feedAcl(dec, conn, pb, hex_raw[4 .. 4 + avail], att_handle, out, stats);
}
