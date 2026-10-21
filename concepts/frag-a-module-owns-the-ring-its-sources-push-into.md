---
type: belief
id: frag-a-module-owns-the-ring-its-sources-push-into
provenance: session
ts: 2026-10-21
---

The event ring belongs to the module whose native sources push into
it — not to the app, and not to the pump. A pump drains every ring its
program's arms listen to.

The tray spike ran one shared mailbox: view IMPs and the
KoruTrayTarget IMPs pushed `key_down`/`mouse_*`/`tray_action` into a
single ring that `frames` drained. Splitting host out of metal
exposed the constraint behind it — a shared ring means shared event
vocabulary, and under usage-driven emission an offscreen-only metal
program cannot afford a link to the module that owns that vocabulary.

The sharpened shape: metal owns the window ring (`key_down`,
`mouse_*`, `scroll` — the events its `KoruView` IMPs produce), host
owns the tray ring (`tray_action` — what `KoruTrayTarget` produces),
and each pump drains the union of rings its arms cover: `frames`
drains metal's ring then host's tray ring on the same iteration;
`host.run` drains the tray ring alone. Dispatch order stays
drain-then-render, and `should_quit` lives with the pump contract,
not with any one ring.

Corollary for the verbs that come next: a new event *vocabulary*
belongs beside the module that produces it — a future dialog or
notification ring lands in host next to `tray_ev_buf`, not in a
shared "events" type both halves would have to import.
