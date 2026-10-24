// code_diffview — the `diffview` component on a composed surface, headless.
//
// The demo mints a real .diff file — the bytes below are verbatim
// `git show` output from this repo's own history (the omni_img doc-seam
// landing: 3 hunks, mixed +/- and context) — write-file puts them on
// disk, diff-load parses the real unified grammar, and diffview draws
// what the bytes ARE: old|new gutter from the declared ranges, added
// green / removed red / context pearl, @@ hunk headers in champagne,
// hunks arriving staggered over the first ~60 frames on an ink silk
// card in the champagne room.
//
//   koruc run metal/tests/code_diffview.k
//   sips -s format png /tmp/code_diffview.bmp --out /tmp/code_diffview.png

import libs/metal
import libs/components/code_diffview
import std/store
import std/io
import std/fs

std/store:new(world) { frame: 0[i64], slot: 0[i64], fnt: 0[i64] }

std/fs:write-file(path: "/tmp/code_diffview_sample.diff", content: "diff --git a/metal/tests/omni_img.kz b/metal/tests/omni_img.kz\nindex e5f8bb5..67e32b4 100644\n--- a/metal/tests/omni_img.kz\n+++ b/metal/tests/omni_img.kz\n@@ -80,6 +80,8 @@ var kinds: [MAX_RESES]i64 = .{0} ** MAX_RESES;\n var last_minted_buf: [16]u8 = undefined;\n var last_minted_len: usize = 0;\n \n+var transcript_buf: [MAX_RESES][4096]u8 = undefined;\n+\n var mint_seed: u64 = 0;\n var mint_count: u32 = 0;\n \n@@ -246,10 +248,15 @@ fn decodeDoc(slot: usize) void {\n         $mod.opened += 1;\n     }\n     $mod.files[slot] = f;\n-    const n = @min(path.len, 255);\n-    @memcpy($mod.path_buf[slot][0..n], path[0..n]);\n+    // Resolve through symlinks — a card minted on the remote-mic link\n+    // should name the session it pointed at, and sidecars (.txt\n+    // transcripts) live beside the real file, not the link.\n+    var resolved: [std.fs.max_path_bytes]u8 = undefined;\n+    const real = std.fs.cwd().realpath(path, &resolved) catch path;\n+    const n = @min(real.len, 255);\n+    @memcpy($mod.path_buf[slot][0..n], real[0..n]);\n     $mod.path_len[slot] = n;\n-    $mod.kinds[slot] = if (isImage(path)) 1 else if (isAudio(path)) 2 else 0;\n+    $mod.kinds[slot] = if (isImage(real)) 1 else if (isAudio(real)) 2 else 0;\n     if ($mod.kinds[slot] == 2) decodeWave(slot);\n     if ($mod.kinds[slot] == 0) decodeDoc(slot);\n \n@@ -362,6 +369,41 @@ fn decodeDoc(slot: usize) void {\n     return $mod.kinds[s];\n }\n \n+// The transcript seam — a voice session's sidecar text, when the\n+// Whistle watcher has landed it. Re-read per call on purpose: the card\n+// mints at button-release and the transcript arrives a beat later, so a\n+// stale read would never see it land. Absent or empty sidecar → \"\".\n+// `res-transcript-n` is the byte count for the draw-side conditional.\n+~[retain]pub tor res-transcript { slot: i64 } -> string\n+\n+~proc res-transcript|zig {\n+    const s: usize = @intCast(@max(0, @min(slot, MAX_RESES - 1)));\n+    const n = transcriptRead(s);\n+    return transcript_buf[s][0..n];\n+}\n+\n+// Byte count — 0 doubles as \"no transcript\", matching kinds==0 docs\n+// that decoded nothing: the surface reads the number, not a flag.\n+~[retain]pub tor res-transcript-n { slot: i64 } -> i64\n+\n+~proc res-transcript-n|zig {\n+    const s: usize = @intCast(@max(0, @min(slot, MAX_RESES - 1)));\n+    return transcriptRead(s);\n+}\n+\n fn isImage(p: []const u8) bool {\n")
| written |> libs/components/code_diffview:diff-load(path: "/tmp/code_diffview_sample.diff")
    | ok sl |> std/store:stored { world.slot: sl }
        |> libs/metal:offscreen.open(width: 1080, height: 700, scale: 2.0)
            | surf s |> libs/metal:offscreen.clear.color(s, r: 0.91, g: 0.85, b: 0.72)
                |> libs/components/code_diffview:diff-font(path: "/System/Library/Fonts/SFNSMono.ttf")
                    | font ft |> std/store:stored { world.fnt: ft }
                    | err fe |> std/io:print.ln("code_diffview: font failed {{ fe:s }}")
                |> for(0..64)
                    ! else _ |> _
                    ! each _ |> libs/metal:offscreen.frame(s)
                        ! frame f
                            |> std/store:stored { world.frame: world.frame + 1 }
                            // the room — the champagne silk drape
                            |> libs/metal:draw.silk(f, x: 0.0, y: 0.0, w: 1080.0, h: 700.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.35, folds: 3.0, sheen: 0.7, pearl: 0.45)
                            // a pearl halo where the card lands
                            |> libs/metal:draw.silk(f, x: 200.0, y: 130.0, w: 680.0, h: 460.0, radius: 210.0, r: 0.97, g: 0.93, b: 0.82, a: 0.35, angle: 0.35, folds: 2.0, sheen: 0.8, pearl: 0.9)
                            // the component — the diff drifts up 6 lines
                            // as the card eases, hunks stagger in behind
                            |> libs/components/code_diffview:diff-ease(u: @max(0.0, @min(1.0, @as(f64, @floatFromInt(world.frame)) / 30.0 * 1.4))) : sc
                            |> libs/components/code_diffview:diffview(f, world.slot, face: world.fnt, x: 140.0, y: 40.0, w: 800.0, h: 590.0,
                                scroll: 6.0 * (1.0 - sc),
                                t: @as(f64, @floatFromInt(world.frame)) / 30.0, a: 1.0)
                            // the caption — system face, the demo's claim
                            |> libs/metal:draw.text(f, x: 300.0, y: 660.0, size: 13.0, r: 0.42, g: 0.34, b: 0.22, a: 0.8, text: "the unified-diff surface — added / removed / context, read off real bytes")
                            // mid-flight snap — hunks still arriving
                            |> if (world.frame == 26)
                                | then |> libs/metal:offscreen.snap(s, path: "/tmp/code_diffview_arrive.bmp")
                        | done _
                |> libs/metal:offscreen.snap(s, path: "/tmp/code_diffview.bmp")
                |> libs/metal:offscreen.close(s)
            | err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
    | err e |> std/io:print.ln("code_diffview: diff-load failed {{ e:s }}")
| failed e |> std/io:print.ln("code_diffview: write-file failed {{ e:s }}")
