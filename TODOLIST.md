# TODOLIST.md — Implementation Checklist (no timeline; order = dependency)

Legend: `[ ]` todo · `[~]` in progress · `[x]` done. WS = workstream (PARALLEL_AGENTS.md).

## Phase 0 — Foundation (WS0, solo, blocks everything)

- [ ] `flutter create laarish` (org id, Android minSdk 24, iOS 13), enable Impeller, add app icon from Logo.jpeg
- [ ] Add deps: riverpod/hooks_riverpod, go_router, rive, lottie, isar+isar_flutter_libs, firebase_core, firebase_auth, google_sign_in, mobile_scanner, just_audio, video_player, confetti, flutter_animate, sensors_plus, json_serializable/build_runner, flutter_local_notifications
- [ ] Firebase project + `flutterfire configure` (Android APK signing debug keys registered)
- [ ] `core/theme/`: LaarishColors, LaarishText (Baloo 2 + Nunito), spacing — tokens per DESIGN_SYSTEM.md
- [ ] `core/motion/`: spring constants, curve vocabulary, `ThrottledTicker(30fps)`, themed page transitions (leaf-wipe, iris)
- [ ] `core/widgets/`: LaarishButton (gummy 3D press), StickerCard, SpeechBubble, RibbonBanner, StepCircle, HudBar (SunPoints/SeedCoins/streak counters with fly-to animation targets)
- [ ] `core/audio/AudioService` + Sfx enum (placeholder silent files)
- [ ] `data/repositories.dart` — abstract ProgressRepository/AuthRepository/ContentRepository (CONTRACT FREEZE)
- [ ] In-memory stub repos + placeholder screens wired in `router.dart` (full route table)
- [ ] `LevelContent` model + JSON schema + `schema_test.dart` (CONTRACT FREEZE)
- [ ] RewardOverlay API stub (`show(RewardBundle)`)
- [ ] CI: `flutter analyze` + `flutter test` on push
- [ ] Commit contracts; tag `phase0-freeze`

## Phase 1 — Parallel workstreams

### WS1 Auth & Onboarding
- [ ] S1 Splash: seed→sprout→logo Rive/sequence, preload assets behind it
- [ ] S2 Login: Firebase email+Google; Rive garden gate (idle/typing eyes-follow/success gate-open/error friendly shake); parent gate math overlay
- [ ] S3 QR scan: mobile_scanner, sunflower-petal viewfinder, `laarish://kit/<id>` payload, petal-burst success
- [ ] S4 Profession carousel: perspective 3D cards, Agriculturist active, teaser silhouettes
- [ ] S5 Welcome intro: multi-layer parallax scene + tilt, characters self-introduce (speech bubbles, canon lines from PDF p.1)
- [ ] S6 Story video: framed player, skip-after-first-watch persistence
- [ ] S7 Curiosity questions: swipe cards, flower-bloom on answer, results feed Curious Mind badge
- [ ] Onboarding state machine: resume where left off; skip path for returning users

### WS2 Roadmap (flagship)
- [ ] GardenPathPainter: S-curve spline, dashed footsteps, cached Picture, vine-fill progress sweep
- [ ] 4 biome bands + vertical cross-fade (Tommy/Okki/Chilly/Methi palettes + foliage sprites)
- [ ] Parallax controller (4 layers ×0.2/0.4/0.7/1.0) + foreground leaves 1.15
- [ ] Sky fragment shader (animated gradient + god rays, ThrottledTicker)
- [ ] LevelNode widget: locked bud / unlocked bloom-wobble / done fruit+stars; spring stagger pop-in on viewport entry
- [ ] Current-node: glow shader pulse + Rive mascot idle + camera magnetism (easeOutBack auto-scroll)
- [ ] Chest sub-nodes (bonus Seed Coins), star meters per node
- [ ] Ambient critters: pooled butterfly/bee bezier flights, pollen particles (one CustomPainter system)
- [ ] Node→level iris transition
- [ ] Perf pass: frame chart ≤ 8ms/8ms on mid Android

