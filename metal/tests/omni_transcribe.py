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
CMD_QUEUE = "/tmp/omni_voice.cmd"

os.makedirs(RESAMPLE_DIR, exist_ok=True)

# --- the command gate ----------------------------------------------------
# The bridge verbs, declared as Needle tools. A transcript that picks one
# becomes a wire-source line on /tmp/omni_voice.cmd; chatter produces no
# tool call and stays a caption on its own card.


def file_open(path: str):
    """Open a file as a resource on the bridge. Path must be absolute."""


def file_close(handle: str):
    """Discharge a held resource by its 6-hex custody handle."""


def say(text: str):
    """Print a line on the bridge."""


_cmd_agent = None


def cmd_agent():
    global _cmd_agent
    if _cmd_agent is None:
        sessions = sorted(
            os.path.join(GLOB_DIR, n)
            for n in os.listdir(GLOB_DIR)
            if n.startswith("omni_remote_mic_") and n.endswith(".wav")
        )
        known = "\n".join(sessions[-6:]) or "(none yet)"
        _cmd_agent = needle.Needle(
            tools=[file_open, file_close, say],
            system=(
                "You map a spoken utterance to a bridge command. "
                "Paths must be real absolute paths — known voice sessions:\n"
                f"{known}\n"
                "'open'/'show me' a file → file_open. If nothing fits, "
                "call nothing."
            ),
            stateless=True,
        )
    return _cmd_agent


def command_for(text: str) -> str:
    """Transcript → wire source line, or "" when it isn't a command."""
    try:
        r = cmd_agent().complete(text)
    except Exception as e:
        sys.stderr.write(f"cmd gate: {e}\n")
        return ""
    if r.get("type") != "call":
        return ""
    lines = []
    for call in r.get("function_calls") or []:
        name = call.get("name")
        args = call.get("arguments") or {}
        if name == "file_open" and isinstance(args.get("path"), str):
            p = args["path"].replace("\\", "\\\\").replace('"', '\\"')
            lines.append(f'file-open(path: "{p}")')
        elif name == "file_close" and isinstance(args.get("handle"), str):
            lines.append(f'file-close(handle: "{args["handle"]}")')
        elif name == "say" and isinstance(args.get("text"), str):
            t = args["text"].replace("\\", "\\\\").replace('"', '\\"')
            lines.append(f'say(text: "{t}")')
    return "\n".join(lines)


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
            wire = command_for(text)
            if wire:
                with open(CMD_QUEUE, "a") as q:
                    q.write(wire + "\n")
                sys.stderr.write(f"  → wire: {wire!r}\n")
        time.sleep(0.25)


if __name__ == "__main__":
    main()
