#!/usr/bin/env python3
# omni_transcribe — the session sidecar writer. Watches /tmp for
# omni_remote_mic_*.wav sessions minted by siri_mic_bridge; when a file's
# size is stable for STABLE_S the take is over, so resample 48k→16k and
# run Whistle (Cactus needle, on-device) → <session>.txt. OMNI cards pick
# the sibling transcript up through the seam — the card deepens a beat
# after it lands, nothing is invented while it is pending.
import json, os, re, subprocess, sys, time

os.environ.setdefault("NEEDLE_TELEMETRY", "0")

import needle

GLOB_DIR = "/tmp"
STABLE_S = 1.2
RESAMPLE_DIR = "/tmp/omni_whistle"
CMD_QUEUE = "/tmp/omni_voice.cmd"

os.makedirs(RESAMPLE_DIR, exist_ok=True)

# --- the command gate ----------------------------------------------------
# Deterministic resolution first. A real reasoner — an ACP session, `devin
# acp` over stdio — takes the misses: transcripts flow to it, its
# commander-grammar replies land on the same /tmp/omni_voice.cmd queue.
# The agent gets no fs/terminal capabilities: it speaks, the bridge
# decides. OMNI_ACP=0 disables.

import threading
import queue as _queue


class AcpAgent:
    """Minimal ACP client — one persistent `devin acp` session over stdio
    JSON-RPC. No SDK: initialize → session/new → session/prompt, reading
    agent_message_chunk notifications until the prompt response lands."""

    PREAMBLE = (
        "You are the reasoning participant on OMNI's custody bridge. A "
        "human speaks to you through a voice remote; each prompt is a "
        "transcript. When the utterance is a command, reply with wire "
        "lines only — one per line:\n"
        '  file-open(path: "<absolute path>")\n'
        '  file-close(handle: "<6-hex>")\n'
        '  say(text: "<text>")\n'
        "Only real absolute paths from the Files list in the prompt — "
        "never invent paths. When it isn't a command, reply with a short "
        "plain sentence."
    )

    def __init__(self, cmd=("devin", "acp"), cwd="/tmp"):
        self.proc = subprocess.Popen(
            list(cmd), stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, text=True, bufsize=1, cwd=cwd,
        )
        self._q = _queue.Queue()
        self._id = 0
        self._first = True
        threading.Thread(target=self._reader, daemon=True).start()
        self._call("initialize", {
            "protocolVersion": 1,
            "clientCapabilities": {
                "fs": {"readTextFile": False, "writeTextFile": False},
                "terminal": False,
            },
        })
        r = self._call("session/new", {"cwd": cwd, "mcpServers": []})
        self.session_id = (r or {}).get("sessionId")

    def _reader(self):
        for line in self.proc.stdout:
            line = line.strip()
            if line:
                try:
                    self._q.put(json.loads(line))
                except Exception:
                    pass

    def _send(self, method, params):
        self._id += 1
        self.proc.stdin.write(json.dumps(
            {"jsonrpc": "2.0", "id": self._id, "method": method,
             "params": params}) + "\n")
        self.proc.stdin.flush()
        return self._id

    def _wait(self, rid, timeout=120):
        end = time.time() + timeout
        notes = []
        while time.time() < end:
            try:
                m = self._q.get(timeout=1)
            except _queue.Empty:
                continue
            if m.get("id") == rid:
                return (m.get("result") or {}), notes
            notes.append(m)
        return {}, notes

    def _call(self, method, params, timeout=60):
        r, _ = self._wait(self._send(method, params), timeout)
        return r

    def prompt(self, text, files, timeout=180):
        body = text
        if self._first:
            body = self.PREAMBLE + "\n\n" + body
            self._first = False
        body += "\n\nFiles:\n" + (files or "(none)")
        _, notes = self._wait(self._send("session/prompt", {
            "sessionId": self.session_id,
            "prompt": [{"type": "text", "text": body}],
        }), timeout)
        out = []
        for m in notes:
            u = (m.get("params") or {}).get("update") or {}
            if u.get("sessionUpdate") == "agent_message_chunk":
                c = u.get("content") or {}
                if c.get("type") == "text":
                    out.append(c.get("text", ""))
        return "".join(out)


_acp = None


def acp_agent():
    global _acp
    if _acp is None and os.environ.get("OMNI_ACP", "1") != "0":
        try:
            _acp = AcpAgent()
            sys.stderr.write(f"acp: session {(_acp.session_id or '?')!r} up\n")
        except Exception as e:
            sys.stderr.write(f"acp: spawn failed: {e}\n")
            _acp = False
    return _acp or None