### WS3 Level Engine
- [ ] LevelRunner FSM over `steps[]`; progress bar as growing vine
- [ ] Step widgets: mascotIntro (Rive + typewriter bubble), lesson (animated sticker-card carousel), quiz (3D flip cards, bloom-on-correct), realTask (do-it-for-real + optional photo confirm), reward (hands off to RewardOverlay)
- [ ] 12 minigames: soak, fill (10mm gap gauge), poke (6mm depth with Diggy ruler), drop (2 seeds), label, mist (swipe-spray with water shader), pour (400ml/4 Cuppys circular pour), snip (thinning scissors trace), scatter (Methi), pick (harvest pluck), match (kit intro pairs), count (harvest counting)
- [ ] Real-time gates: stage thresholds from content JSON (sprout window, graduation signs checklist UI, transplant unlock)
- [ ] Photo capture + local storage (MediaService) for plant diary
- [ ] Replay-for-stars mode

### WS4 Garden Home & Missions
- [ ] S10 My Garden: per-plant live cards (stage art, greeting Rive wave), streak flame, sprout-countdown soil mound with daily crack animation
- [ ] MissionController: generate daily missions from stage + guidebook schedule (mist/water/check/thin/patience/photo)
- [ ] Mission interactions + all-done daily chest
- [ ] Streak logic + shield item + gentle-reset copy (tests)
- [ ] Local notifications: 1/day max, parent-gated opt-in, mascot copy
- [ ] Plant diary timeline (photos, before/after slider)

### WS5 Rewards & Economy
- [ ] RewardTable + EconomyController (pure, tested per GAMIFICATION.md §7)
- [ ] UnlockPolicy pure functions + tests (ARCHITECTURE.md §3.2)
- [ ] RewardOverlay full implementation: dim, spring-in, confetti+Lottie shine, count-up, fly-to-HUD
- [ ] Badge system: ids, award triggers, S11 Badge Book sticker album (physical-parity prompt "stick your real badge!")
- [ ] Gardener Rank ladder + rank-up celebration
- [ ] Buddy cosmetics shop (Seed Coins): outfits, garden decorations
- [ ] S12 Certificate: child name, animated gold seal, render-to-image share/save
- [ ] Profession-complete grand celebration sequence

### WS6 Data Layer
- [ ] Isar collections (Profile, Wallet, PlantProgress, Badge, Streak) + IsarProgressRepo
- [ ] Write-retry + in-memory queue banner behavior (ARCHITECTURE.md §3.7)
- [ ] FirebaseAuthRepo (error→friendly-message map)
- [ ] firestore_stub.dart (interface-conforming, throws UnimplementedError) — placeholder only
- [ ] Repo integration tests (in-memory Isar)

## Phase 2 — Content & QA (parallel)

### WS7 Content & Audio
- [x] 20 level JSONs (tommy_l1…methi_l5) — every number/step/dialogue from CANON.md (verbatim quoted lines; soil recipes, ml, mm, weeks; Okki overnight soak; Methi round-2 flow; Chilly patience content; 5 Rules as tutorial + recurring reminders)
- [ ] Confirm CANON.md §7 conflicts with Laarish team (Okki burial depth, Chilly grow-bag water) and update JSONs
- [ ] Curiosity question packs (why plants? why farming? + per-plant fun facts)
- [ ] missions.json schedules per stage
- [ ] All copy: ≤8-word sentences, mascot voice per character (Tommy heroic, Chilly cool/patient, Methi speedy, Okki cheerful)
- [ ] Audio: BGM loop + full SFX set (ogg), wire Sfx enum
- [ ] Art integration: pre-rendered 3D stills/sequences per biome & minigame (guidebook style), Rive rigs for 6 characters (4 mascots + Rishi + Ayra), badge seals, Lottie celebration set

### WS8 QA / Perf / Release
- [ ] Integration tests: full flow login→L1 complete; offline cold-start; resume mid-level
- [ ] Content audit: JSON vs guidebook numbers (checklist per plant)
- [ ] Perf audit on mid Android: roadmap scroll, level transitions, RewardOverlay — frame charts recorded
- [ ] Memory audit: biome image eviction, ≤3 live Rive artboards
- [ ] APK size ≤60MB check; release build + signing; sideload test round

## Phase 3 — Merge & Polish (WS0)
- [ ] Merge train: WS6→WS5→WS3→WS2→WS1→WS4→WS7, fix seams
- [ ] Global polish pass: transition timing, SFX/haptic coverage ("silence is a bug" sweep)
- [ ] Final child playtest checklist (no-reading navigation, tap sizes, celebration density)
- [ ] Tag v1.0, build release APK
