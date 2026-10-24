// viz_doc — the kind-dispatched document renderer, alone on the champagne
// wall. Four real mints through the bridge's file-open: two markdown docs
// (the challenge's own CHALLENGE.md and the repo's SCENE.md → kind 0, the
// docpage arm — each card typeset in its resource's own leading lines),
// one Mach-O binary with a doc kind (/bin/zsh → kind 0, zero lines — the
// honest empty card, nothing invented), and one Siri Remote mic session
// (kind 2 → the waveform arm, proving the dispatch ladder picks the right
// renderer per resource). Dispatch reads the bridge's kind field —
// res-kind — never the path; the two docs mint the same kind but draw
// different text because the bytes differ, which is the whole point:
// the card IS the resource.
//
//   mkdir -p /tmp/omni_world
//   koruc run metal/tests/viz_doc.k
//   sips -s format png /tmp/viz_doc.bmp --out /tmp/viz_doc.png

import libs/host
import libs/metal
import libs/components
import std/bridge
import std/store
import std/io
import app/omni_img

std/store:new(world) { frame: 0[i64] }

[with]std/bridge:create(id: "omni", scope: "image", world: "/tmp/omni_world"): br
|> std/bridge:run(br, source: "file-open(path: \"/Users/larsde/src/oshun/.claude/worktrees/replay-visualizer-02/challenges/visualizer/CHALLENGE.md\") | ok h |> say(text: \"minted challenge\")\nfile-open(path: \"/Users/larsde/src/oshun/.claude/worktrees/replay-visualizer-02/SCENE.md\") | ok h |> say(text: \"minted scene\")\nfile-open(path: \"/bin/zsh\") | ok h |> say(text: \"minted binary\")\nfile-open(path: \"/tmp/omni_remote_mic_2.wav\") | ok h |> say(text: \"minted wav\")")
    | result _ |> std/io:print.ln("turn result")
    | partial p |> std/io:print.ln("{{ p.report:s }}")
        |> app/omni_img:res-live(slot: 0) : l0
        |> app/omni_img:res-kind(slot: 0) : k0p
            |> app/omni_img:res-doc-n(slot: 0) : dn0
                |> std/io:print.ln("slot0 live={{ l0:d }} kind={{ k0p:d }} lines={{ dn0:d }}")
                    |> app/omni_img:res-live(slot: 1) : l1
        |> app/omni_img:res-kind(slot: 1) : k1p
            |> app/omni_img:res-doc-n(slot: 1) : dn1
                |> std/io:print.ln("slot1 live={{ l1:d }} kind={{ k1p:d }} lines={{ dn1:d }}")
                    |> app/omni_img:res-live(slot: 2) : l2
        |> app/omni_img:res-kind(slot: 2) : k2p
            |> app/omni_img:res-doc-n(slot: 2) : dn2
                |> std/io:print.ln("slot2 live={{ l2:d }} kind={{ k2p:d }} lines={{ dn2:d }}")
                    |> app/omni_img:res-live(slot: 3) : l3
        |> app/omni_img:res-kind(slot: 3) : k3p
            |> app/omni_img:res-wave-n(slot: 3) : wn3
                |> std/io:print.ln("slot3 live={{ l3:d }} kind={{ k3p:d }} buckets={{ wn3:d }}")
                    |> libs/metal:window.open(width: 1180, height: 420, title: "visualizer — document")
        | win w |> libs/metal:window.clear.color(win: w, r: 0.10, g: 0.10, b: 0.15)
            |> libs/metal:frames(win: w, count: 9999)
                ! frame f
                    |> std/store:stored { world.frame: world.frame + 1 }
                    // the room — champagne silk, same drape as the commander's
                    |> libs/metal:draw.roundrect(f, x: 0.0, y: 0.0, w: 1180.0, h: 420.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0)
                    // card 0 — slot 0: the challenge's own CHALLENGE.md
                    |> libs/metal:draw.panel(f, x: 60.0, y: 110.0, w: 240.0, h: 190.0, radius: 12.0, r: 0.97, g: 0.95, b: 0.89, a: 0.92, bw: 1.0, br: 0.80, bg: 0.70, bb: 0.55, ba: 0.5)
                    |> if (k0p == 0)
                        | then |> libs/components:docpage(f, slot: 0, x: 74.0, y: 124.0, w: 212.0, h: 148.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 74.0, y: 280.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "document")
                    |> if (k0p == 2)
                        | then |> libs/components:waveform(f, slot: 0, x: 74.0, y: 124.0, w: 212.0, h: 128.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 74.0, y: 280.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "audio")
                    |> app/omni_img:res-id(slot: 0) : id0
                        |> libs/metal:draw.text(f, x: 74.0, y: 316.0, size: 11.0, r: 0.16, g: 0.12, b: 0.08, a: 0.8, text: id0)
                    // card 1 — slot 1: SCENE.md (different bytes, different lines)
                    |> libs/metal:draw.panel(f, x: 330.0, y: 110.0, w: 240.0, h: 190.0, radius: 12.0, r: 0.97, g: 0.95, b: 0.89, a: 0.92, bw: 1.0, br: 0.80, bg: 0.70, bb: 0.55, ba: 0.5)
                    |> if (k1p == 0)
                        | then |> libs/components:docpage(f, slot: 1, x: 344.0, y: 124.0, w: 212.0, h: 148.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 344.0, y: 280.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "document")
                    |> if (k1p == 2)
                        | then |> libs/components:waveform(f, slot: 1, x: 344.0, y: 124.0, w: 212.0, h: 128.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 344.0, y: 280.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "audio")
                    |> app/omni_img:res-id(slot: 1) : id1
                        |> libs/metal:draw.text(f, x: 344.0, y: 316.0, size: 11.0, r: 0.16, g: 0.12, b: 0.08, a: 0.8, text: id1)
                    // card 2 — slot 2: a Mach-O binary minted as a doc — zero
                    // decoded lines, the honest empty card
                    |> libs/metal:draw.panel(f, x: 600.0, y: 110.0, w: 240.0, h: 190.0, radius: 12.0, r: 0.97, g: 0.95, b: 0.89, a: 0.92, bw: 1.0, br: 0.80, bg: 0.70, bb: 0.55, ba: 0.5)
                    |> if (k2p == 0)
                        | then |> libs/components:docpage(f, slot: 2, x: 614.0, y: 124.0, w: 212.0, h: 148.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 614.0, y: 280.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "document")
                    |> if (k2p == 2)
                        | then |> libs/components:waveform(f, slot: 2, x: 614.0, y: 124.0, w: 212.0, h: 128.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 614.0, y: 280.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "audio")
                    |> app/omni_img:res-id(slot: 2) : id2
                        |> libs/metal:draw.text(f, x: 614.0, y: 316.0, size: 11.0, r: 0.16, g: 0.12, b: 0.08, a: 0.8, text: id2)
                    // card 3 — slot 3: a real mic session — kind 2 takes the
                    // waveform arm, the other half of the dispatch ladder
                    |> libs/metal:draw.panel(f, x: 870.0, y: 110.0, w: 240.0, h: 190.0, radius: 12.0, r: 0.97, g: 0.95, b: 0.89, a: 0.92, bw: 1.0, br: 0.80, bg: 0.70, bb: 0.55, ba: 0.5)
                    |> if (k3p == 0)
                        | then |> libs/components:docpage(f, slot: 3, x: 884.0, y: 124.0, w: 212.0, h: 148.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 884.0, y: 280.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "document")
                    |> if (k3p == 2)
                        | then |> libs/components:waveform(f, slot: 3, x: 884.0, y: 124.0, w: 212.0, h: 128.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 884.0, y: 280.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "audio")
                    |> app/omni_img:res-id(slot: 3) : id3
                        |> libs/metal:draw.text(f, x: 884.0, y: 316.0, size: 11.0, r: 0.16, g: 0.12, b: 0.08, a: 0.8, text: id3)
                    |> if (world.frame == 60)
                        | then |> libs/metal:window.snap(path: "/tmp/viz_doc.bmp")
                    |> if (world.frame == 75)
                        | then |> libs/host:quit()
                ! key-down k when k.code == 53 |> libs/host:quit()
                ! close |> libs/host:quit()
                | done w2 |> libs/metal:window.close(win: w2) |> std/bridge:close(br) |> std/io:print.ln("viz_doc: closed")
        | err e |> std/bridge:close(br) |> std/io:print.ln("metal init failed: {{ e:s }}")
    | error e |> std/bridge:close(br) |> std/io:print.ln("mint turn failed: {{ e.message:s }}")
