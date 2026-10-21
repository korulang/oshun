---
type: belief
id: frag-autoreleased-host-objects-die-at-the-pool-boundary
provenance: session
ts: 2026-10-21
---

An Objective-C object handed to us by a convenience/factory method is
autoreleased, and the owner we assume it has often does not exist. The
handle dies at the next pool pop — for a `~proc|zig` body that is the
proc's own autoreleasePoolPush/Pop — and the token we stored on a
Koru-side struct then dangles into whatever object reuses the memory.

The tray spike hit this concretely: `statusItemWithLength:` returns an
`NSSceneStatusItem` the status bar does NOT retain. `tray.new` stored it
on the Tray token and returned; the proc's pool popped; the item died.
Every subsequent `setMenu:`/`addItem:` went to a dangling pointer — the
slot was silently reused by an `_NSMenuImpl` in one run and an
`NSExtraMIData` in another, and the crash surfaced only at
`tray.remove`, an app-lifetime later, as an unrecognized-selector
exception naming a class that had nothing to do with the call site.

The signature to recognize: a stored handle that works in the same proc
that created it, then fails later with an exception whose receiver class
is unrelated to the object you stored. That is memory reuse, not a bad
selector. Electrobun's `retainObjCObject(statusItem)` in createTray was
the same discovery, visible in the reference and still easy to miss.

The rule: when a proc captures a convenience-returned ObjC object into a
token meant to outlive the proc, retain it at capture and release it in
the token's consumer (`tray.remove` sends the matching release after
`removeStatusItem:`). alloc/init returns already-owned (+1) — target
objects, menus, menu items need no retain. The diagnostic cost of
skipping this is high: the handle looks live while pointing at an
unrelated object of an unrelated class.