_WIRE_RE = re.compile(
    r'^(file-open|file-close|say)\((.*)\)\s*$'
)


def acp_wire(reply: str):
    """Extract wire-shaped lines from an agent reply; file-open paths must
    exist — same oracle as the resolver."""
    lines = []
    for ln in reply.splitlines():
        ln = ln.strip()
        m = _WIRE_RE.match(ln)
        if not m:
            continue
        if m.group(1) == "file-open":
            pm = re.search(r'path:\s*"([^"]*)"', m.group(2))
            if not pm or not os.path.isfile(pm.group(1)):
                continue
        lines.append(ln)
    return lines

_WORD_NUM = {
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
    "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
    "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
    "nineteen": 19, "twenty": 20,
}


def _session_wavs():
    wavs = []
    for n in os.listdir(GLOB_DIR):
        if n.startswith("omni_remote_mic_") and n.endswith(".wav"):
            p = os.path.join(GLOB_DIR, n)
            if os.path.getsize(p) > 44:
                wavs.append(p)
    wavs.sort(key=lambda p: int(p.rsplit("_", 1)[1][:-4])
              if p.rsplit("_", 1)[1][:-4].isdigit() else 0)
    return wavs


def _open_lines(paths):
    return [
        'file-open(path: "%s")' % p.replace("\\", "\\\\").replace('"', '\\"')
        for p in paths
    ]


def _spoken_path(t):
    """'slash temp slash ocean underscore logo dot png' → /tmp/ocean_logo.png"""
    s = re.sub(r"[?!]+$", "", t)
    for word, ch in ((" slash ", "/"), (" underscore ", "_"),
                     (" dot ", "."), (" dash ", "-")):
        s = s.replace(word, ch)
    s = s.replace(" temp ", " tmp ")
    m = re.search(r"(/[^ ]+)", s)
    if not m:
        m = re.search(r"downloads\b\s*(.*)", s)
        if not m:
            return None
        cand = os.path.expanduser("~/Downloads/" + m.group(1).replace(" ", ""))
        return cand if os.path.isfile(cand) else None
    cand = m.group(1)
    while cand.startswith("//"):
        cand = cand[1:]
    return cand if os.path.isfile(cand) else None


def known_sessions() -> str:
    return "\n".join(_session_wavs()[-8:]) or "(none yet)"


def resolve_intent(text: str):
    """Deterministic target resolution — fires before asking the model."""
    t = text.lower()
    wavs = _session_wavs()
    wants_open = any(w in t for w in ("open", "show", "file", "session", "play"))
    if not wants_open:
        return []
    if any(w in t for w in ("last", "latest", "newest", "recent")) and wavs:
        return _open_lines([wavs[-1]])
    for w in t.replace("-", " ").split():
        n = int(w) if w.isdigit() else _WORD_NUM.get(w)
        if n is not None:
            p = os.path.join(GLOB_DIR, f"omni_remote_mic_{n}.wav")
            if os.path.exists(p):
                return _open_lines([p])
    p = _spoken_path(t)
    if p:
        return _open_lines([p])
    return []


def command_for(text: str):
    """Transcript → (wire source, verdict dict for the sidecar)."""
    resolved = resolve_intent(text)
    if resolved:
        return "\n".join(resolved), {"type": "resolved", "wire": resolved}
    agent = acp_agent()
    if agent and agent.session_id:
        try:
            reply = agent.prompt(f"Utterance: {text}", known_sessions())
        except Exception as e:
            sys.stderr.write(f"acp prompt: {e}\n")
            return "", {"type": "acp-error", "error": str(e)}
        lines = acp_wire(reply)
        verdict = {"type": "acp", "reply": reply[:2000]}
        if lines:
            verdict["wire"] = lines
            return "\n".join(lines), verdict
        return "", verdict
    return "", {"type": "no-match"}


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
            wire, verdict = command_for(text) if text else ("", {"type": "empty"})
            sys.stderr.write(
                f"  → gate: {verdict.get('type')!r} wire={verdict.get('wire')}\n"
            )
            try:
                with open(txt[:-4] + ".gate.json", "w") as nf:
                    json.dump({"text": text, "verdict": verdict, "wire": wire}, nf)
            except Exception:
                pass
            if wire:
                with open(CMD_QUEUE, "a") as q:
                    q.write(wire + "\n")
                sys.stderr.write(f"  → wire: {wire!r}\n")
        time.sleep(0.25)


if __name__ == "__main__":
    main()
