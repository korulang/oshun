---
type: belief
id: frag-a-port-reproduces-the-reference-not-the-house-style
provenance: omni gallery control port, 2026-11-15
ts: 2026-11-15
---

A port is judged against the reference, not against the house style. The
first Omni control family was designed *into* the Lantern language — ink
pane, champagne light, one hue, the card anatomy — and it looked cohesive.
Cropped to the reference's own frame it scored **0.296 / 0.266 SSIM** against
the BP and flight captures. Taking the measured reference spec directly
(palette, background, card geometry, text positions, the 21-bar/42-dot
table, the runway) scores **0.828 / 0.761** from the same crop.

The cohesive look was a re-design wearing the word "port." The user's read
that it was "very far away" was correct, and no technical constraint
explained the distance: the canvas lacks gradients and text blur, but that
gap is the second-order one (the HTML arms, with CSS, reach 0.910 / 0.864).
The first-order error was target substitution — choosing a language the
reference never spoke.

The usable rule: take the reference's geometry and palette as the target,
and use the house language only where it does not move the reference. A
design-language exploration is legitimate work; it is a different brief.

**What would correct this belief:** a stylized port that scores closer to
the reference than a measured one, or a case where the reference's own
geometry is unusable and a house grammar lands nearer the intent. Nothing
here says Lantern is wrong as a language — only that it was the wrong
target for a port.
