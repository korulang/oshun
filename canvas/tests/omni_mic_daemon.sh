#!/usr/bin/env bash
# omni_mic_daemon — supervised mic bridge for OMNI, no sudo needed.
# Reads the root packetlogger's nhdr stream from /tmp/omni_hci_capture.txt
# (the capture side runs separately — see omni_mic_capture.plist LaunchDaemon)
# and feeds siri_mic_bridge for the live remote. launchd KeepAlive respawns
# this script; the inner loop respawns the bridge on crash. If another
# siri_mic_bridge is already running (e.g. omni_mic_up.sh), we defer to it
# rather than race the session-file namespace.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
CAP=/tmp/omni_hci_capture.txt
DEVICE="${1:-C08PGGDL2330}"
ATT="${2:-0x36}"
OUT=/tmp/omni_remote_mic.wav

while true; do
  if pgrep -f "$HERE/siri_mic_bridge" >/dev/null 2>&1; then
    sleep 10
    continue
  fi
  if [ -f "$CAP" ]; then
    tail -f "$CAP" | "$HERE/siri_mic_bridge" "$DEVICE" --wav "$OUT" "$ATT"
  fi
  sleep 5
done
