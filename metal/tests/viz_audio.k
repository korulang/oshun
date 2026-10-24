// viz_audio — the kind-dispatched audio renderer, alone on the champagne
// wall. Four real mints through the bridge's file-open: two Siri Remote
// mic sessions (/tmp/omni_remote_mic_*.wav → kind 2, the waveform arm),
// one file NAMED .wav whose bytes aren't RIFF (kind 2, zero buckets —
// the honest bare rail, nothing invented), and one markdown doc (kind 0,
// the generic silk + id arm). Dispatch reads the bridge's kind field —
// res-kind — never the path; the two real wavs mint the same kind but
// draw different bars because the bytes differ, which is the whole
// point: the card IS the resource.
//
//   mkdir -p /tmp/omni_world
//   koruc run metal/tests/viz_audio.k
//   sips -s format png /tmp/viz_audio.bmp --out /tmp/viz_audio.png

import libs/host
import libs/metal
import libs/components
import std/bridge
import std/store
import std/io
import app/omni_img

std/store:new(world) { frame: 0[i64] }

[with]std/bridge:create(id: "omni", scope: "image", world: "/tmp/omni_world"): br
|> std/bridge:run(br, source: "file-open(path: \"/tmp/omni_remote_mic_1.wav\") | ok h |> say(text: \"minted 1\")\nfile-open(path: \"/tmp/omni_remote_mic_3.wav\") | ok h |> say(text: \"minted 3\")\nfile-open(path: \"/Users/larsde/src/oshun/challenges/visualizer/CATALOG.md\") | ok h |> say(text: \"minted doc\")\nfile-open(path: \"/tmp/not_really.wav\") | ok h |> say(text: \"minted fake\")")
    | result _ |> std/io:print.ln("turn result")
    | partial p |> std/io:print.ln("{{ p.report:s }}")
        |> app/omni_img:res-live(slot: 0) : l0
        |> app/omni_img:res-kind(slot: 0) : k0p
            |> app/omni_img:res-wave-n(slot: 0) : wn0
                |> app/omni_img:res-wave-rate(slot: 0) : wr0
                    |> app/omni_img:res-wave-secs(slot: 0) : ws0
                        |> std/io:print.ln("slot0 live={{ l0:d }} kind={{ k0p:d }} buckets={{ wn0:d }} rate={{ wr0:d }} secs={{ ws0:f }}")
                            |> app/omni_img:res-live(slot: 1) : l1
        |> app/omni_img:res-kind(slot: 1) : k1p
            |> app/omni_img:res-wave-n(slot: 1) : wn1
                |> app/omni_img:res-wave-rate(slot: 1) : wr1
                    |> app/omni_img:res-wave-secs(slot: 1) : ws1
                        |> std/io:print.ln("slot1 live={{ l1:d }} kind={{ k1p:d }} buckets={{ wn1:d }} rate={{ wr1:d }} secs={{ ws1:f }}")
                            |> app/omni_img:res-live(slot: 2) : l2
        |> app/omni_img:res-kind(slot: 2) : k2p
            |> std/io:print.ln("slot2 live={{ l2:d }} kind={{ k2p:d }}")
                |> app/omni_img:res-live(slot: 3) : l3
        |> app/omni_img:res-kind(slot: 3) : k3p
            |> app/omni_img:res-wave-n(slot: 3) : wn3
                |> std/io:print.ln("slot3 live={{ l3:d }} kind={{ k3p:d }} buckets={{ wn3:d }}")
                    |> libs/metal:window.open(width: 1180, height: 420, title: "visualizer — audio")
        | win w |> libs/metal:window.clear.color(win: w, r: 0.10, g: 0.10, b: 0.15)
            |> libs/metal:frames(win: w, count: 9999)
                ! frame f
                    |> std/store:stored { world.frame: world.frame + 1 }
                    // the room — champagne silk, same drape as the commander's
                    |> libs/metal:draw.roundrect(f, x: 0.0, y: 0.0, w: 1180.0, h: 420.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0)
                    // card 0 — slot 0: mic session 1
                    |> libs/metal:draw.panel(f, x: 60.0, y: 120.0, w: 240.0, h: 170.0, radius: 12.0, r: 0.97, g: 0.95, b: 0.89, a: 0.92, bw: 1.0, br: 0.80, bg: 0.70, bb: 0.55, ba: 0.5)
                    |> if (k0p == 2)
                        | then |> libs/components:waveform(f, slot: 0, x: 74.0, y: 134.0, w: 212.0, h: 128.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 74.0, y: 268.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "audio")
                    |> if (k0p == 0)
                        | then |> libs/metal:draw.text(f, x: 74.0, y: 190.0, size: 12.0, r: 0.16, g: 0.12, b: 0.08, a: 0.5, text: "document")
                    |> app/omni_img:res-id(slot: 0) : id0
                        |> libs/metal:draw.text(f, x: 74.0, y: 304.0, size: 11.0, r: 0.16, g: 0.12, b: 0.08, a: 0.8, text: id0)
                    // card 1 — slot 1: mic session 3 (different bytes, different bars)
                    |> libs/metal:draw.panel(f, x: 330.0, y: 120.0, w: 240.0, h: 170.0, radius: 12.0, r: 0.97, g: 0.95, b: 0.89, a: 0.92, bw: 1.0, br: 0.80, bg: 0.70, bb: 0.55, ba: 0.5)
                    |> if (k1p == 2)
                        | then |> libs/components:waveform(f, slot: 1, x: 344.0, y: 134.0, w: 212.0, h: 128.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 344.0, y: 268.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "audio")
                    |> if (k1p == 0)
                        | then |> libs/metal:draw.text(f, x: 344.0, y: 190.0, size: 12.0, r: 0.16, g: 0.12, b: 0.08, a: 0.5, text: "document")
                    |> app/omni_img:res-id(slot: 1) : id1
                        |> libs/metal:draw.text(f, x: 344.0, y: 304.0, size: 11.0, r: 0.16, g: 0.12, b: 0.08, a: 0.8, text: id1)
                    // card 2 — slot 2: the doc, generic arm (no waveform, no pixels)
                    |> libs/metal:draw.panel(f, x: 600.0, y: 120.0, w: 240.0, h: 170.0, radius: 12.0, r: 0.97, g: 0.95, b: 0.89, a: 0.92, bw: 1.0, br: 0.80, bg: 0.70, bb: 0.55, ba: 0.5)
                    |> if (k2p == 2)
                        | then |> libs/components:waveform(f, slot: 2, x: 614.0, y: 134.0, w: 212.0, h: 128.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 614.0, y: 268.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "audio")
                    |> if (k2p == 0)
                        | then |> libs/metal:draw.text(f, x: 614.0, y: 190.0, size: 12.0, r: 0.16, g: 0.12, b: 0.08, a: 0.5, text: "document")
                    |> app/omni_img:res-id(slot: 2) : id2
                        |> libs/metal:draw.text(f, x: 614.0, y: 304.0, size: 11.0, r: 0.16, g: 0.12, b: 0.08, a: 0.8, text: id2)
                    // card 3 — slot 3: named .wav, bytes aren't RIFF — the bare rail
                    |> libs/metal:draw.panel(f, x: 870.0, y: 120.0, w: 240.0, h: 170.0, radius: 12.0, r: 0.97, g: 0.95, b: 0.89, a: 0.92, bw: 1.0, br: 0.80, bg: 0.70, bb: 0.55, ba: 0.5)
                    |> if (k3p == 2)
                        | then |> libs/components:waveform(f, slot: 3, x: 884.0, y: 134.0, w: 212.0, h: 128.0, a: 0.9)
                            |> libs/metal:draw.text(f, x: 884.0, y: 268.0, size: 10.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "audio")
                    |> if (k3p == 0)
                        | then |> libs/metal:draw.text(f, x: 884.0, y: 190.0, size: 12.0, r: 0.16, g: 0.12, b: 0.08, a: 0.5, text: "document")
                    |> app/omni_img:res-id(slot: 3) : id3
                        |> libs/metal:draw.text(f, x: 884.0, y: 304.0, size: 11.0, r: 0.16, g: 0.12, b: 0.08, a: 0.8, text: id3)
                    |> if (world.frame == 60)
                        | then |> libs/metal:window.snap(path: "/tmp/viz_audio.bmp")
                    |> if (world.frame == 75)
                        | then |> libs/host:quit()
                ! key-down k when k.code == 53 |> libs/host:quit()
                ! close |> libs/host:quit()
                | done w2 |> libs/metal:window.close(win: w2) |> std/bridge:close(br) |> std/io:print.ln("viz_audio: closed")
        | err e |> std/bridge:close(br) |> std/io:print.ln("metal init failed: {{ e:s }}")
    | error e |> std/bridge:close(br) |> std/io:print.ln("mint turn failed: {{ e.message:s }}")
