---
type: belief
id: frag-siri-remote-mic-needs-non-apple-ble
provenance: session
ts: 2026-10-23
---

# The Siri Remote microphone IS reachable on macOS — by snooping, not commanding

**Corrected 2026-10-23 (same day it was written — the conclusion was wrong within
hours).** The prior line said remote-mic audio "requires a non-Apple BLE host."
That was false: GoatRemote streams real decoded audio from this remote on this
Mac, confirmed five sessions, Opus on ATT handle `0x0035`, PCM in a shm ring.

What was measured and still stands — the *write/command* path is closed:

- `IOHIDDeviceSetReport` Output writes: `0/256` accepted across all 7 virtual
  interfaces — rejected before the wire.
- Feature writes "succeed" but land on the wrong GATT report.
- CoreBluetooth hides HID service `0x1812` from third-party sessions.
- Forged `CBCharacteristic` writes reach bluetoothd and die at
  `kCBMsgArgResult = 902` — the daemon gates on the session's
  discovered-attribute table.
- DriverKit/kext replacement dead on AMFI even with SIP off (SiriRemoteForge).

What the prior line missed — **the audio doesn't need our activation at all.** The
remote is host-activated, and macOS's *own* HOGP stack inside bluetoothd does the
activating for its own session: subscribes the audio CCCD at connect, presses on
the mic button make the remote stream `0xFA` Opus reports on the wire — while
IOHID hides them from user space (they route to `AppleEmbeddedBluetoothAudio`).
The bytes exist; we were watching a presentation layer.

The read path that works (all replicable, zero GoatRemote code at runtime):

1. A Bluetooth logging mobileconfig enables deep HCI/firmware tracing — plain
   plist, we can author our own.
2. Apple's `packetlogger convert -s -f nhdr` (Additional Tools for Xcode, free)
   streams live HCI as text — requires root for live capture.
3. ACL→L2CAP→ATT reassembly → unwrap `0xFA` (seq u16, opus_len, CELT WB 20ms
   mono) → libopus → PCM. ~300 lines, the wire format is documented in
   `azais-corentin/siri-remote`.

Architecture for OMNI: a root-scoped helper runs packetlogger → reassembler →
opus → PCM into a socket/shm; omni consumes it as a bridge-resident resource.
Buttons stay on the existing IOHID seize. The input plane is transport-agnostic
*by choice* now (HID + HCI-snoop + future Linux relay), not because a wall
forced it.

Product note: no $12 dongle, no second machine, no re-pairing — the relay plan
is demoted to the non-Apple-OS story. Root helper + profile install are the only
user-visible friction, same as GoatRemote's.
