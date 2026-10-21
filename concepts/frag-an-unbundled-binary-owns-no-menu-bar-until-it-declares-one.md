---
type: belief
id: frag-an-unbundled-binary-owns-no-menu-bar-until-it-declares-one
provenance: session
ts: 2026-10-21
---

A Koru binary is unbundled: no Info.plist, launched from a terminal. On
macOS that means the process owns no menu bar by default — and setting
`setActivationPolicy(Regular)` alone is not enough to get one. The
contract has three parts, all of which a windowed app must perform:
policy Regular, a non-nil `mainMenu`, and activate. Under menu-bar
auto-hide the system reveals the bar only for a frontmost app that has
one; an app with policy-but-no-menu can look focused while the reveal
zone stays dead.

Surfaced live: the tray spike's window took focus, but the auto-hidden
menu bar never revealed over it — AX showed `menu bar 1` containing
only the `◉ koru` status item, no Apple menu at all. After
`activateRegular()` (Regular + minimal NSMenu mainMenu + activate) the
same query returns `Apple` and the status item correctly migrates to
`menu bar 2`, the extras bar where status items live for regular apps.

Two rules that fall out of it:

- `window.open` upgrades unconditionally; `tray.new` must never
  downgrade — a windowed app that creates a tray after the window would
  otherwise lose Regular and its bar. The Accessory declaration is for
  tray-only apps (agents: status item, no dock icon, no bar).
- The minimal `mainMenu` (an empty NSMenu) is scaffolding for the
  `menu` verb, not a substitute — it yields an Apple menu and a bar
  to reveal, nothing more.

Identity is a second declaration, orthogonal to presence: an unbundled
binary embeds `Info.plist` as `__TEXT,__info_plist` (a compile-time C
section attribute, no linker flags), and AppKit's app-menu title reads
`CFBundleName` from it — the menu heading stops being `a.out`. But the
oracles are split: `NSBundle.mainBundle` and AppKit honor the embedded
plist while `NSProcessInfo.processName` and LaunchServices
`LSDisplayName` still read the executable name. So the declaration buys
the menu title and bundle queries — not every system name; that last
row needs real `.app` packaging.
