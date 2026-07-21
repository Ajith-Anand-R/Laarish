# LAARISH — Master Plan

> "I'm An Agriculturist" — a gamified companion app for the Laarish physical growing kit.
> Children (ages ~5–10) grow 4 real plants (Tommy the Tomato, Okki, Chilly, Methi) with the kit,
> while the app turns every real-world step into a game level with rewards, characters, and celebration.

This document is the single source of truth for **vision, flow, and screen inventory**.
Companion documents:

| File | Purpose |
|---|---|
| [CANON.md](CANON.md) | **Extracted guidebook canon — names, verbatim dialogues, numbers, steps, badges. Overrides everything.** |
| [AGENT.md](AGENT.md) | System prompt + directions for any AI agent building this app |
| [ARCHITECTURE.md](ARCHITECTURE.md) | High-level + low-level system design, folder structure, data models |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | Colors, typography, motion language, 3D/animation techniques |
| [GAMIFICATION.md](GAMIFICATION.md) | Reward economy, badges, streaks, retention loops |
| [PARALLEL_AGENTS.md](PARALLEL_AGENTS.md) | How multiple AI subagents work in parallel without conflicts |
| [TODOLIST.md](TODOLIST.md) | Phased implementation checklist |

---

## 1. Product Vision

- **Not a farming simulator.** The app mirrors the *real* Laarish kit. The child does a real step
  (soak Corky, drop 2 seeds, mist with Misty), then confirms/plays it in the app and gets rewarded.
- **Feel:** premium mobile game — Candy-Crush-grade juice and smoothness — but calm, light,
  garden-sunshine palette matched to the guidebook art.
- **Every screen is gamified.** No plain forms, no plain lists. Login, roadmap, even settings live
  inside the garden world.
- **Two worlds, one identity:** the guidebook's characters ARE the app's characters. Visual parity
  with the PDF (Pixar-style 3D renders, cream paper background, rounded sticker cards, badge seals).

## 2. Canon (see CANON.md — full extraction; do not invent alternatives)

**Kids:** Rishi (boy, yellow t-shirt, curly hair) and Ayra (girl, yellow dress, flower in hair).
The child picks one as their buddy/guide. All their guidebook lines used verbatim (CANON.md §2).

**Plant mascots (order fixed, titles canon):**
1. 🍅 **TOMMY — THE CLIMBER** (tomato superhero: green cape, "T" belt). Superpower: bury 2/3 of stem → More Roots, More Water, More Food, More Tomatoes. "It looks extreme. It is exactly right." Sprouts 5–7 days, seed depth 6 mm.
2. 🌿 **OKKI — THE SPEEDSTER** (**okra**, yellow bandana, green sneakers, running pose). "Soak me tonight! I'll wake up faster!" — seeds soak 8–12 hrs night before, seed depth 12 mm, sprouts 5–7 days. "Okki sulks in cold."
3. 🌶️ **CHILLY — THE SLOW BURN** (sunglasses, flame aura, arms crossed). "I take my time, but I reward you with lots of chillies!" Sprouts 10–14 days — patience is the lesson. Surface-level transplant, no deep burial.
4. 🌱 **METHI — THE FENUGREEK / THE QUICK GREENS** (leafy hair, yellow headband, scissors). "I give you TWO harvests!" MANY plants, NO transplanting, FASTEST harvest, Round 1 (cup) + Round 2 (grow bag). Golden Rule: TWO ROUNDS · TWO HARVESTS · SAME SEED · BETTER GARDENER.

**Kit tools (named characters too):** Corky (coir cup), Diggy (ruler/dibber, mixes soil), Misty (spray bottle), Cuppy (100 ml measuring cup), grow bags (12"×12" LDPE), wooden name labels.

**THE 5 RULES (global, every gardener — recurring in-app mechanic):**
① 5 minutes every day (mist, check, cheer them on — never skip a day in Phase 1)
② How to water (Phase 1: Misty only, 10–15 sprays from 10 cm, never pour · Phase 2: Cuppy slowly in circles around inside edge, never centre, watch drainage)
③ Sunlight 4–6 hrs direct sun daily; cold = no sprouting
④ Thinning: snip weaker at soil level, never pull
⑤ Graduation Rule: all 4 Graduation Signs before the Big Move; missing one → wait 3–4 days.
The 5 Rules become the app's tutorial + daily-mission engine rules.

**Phase structure per plant (drives level content — exact steps/numbers in CANON.md §4–5):**
Phase 1 Nursery (Corky) → Thinning → 4 Graduation Signs → Phase 2 Big Move to Grow Bag (per-plant soil mixes + burial style) → Phase 3 Growing & Harvest. Methi replaces this with Round 1 (cup) → Round 2 (grow bag).

**Physical↔digital badge parity:** guidebook sticker spots = app badges, exact canon names —
FIRST SPROUT + FIRST HARVEST (Tommy, Okki, Chilly), ROUND 1 HARVEST + ROUND 2 HARVEST (Methi).
The app awards the digital twin; child sticks the physical one in the book. One achievement, two artifacts.

