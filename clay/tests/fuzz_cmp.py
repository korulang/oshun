#!/usr/bin/env python3
"""Differential fuzz gate comparator — one dump file, three sections.

  ==REF==   Clay oracle CmdView stream
  ==CAND==  candidate stream (must match REF)
  ==MUT==   known-wrong candidate (must NOT match REF)

Per-kind field rules (matching what consumers actually read):
  kind, ud, z=    : exact, always (z is the command's zIndex — the
                    floating root's, so order+payload both checked)
  rect            : all kinds, tol 0.001 (same binary — near-exact expected)
  color c=        : kinds 1 (RECT), 3 (TEXT), 7 (OVERLAY_START —
                    overlayColor.color aliases rectangle.backgroundColor
                    at the union head; a real payload, not garbage), and
                    9 (CUSTOM — custom.backgroundColor shares the same
                    union head; real bytes, here always 0)
  img i=          : kind 4 only
  cd d=           : kind 9 only as payload; compared everywhere — a
                    candidate leaking nonzero d= on other kinds fails
  fs f=, tx=      : kind 3 only (fs tol 0.001, tx exact)
  fi=, ls=, lh=   : kind 3 only — fontId exact, letterSpacing and
                    lineHeight compared as floats (tol 0.001);
                    measured dims ride in r=
  corner cr=      : kinds 1 (RECT), 2 (BORDER — border.cornerRadius
                    shares the union head), 4 (IMAGE), and 9 (CUSTOM —
                    custom.cornerRadius sits at the same union offset) —
                    other kinds carry zeroed bytes (or, for text, are
                    guarded to 0 in `each`), compared exact at %.2f
  border bw=      : kind 2 only — border.width {left,right,top,bottom,
                    betweenChildren}; betweenChildren>0 also emits k=1
                    RECTs between children (compared via r=)

Usage: fuzz_cmp.py <dump>
Exit 0 only if CAND matches REF *and* MUT diverges from REF."""
import re, sys

pat = re.compile(
    r"^cmd k=(\d+) ud=(-?\d+) r=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)"
    r" c=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)"
    r" i=(-?\d+) d=(-?\d+) f=([-\d.]+) cr=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)"
    r" bw=([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)"
    r" fi=(-?\d+) ls=([-\d.]+) lh=([-\d.]+) z=(-?\d+) tx=(.*)$")

def parse(path):
    secs, errs, cur = {}, {}, None
    for line in open(path):
        line = line.rstrip("\n")
        if line.startswith("==") and line.endswith("=="):
            cur = line.strip("=")
            secs[cur] = []
            errs[cur] = []
            continue
        if cur is None:
            continue
        if line.startswith("err t="):
            errs[cur].append(line[6:])
            continue
        m = pat.match(line)
        if m:
            g = m.groups()
            secs[cur].append(dict(k=int(g[0]), ud=int(g[1]),
                                  r=[float(g[2]), float(g[3]), float(g[4]), float(g[5])],
                                  c=[float(g[6]), float(g[7]), float(g[8]), float(g[9])],
                                  i=int(g[10]), d=int(g[11]), f=float(g[12]),
                                  cr=[float(g[13]), float(g[14]), float(g[15]), float(g[16])],
                                  bw=[float(g[17]), float(g[18]), float(g[19]), float(g[20]), float(g[21])],
                                  fi=int(g[22]), ls=float(g[23]), lh=float(g[24]),
                                  zi=int(g[25]), tx=g[26]))
    return secs, errs

def cmp_errs(a, b, label):
    # Ordered error-type sequences per section — diagnostics fire during
    # declaration, so each section's err list precedes its cmd list.
    if a == b:
        return []
    diffs = [f"{label}: error stream {len(a)} vs {len(b)}"]
    for idx, (x, y) in enumerate(zip(a, b)):
        if x != y:
            diffs.append(f"{label}: err[{idx}] t={x} vs t={y}")
    return diffs

def cmp_rows(a, b, label):
    fails = []
    if len(a) != len(b):
        fails.append(f"{label}: command count {len(a)} vs {len(b)}")
    for idx, (x, y) in enumerate(zip(a, b)):
        if x["k"] != y["k"]:
            fails.append(f"{label}[{idx}]: kind {x['k']} vs {y['k']}")
            continue
        if x["ud"] != y["ud"]:
            fails.append(f"{label}[{idx}]: ud {x['ud']} vs {y['ud']}")
        if x["zi"] != y["zi"]:
            fails.append(f"{label}[{idx}]: z {x['zi']} vs {y['zi']}")
        for j, (u, v) in enumerate(zip(x["r"], y["r"])):
            if abs(u - v) > 0.001:
                fails.append(f"{label}[{idx}]: rect[{j}] {u} vs {v} (d={u-v:+.4f})")
        if x["k"] in (1, 2, 3, 7, 9):
            for j, (u, v) in enumerate(zip(x["c"], y["c"])):
                if abs(u - v) > 0.002:
                    fails.append(f"{label}[{idx}]: color[{j}] {u} vs {v} (d={u-v:+.4f})")
        if x["k"] in (1, 2, 4, 9):
            for j, (u, v) in enumerate(zip(x["cr"], y["cr"])):
                if abs(u - v) > 0.005:
                    fails.append(f"{label}[{idx}]: corner[{j}] {u} vs {v} (d={u-v:+.4f})")
        if x["k"] == 2:
            for j, (u, v) in enumerate(zip(x["bw"], y["bw"])):
                if abs(u - v) > 0.001:
                    fails.append(f"{label}[{idx}]: bw[{j}] {u} vs {v}")
        if x["k"] == 4 and x["i"] != y["i"]:
            fails.append(f"{label}[{idx}]: img {x['i']} vs {y['i']}")
        if x["d"] != y["d"]:
            fails.append(f"{label}[{idx}]: cd {x['d']} vs {y['d']}")
        if x["k"] == 3:
            if abs(x["f"] - y["f"]) > 0.001:
                fails.append(f"{label}[{idx}]: fs {x['f']} vs {y['f']}")
            if x["fi"] != y["fi"]:
                fails.append(f"{label}[{idx}]: fi {x['fi']} vs {y['fi']}")
            if abs(x["ls"] - y["ls"]) > 0.001:
                fails.append(f"{label}[{idx}]: ls {x['ls']} vs {y['ls']}")
            if abs(x["lh"] - y["lh"]) > 0.001:
                fails.append(f"{label}[{idx}]: lh {x['lh']} vs {y['lh']}")
            if x["tx"] != y["tx"]:
                fails.append(f"{label}[{idx}]: tx '{x['tx']}' vs '{y['tx']}'")
    return fails

