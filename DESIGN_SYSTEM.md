# DESIGN_SYSTEM.md — Visual, Motion & 3D Language

Source of visual truth: the Laarish guidebook PDF. The app must look like the guidebook came alive.

## 1. Palette (light & medium, from guidebook pages)

| Token | Hex | Use |
|---|---|---|
| `paper` | #FDF6E7 | Base background everywhere (guidebook cream) |
| `paperDeep` | #F5E9D0 | Card wells, insets |
| `sky` | #87CEEB → #BFE3F5 grad | Roadmap sky band, intro scene |
| `sunflower` | #FFC93C | Primary action, highlights, star fills |
| `sunflowerDeep` | #F5A623 | Pressed states, badge gold |
| `leaf` | #58A83C | Success, progress fill, Methi biome |
| `leafDeep` | #2F6B2F | Headers on cards (guidebook green banners) |
| `tomato` | #D93025 | Tommy biome, section banners (guidebook red) |
| `chili` | #C62828 + flame #FF8F3C | Chilly biome accents |
| `soil` | #7A5230 | Path, ground, wooden signs |
| `ink` | #3A2E24 | Text (warm dark brown — never pure black) |
| `bubble` | #FFFFFF | Speech bubbles, sticker cards |

Rules: backgrounds always light (paper/sky). Saturated colors only as accents/characters.
Each plant tints its biome: Tommy warm-red garden, Okki fresh green, Chilly sunset-spice, Methi bright lime.

## 2. Typography

- **Display:** Baloo 2 (rounded, chunky — matches guidebook headers) — titles, level names, numbers.
- **Body:** Nunito — instructions, speech bubbles.
- Sizes: Display 34/28/22, body 18 (kids read big). All text in speech bubbles or sticker cards, never floating on raw background.

## 3. Shape language

- Sticker cards: white/cream rounded-24 cards with 2px soft outline + tiny drop shadow (guidebook look).
- Section banners: pill-shaped colored ribbon with white bold text (guidebook "PHASE 1 - NURSERY" style).
- Numbered step circles: filled color circle + white number (guidebook ①②③).
- Buttons: 3D "gummy" style — top-light gradient, bottom rim darker, presses DOWN 4dp with squash (scale 1.0→0.94 y) + pop sound.
- Speech bubbles with tail, always paired to a character.
- Badges: gold-seal rosette with ribbon tails (guidebook badge art).

## 4. Motion language ("garden juice")

Every animation follows these physics — this is what makes it feel Candy-Crush-smooth:

| Primitive | Spec |
|---|---|
| **Spring pop** | SpringDescription(mass 1, stiffness 500, damping 20) — UI enters by scale 0→1.05→1 |
| **Squash & stretch** | Any tap: 0.94 squash 60ms → overshoot 1.06 → settle. Characters bounce with y-squash |
| **Stagger** | Lists/nodes cascade 40–70ms apart, never simultaneous |
| **Ease vocabulary** | enter: easeOutBack · exit: easeInCubic · camera: easeInOutCubicEmphasized |
| **Float idle** | Ambient elements sine-float ±4dp @ 3–5s, phase-offset so nothing syncs |
| **Fly-to-HUD** | Rewards arc (quadratic bezier) to counters; counter squash-pulses on receive |
| **Transitions** | No page slides. Themed wipes: leaf-wipe, gate-open, sunflower-iris, soil-rise. 450–600ms |
| **Celebration** | RewardOverlay: dim 40% → item spring-in → confetti burst + Lottie shine → count-up 800ms |

Rule: nothing appears or disappears without motion; nothing moves linearly.

## 5. The "3D without a game engine" recipe

Layered approach — combine, don't pick one:

1. **Pre-rendered 3D art (the star).** Characters/scenes generated in the exact guidebook style
   (Pixar-ish 3D renders) exported as transparent webp @1x/2x/3x. Hero moments use short
   image-sequences (24–36 frames, webp, played via AnimatedSprite widget) — e.g. Tommy 360° turn,
   badge mint spin. This is how the app matches the PDF *exactly*.
2. **Rive state machines** on top for life: blink/idle/wave/jump/celebrate rigs built from the
   same character art (Rive mesh-deform on the renders). Inputs: `isIdle, tap, celebrate, lookX/lookY`
   (eyes follow finger/text-field on login).
3. **Parallax depth**: 4–5 layers (sky 0.2, far hills 0.4, mid garden 0.7, path 1.0, foreground
   leaves 1.15) driven by scroll; plus subtle device-tilt (accelerometer ±6dp) on hero scenes.
4. **Perspective transforms**: `Matrix4..setEntry(3,2,0.0015)` rotations for card flips
   (profession carousel, quiz cards, certificate) — true 3D feel from Flutter alone.
5. **Fragment shaders** (`assets/shaders/`): animated sky gradient + drifting god-rays,
   soft glow behind current level node, water shimmer for watering minigame. GPU-cheap ambience.
6. **Particles** via one pooled CustomPainter system: floating pollen/leaves on roadmap,
   water droplets, confetti assist, firefly sparkles on night-themed Chilly patience screens.

Perf convention (project rule): slow ambient effects (background drift, blur layers) tick at
30fps via `ThrottledTicker`; interactive/spring motion stays 60fps. Never cut visuals to fix lag.

## 6. Roadmap scroll spec (flagship, Candy-Crush ladder feel)

- Vertical `CustomScrollView`, `BouncingScrollPhysics` — iOS-style rubber band on both platforms.
- Winding S-curve path (cubic splines), dashed "footsteps" texture; completed path fills green with a growing-vine sweep animation.
- Nodes pop in with spring+stagger as they enter viewport (once per session).
- Current node: glow shader pulse + mascot idling on it (Rive) + gentle camera magnetism.
- Scroll parallax on all biome layers; biome color/foliage cross-fades between plant zones.
- Flying ambient critters (butterfly/bee sprite on bezier paths) — 1–2 at a time, pooled.
- Star meter per node (0–3 stars, gold fill), chest sub-nodes between levels for bonus Seed Coins.
- Entering a level: node scales up into a full-screen iris transition (node becomes the level scene).

## 7. Sound design

- BGM: light acoustic garden loop (~70 BPM), ducks −12dB under speech/video.
- SFX palette: pop (tap), boing (spring), sparkle (reward), water, snip, dig, harvest-pluck, badge-fanfare, gate-creak.
- Every interactive touch = SFX + light haptic. Silence is a bug.

## 8. Asset production pipeline

1. Generate/commission stills in guidebook style (same character sheets — reuse PDF renders where extractable).
2. Cut to transparent webp; sprite-sheets for sequences.
3. Rig faces/limbs in Rive for interactive states.
4. Icons: guidebook emoji-style 3D icons (flame, leaf, star, root) as webp stickers.
5. Naming: `assets/images/<biome>/<subject>_<state>@2x.webp`; Rive: `assets/rive/<subject>.riv`.