## 3. App Flow (locked)

```
Splash (logo grows from a seed)
  → Parent Gate + Login (Firebase Auth; gamified garden-gate scene)
  → Kit Activation: QR scan (Laarish kit)  OR  Profession Selection ("I Am an Agriculturist")
  → Welcome to Agriculturist (3D animated intro — Rishi/Ayra + all 4 mascots)
  → Motivational Story Video (skippable after first watch)
  → Curiosity Questions (Why plants? Why farming? — swipeable animated Q&A cards)
  → Journey Roadmap (the GARDEN PATH — Candy-Crush-style vertical scroll map)
       Tommy → Okki → Chilly → Methi   (sequential unlock)
       Each plant = 5 levels:
         L1 Kit Introduction   (meet tools, unbox, drag-match minigame)
         L2 Seeding            (interactive: soak, fill, poke, drop seeds, label, mist)
         L3 Watering & Care    (daily-care loop: mist/water/sunlight, streaks, thinning event)
         L4 Plant Growth       (graduation signs checklist, transplant to grow bag, photo moments)
         L5 Harvesting         (harvest celebration, count your harvest, badge)
  → Profession Completed
  → 🏆 Proud Agriculturist Badge + 📜 Digital Certificate (child's name) + 🎉 Celebration
```

**Level internal loop (every level):** Intro by mascot → Learn (animated micro-lesson) →
Do (real-world action, confirmed in app / mini-interaction) → Quiz spark (1–3 curiosity questions) →
Reward drop (stars, Sun Points, Seed Coins, sometimes badge) → path advances.

**Time-realistic levels:** L3/L4 span real days/weeks (plants grow slowly). The app handles this with
daily check-ins, streaks, "patience missions" (especially Chilly), and push-style local reminders —
never fake-skipping real growth. See GAMIFICATION.md.

## 4. Screen Inventory

| # | Screen | Gamified treatment |
|---|---|---|
| S1 | Splash | Seed falls, sprouts into Laarish logo; particles |
| S2 | Login / Parent gate | Garden gate opens on success; mascots peek from bushes; parent gate = simple math for adults |
| S3 | QR Scan | Viewfinder framed by sunflower petals; scan success = petal burst |
| S4 | Profession Select | 3D card carousel ("I Am an Agriculturist" active; others "coming soon" silhouettes) |
| S5 | Welcome Intro | Full-screen layered-parallax 3D scene, characters introduce themselves (speech bubbles like PDF p.1) |
| S6 | Story Video | video_player in decorated frame, skip after first completion |
| S7 | Curiosity Questions | Swipe cards, each answer blooms a flower |
| S8 | Journey Roadmap | THE flagship screen. Winding garden path, 20 level nodes, parallax sky/clouds/hills, mascot idles at current node |
| S9 | Level screens ×20 | Per-level interactive scenes (see ARCHITECTURE.md content model) |
| S10 | Daily Care Home | "My Garden" — live plant status, streak flame, today's missions |
| S11 | Badge Book | Sticker-album mirroring the guidebook badge spots |
| S12 | Certificate | Animated seal + child name, share/save as image |
| S13 | Profile/Settings | Inside a wooden signpost UI; parent-gated |

## 5. Tech Stack (locked — see ARCHITECTURE.md for detail)

- **Flutter 3.x (stable), Dart 3, Impeller renderer** — Android + iOS from one codebase.
- **No external game engine** (no Unity/Unreal/Godot). The "engine" is Flutter itself:
  Rive (vector state-machine animation), fragment shaders, CustomPaint, flutter_animate, physics simulations.
- **Rive** — mascot characters, buttons, login scene, interactive level objects (state machines respond to input).
- **Lottie** — celebration/confetti/one-shot effects where Rive is overkill.
- **Pre-rendered 3D**: hero images & image-sequences generated in the guidebook's art style (same pipeline that made the PDF art) — this is how the app matches the PDF exactly.
- **Firebase Auth** (email + Google) for login. **All game data local** (Isar DB) during development/APK testing; Firestore sync layer stubbed behind a repository interface for later.
- **Riverpod** (state), **go_router** (navigation), **mobile_scanner** (QR), **just_audio** (BGM/SFX), **video_player**, **confetti**, **flutter_animate**.

## 6. Non-Goals (v1)

- No multiplayer/social feed. No chat. No ads. No in-app purchases.
- No server-side gameplay logic (local-first; Firestore later).
- No AR. No user-generated content beyond photos stored locally.
- Only the Agriculturist profession is playable; others are teaser cards.

## 7. Success Criteria

- 60 fps sustained on mid-range Android (throttled effects allowed per perf convention — never reduced visuals).
- A child can navigate everything without reading fluently (icons, voice-over hooks, mascot guidance).
- Every guidebook step appears in the app in the same order with the same numbers (ml, mm, weeks).
- The roadmap scroll feels like a AAA casual game — springy, parallax, alive.
