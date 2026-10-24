// code_turnview — the turn renderer on a composed surface, headless.
// Four real remote-mic gate sidecars (real voice turns against the ACP
// bridge: utterance text, verdict, issued wire command) render as turn
// cards on a champagne silk bed: a full acp turn (prompt + verdict note +
// reply + tool row), a second acp turn, a no-match turn (prompt + note,
// no reply, no wire), and the empty verdict (the real empty state).
// Cards cascade in on an 8-frame offset; each card's rows stagger on a
// 5-frame cadence. A mid-motion snap lands beside the settled one.
// tv-font loads SF Mono into metal's registry (the offscreen path can't
// take font.load's window); the wire rows' kind + detail ride it.
//
//   koruc run metal/tests/code_turnview.k
//   sips -s format png /tmp/code_turnview.bmp --out /tmp/code_turnview.png
import libs/metal
import libs/components/code_turnview
import std/store
import std/io

std/store:new(world) { frame: 0[i64], fnt: 0[i64] }

libs/components/code_turnview:tv-font(path: "/System/Library/Fonts/SFNSMono.ttf")
| font ft |> std/store:stored { world.fnt: ft }
| err e |> std/io:print.ln("code_turnview: font failed {{ e:s }}")

libs/metal:offscreen.open(width: 720, height: 600, scale: 2.0)
| surf s |> libs/metal:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
         |> for(0..52)
             ! each _ |> libs/metal:offscreen.frame(s)
                 ! frame f
                     |> std/store:stored { world.frame: world.frame + 1 }
                     // the room — champagne silk drape, the commander's bed
                     |> libs/metal:draw.silk(f, x: 0.0, y: 0.0, w: 720.0, h: 600.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.35, folds: 3.0, sheen: 0.7, pearl: 0.45)
                     // the surface's own header — the session this is
                     |> libs/metal:draw.text(f, x: 48.0, y: 30.0, size: 14.0, r: 0.16, g: 0.12, b: 0.08, a: 0.75, text: "omni remote mic — session replay")
                     |> libs/metal:draw.text(f, x: 48.0, y: 50.0, size: 9.5, r: 0.16, g: 0.12, b: 0.08, a: 0.4, text: "four real turns · /tmp/omni_remote_mic_*.gate.json")
                     // the turns — real sidecars, an 8-frame cascade
                     |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_33.gate.json", face: world.fnt, x: 48.0, y: 72.0, w: 624.0, h: 112.0, t: @as(f64, @floatFromInt(world.frame)) - 0.0, a: 1.0)
                     |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_36.gate.json", face: world.fnt, x: 48.0, y: 196.0, w: 624.0, h: 112.0, t: @as(f64, @floatFromInt(world.frame)) - 8.0, a: 1.0)
                     |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_17.gate.json", face: world.fnt, x: 48.0, y: 320.0, w: 624.0, h: 112.0, t: @as(f64, @floatFromInt(world.frame)) - 16.0, a: 1.0)
                     |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_15.gate.json", face: world.fnt, x: 48.0, y: 444.0, w: 624.0, h: 112.0, t: @as(f64, @floatFromInt(world.frame)) - 24.0, a: 1.0)
                 | done _
         |> libs/metal:offscreen.snap(s, path: "/tmp/code_turnview_enter.bmp")
         |> for(0..8)
             ! each _ |> libs/metal:offscreen.frame(s)
                 ! frame f
                     |> std/store:stored { world.frame: world.frame + 1 }
                     |> libs/metal:draw.silk(f, x: 0.0, y: 0.0, w: 720.0, h: 600.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.35, folds: 3.0, sheen: 0.7, pearl: 0.45)
                     |> libs/metal:draw.text(f, x: 48.0, y: 30.0, size: 14.0, r: 0.16, g: 0.12, b: 0.08, a: 0.75, text: "omni remote mic — session replay")
                     |> libs/metal:draw.text(f, x: 48.0, y: 50.0, size: 9.5, r: 0.16, g: 0.12, b: 0.08, a: 0.4, text: "four real turns · /tmp/omni_remote_mic_*.gate.json")
                     |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_33.gate.json", face: world.fnt, x: 48.0, y: 72.0, w: 624.0, h: 112.0, t: @as(f64, @floatFromInt(world.frame)) - 0.0, a: 1.0)
                     |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_36.gate.json", face: world.fnt, x: 48.0, y: 196.0, w: 624.0, h: 112.0, t: @as(f64, @floatFromInt(world.frame)) - 8.0, a: 1.0)
                     |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_17.gate.json", face: world.fnt, x: 48.0, y: 320.0, w: 624.0, h: 112.0, t: @as(f64, @floatFromInt(world.frame)) - 16.0, a: 1.0)
                     |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_15.gate.json", face: world.fnt, x: 48.0, y: 444.0, w: 624.0, h: 112.0, t: @as(f64, @floatFromInt(world.frame)) - 24.0, a: 1.0)
                 | done _
         |> libs/metal:offscreen.snap(s, path: "/tmp/code_turnview.bmp")
         |> libs/metal:offscreen.close(s)
         |> std/io:print.ln("code_turnview: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
