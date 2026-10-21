---
type: belief
id: frag-a-manual-pump-that-never-waits-starves-every-run-loop-source
provenance: session
ts: 2026-10-21
---

`nextEventMatchingMask` only spins the run loop while it *waits*. A
manual pump that passes a nil/distantPast `untilDate` — the shape both
`frames` and `host.run` use so rendering never blocks — never runs the
run loop at all, and every run-loop source in the process is dead:
timers, tracking areas, deferred `performSelector`s, and the system
menu bar's auto-hide reveal, which is app-side work the WindowServer
defers to the frontmost app's run loop.

The observable was narrow and the belief behind it is wide: Lars's
report was "the menu bar won't reveal over our window" — but the same
starvation silently killed every deferred mechanism AppKit expects to
be live. A dequeue+`sendEvent:`+`updateWindows` pump is not the
contract; the contract is pump events **and** service the run loop.
`CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true)` per iteration is
the fix — drains pending sources, returns immediately, zero cost when
idle.

Sequencing note: the menu-bar ownership fix (policy + mainMenu +
activate, `frag-an-unbundled-binary-owns-no-menu-bar-until-it-declares-one`)
was necessary and insufficient — the bar existed and still could not
reveal until the run loop was fed. Two halves of one contract: an app
must own a bar *and* be able to respond to it.

Design corollary for future host verbs: anything that registers a
run-loop source — NSTimer, `performSelector:afterDelay:`, tracking
areas on custom views, event taps — works only because both pumps
service the loop. A third pump that forgets the call reintroduces the
starvation invisibly.

**Second ruling, same territory (dialogs forced it):** a serviced pump
satisfies run-loop *sources* but not run-loop *state*. `NSAlert`'s
`runModal`, `beginModalSessionForWindow:`, prompt window compositing,
and activation all gate on `-[NSApp run]` having installed the app as
running — `finishLaunching` + `_running` KVC + every manual-drain
combination still returns instantly or reports `isVisible` while
nothing composites. So `host.run` stopped being a manual pump: it IS
`-[NSApp run]` with a repeating `NSTimer` draining the chrome ring, and
dialogs back on the native `runModal`. `frames` stays manual — its
contract is rendering, and serviced sources are all it needs — but any
verb wanting AppKit's state machinery must fire from inside `run()`'s
loop, which today means a `host.run` arm. `stop:` alone cannot break a
`run()` waiting on its event mach-port; the wake is a posted
`NSApplicationDefined` event.
