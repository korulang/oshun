#!/usr/bin/env bash
# omni_mic_up — bring the Siri Remote mic channel up for OMNI.
# Requires: Bluetooth logging profile installed (deep HCI trace), root for
# packetlogger live capture. Writes live WAV to /tmp/omni_remote_mic.wav —
# omni mints it onto the bridge on mic-button release.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PKL="$HOME/Library/Application Support/GoatRemote/Additional Tools/Hardware/PacketLogger.app/Contents/Resources/packetlogger"
BRIDGE="$HERE/siri_mic_bridge"
DEVICE="${1:-C08PGGDL2330}"
ATT_HANDLE="${2:-0x36}"
OUT="/tmp/omni_remote_mic.wav"

[ -x "$PKL" ] || { echo "packetlogger not found at: $PKL" >&2; exit 1; }
[ -x "$BRIDGE" ] || { echo "siri_mic_bridge not built: $BRIDGE" >&2; exit 1; }

echo "omni mic up — capturing HCI for $DEVICE (att $ATT_HANDLE) -> $OUT"
echo "(ctrl-C to stop; leave running while omni is up)"
exec sudo "$PKL" convert -s -f nhdr | "$BRIDGE" "$DEVICE" --wav "$OUT" "$ATT_HANDLE" > /dev/null
