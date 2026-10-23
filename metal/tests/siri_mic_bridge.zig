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
    out.writeAll(std.mem.sliceAsBytes(pcm_buf[0..@intCast(n)])) catch {};
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

pub fn main() !void {
    var args = std.process.args();
    _ = args.next();
    const device = args.next() orelse "C08SD0RX2330";
    var att_handle: u16 = 0x0035;
    if (args.next()) |hs| att_handle = try std.fmt.parseInt(u16, hs, 0);

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