secs, errs = parse(sys.argv[1])
missing = [s for s in ("REF", "CAND", "MUT") if s not in secs]
if missing:
    print(f"GATE FAIL — missing sections: {', '.join(missing)}")
    sys.exit(1)

ref, cand, mut = secs["REF"], secs["CAND"], secs["MUT"]
cand_fails = cmp_rows(ref, cand, "cand") + cmp_errs(errs["REF"], errs["CAND"], "cand")
mut_fails = cmp_rows(ref, mut, "mut") + cmp_errs(errs["REF"], errs["MUT"], "mut")

problems = []
if not ref:
    problems.append("REF section is empty")
if not mut_fails:
    problems.append("MUT is identical to REF — the gate cannot reject a known-wrong candidate")

# Warm-frame sections (REF2/CAND2/REF3): same spec re-laid-out on the same
# context — exercises persistent state. Clay's persistent hashmap carries
# prior-frame boxes into attach/clip resolution (cold-start artifact), so
# Clay's frame-1 REF is informational; REF2 is the converged oracle.
#
# History: an earlier vendored clay.h left STALE tree roots when a
# reconfigure removed floating (double-visited elements, zi-order
# last-writer map conflation) — that produced the ud=569 divergence once
# adjudicated as nl-correct. Root cause was a shared defect in both
# solvers; fixed in clay.h (dedupe at registration, purge at close) and
# nl (addRoot/dropRootsFor). Both now emit strictly equal streams, so the
# check is strict equality against REF2 — no adjudicated set.

def cmp_converged(conv, stream, err_key, label):
    """Strict positional+payload compare of a candidate stream against
    Clay's converged REF2 (plus error stream); returns the failure list."""
    return cmp_rows(conv, stream, label) + cmp_errs(errs["REF2"], errs[err_key], label)

warm_notes = []
ref2 = secs.get("REF2")
if ref2 is not None:
    ref3 = secs.get("REF3")
    if ref3 is not None:
        conv_drift = cmp_rows(ref2, ref3, "ref3") + cmp_errs(errs["REF2"], errs["REF3"], "ref3")
        if conv_drift:
            warm_notes.append(f"REF2 vs REF3: {len(conv_drift)} divergences — Clay has NOT converged; converged-stream checks are against a moving target")
        else:
            warm_notes.append("REF2 == REF3 (Clay converged)")
    r_drift = cmp_rows(ref, ref2, "ref2") + cmp_errs(errs["REF"], errs["REF2"], "ref2")
    if r_drift:
        warm_notes.append(f"REF drift frame1->frame2: {len(ref)} -> {len(ref2)} cmds, {len(r_drift)} divergences (Clay cold-start artifact)")
    else:
        warm_notes.append("REF is frame-stable")
    conv_fails = cmp_converged(ref2, cand, "CAND", "cand-conv")
    if conv_fails:
        problems.append(f"CAND diverges from Clay's converged stream REF2 ({len(conv_fails)} divergences)")
        problems += ["  " + f for f in conv_fails[:8]]
    else:
        warm_notes.append("correctness: CAND == REF2 strictly")
    if cand_fails:
        warm_notes.append(f"CAND vs REF (frame 1): {len(cand_fails)} divergences — expected, Clay's cold-start artifact")
else:
    if cand_fails:
        problems.append(f"CAND diverges from REF ({len(cand_fails)} divergences)")
        problems += ["  " + f for f in cand_fails[:8]]
if "CAND2" in secs:
    c2_drift = cmp_rows(cand, secs["CAND2"], "cand2") + cmp_errs(errs["CAND"], errs["CAND2"], "cand2")
    if c2_drift:
        problems.append(f"CAND drifts frame1->frame2: {len(cand)} -> {len(secs['CAND2'])} cmds, {len(c2_drift)} divergences — nl must be frame-stable")
        problems += ["  " + f for f in c2_drift[:8]]
    else:
        warm_notes.append("CAND is frame-stable")
    if ref2 is not None:
        w_fails = cmp_converged(ref2, secs["CAND2"], "CAND2", "warm")
        if w_fails:
            problems.append(f"CAND2 diverges from REF2 ({len(w_fails)} divergences)")
            problems += ["  " + f for f in w_fails[:8]]
        else:
            warm_notes.append("warm: CAND2 == REF2 strictly")

if problems:
    print(f"GATE FAIL — ref {len(ref)} cmds")
    for p in problems:
        print("  " + p)
    for n in warm_notes:
        print("  " + n)
    sys.exit(1)
print(f"GATE PASS — CAND strictly matches Clay's converged stream ({len(ref)} ref cmds); MUT rejected with {len(mut_fails)} divergences")
for n in warm_notes:
    print("  " + n)
sys.exit(0)
