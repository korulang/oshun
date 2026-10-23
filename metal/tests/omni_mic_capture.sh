#!/usr/bin/env bash
# omni_mic_capture — the root side of the mic plane. packetlogger's live
# HCI trace needs root; this script is meant to run as a LaunchDaemon,
# appending the nhdr stream to /tmp/omni_hci_capture.txt where the
# user-level omni_mic_daemon reads it without sudo.
PKL="$HOME/Library/Application Support/GoatRemote/Additional Tools/Hardware/PacketLogger.app/Contents/Resources/packetlogger"
[ -x "$PKL" ] || { echo "packetlogger not found at: $PKL" >&2; exit 1; }
exec "$PKL" convert -s -f nhdr >> /tmp/omni_hci_capture.txt
