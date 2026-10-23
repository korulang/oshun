---
type: belief
id: frag-siri-remote-mic-needs-non-apple-ble
provenance: session
ts: 2026-10-23
---

# The Siri Remote microphone cannot be activated from a Mac — full stop

Measured 2026-10-23, product `0x0315` (3rd-gen remote, serial `C08SD0RX2330`), against
every public and private surface:

- Audio is **host-activated**, not button-gated: holding the mic button emits only the
  `0x0c/0x04` usage press — zero `0xFA` reports — until the paired host writes input-enable
  `0xAF` to ATT handle `0x001d` and enables notifications on `0x0023` (CCCD `0x0024`).
  Wire format: report `0xFA`, 99-byte payloads, length-prefixed Opus (CELT WB, 20 ms mono).
  Documented and working in `azais-corentin/siri-remote` (Linux/BlueZ).

- macOS severs every write path:
  - `IOHIDDeviceSetReport` Output type: `0/256` report IDs accepted on all 7 virtual
    interfaces — rejected before the wire.
  - Feature writes "succeed" but map to the wrong GATT report; remote refuses (ATT error).
  - CoreBluetooth hides HID service `0x1812` from third-party sessions entirely —
    discovery returns only `180A`/`180F`, even for an unpaired remote.
  - Forged `CBCharacteristic` objects reach bluetoothd correctly (raw ATT handles in the
    XPC payload — verified via swizzled `sendMsg:args:`) but die with `kCBMsgArgResult
    = 902`: the daemon gates on the *session's* discovered-attribute table. The system's
    own HID access is internal to bluetoothd — there is no client-side raw-ATT opcode.

- DriverKit/kext replacement is dead on AMFI even with SIP disabled
  (HOLODATA-COM/SiriRemoteForge experiment, documented).

**Therefore:** remote-mic audio requires a non-Apple BLE host — a Linux box or a VM with
a passthrough USB BLE dongle running the proven driver — streaming PCM/Opus to OMNI over
a socket. The remote pairs to the relay, so buttons flow through it too; the input plane
becomes transport-agnostic (HID *or* socket). This is the architecture, not a fallback.

Occludes: any plan that assumes `IOHIDManager` seizure or `CoreBluetooth` can reach the
remote's audio channel on macOS.
