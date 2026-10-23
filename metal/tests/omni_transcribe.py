#!/usr/bin/env python3
# omni_transcribe — the session sidecar writer. Watches /tmp for
# omni_remote_mic_*.wav sessions minted by siri_mic_bridge; when a file's
# size is stable for STABLE_S the take is over, so resample 48k→16k and
# run Whistle (Cactus needle, on-device) → <session>.txt. OMNI cards pick
# the sibling transcript up through the seam — the card deepens a beat
# after it lands, nothing is invented while it is pending.
import os, subprocess, sys, time

os.environ.setdefault("NEEDLE_TELEMETRY", "0")

import needle

GLOB_DIR = "/tmp"
STABLE_S = 1.2
RESAMPLE_DIR = "/tmp/omni_whistle"

os.makedirs(RESAMPLE_DIR, exist_ok=True)


def sessions():
    out = []
    for name in os.listdir(GLOB_DIR):
        if name.startswith("omni_remote_mic_") and name.endswith(".wav"):
            p = os.path.join(GLOB_DIR, name)
            out.append((p, p[:-4] + ".txt"))
    return out


def main():
    while True:
        now = time.time()
        for wav, txt in sessions():
            if os.path.exists(txt):
                continue
            try:
                if now - os.path.getmtime(wav) < STABLE_S:
                    continue
            except OSError:
                continue
            resampled = os.path.join(RESAMPLE_DIR, os.path.basename(wav))
            try:
                subprocess.run(
                    ["afconvert", "-f", "WAVE", "-d", "LEI16@16000", "-c", "1", wav, resampled],
                    check=True, capture_output=True,
                )
                r = needle.transcribe(resampled)
                text = (r.get("text") or "").strip()
            except Exception as e:  # a bad take still gets a marker — no silent holes
                text = ""
                sys.stderr.write(f"transcribe {os.path.basename(wav)}: {e}\n")
            with open(txt, "w") as f:
                f.write(text + "\n")
            sys.stderr.write(f"{os.path.basename(txt)}: {text!r}\n")
        time.sleep(0.25)


if __name__ == "__main__":
    main()
