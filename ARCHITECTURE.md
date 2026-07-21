# ARCHITECTURE.md — System Design (HLD + LLD)

## 1. High-Level Design

```
┌─────────────────────────────────────────────────────────────┐
│                        PRESENTATION                          │
│  Screens (S1–S13) · Rive scenes · Level Engine · HUD        │
│  go_router navigation · RewardOverlay · Transitions          │
├─────────────────────────────────────────────────────────────┤
│                     APPLICATION (Riverpod)                    │
│  AuthController · ProgressController · EconomyController     │
│  StreakController · MissionController · LevelRunner (FSM)    │
├─────────────────────────────────────────────────────────────┤
│                          DOMAIN                               │
│  Entities: Profile, PlantProgress, LevelResult, Badge,       │
│  Wallet, Streak, Mission · Rules: UnlockPolicy, RewardTable  │
├─────────────────────────────────────────────────────────────┤
│                           DATA                                │
│  ProgressRepository ──► IsarProgressRepo   (v1, local)       │
│                    └──► FirestoreProgressRepo (v2, stub)     │
│  AuthRepository ──► FirebaseAuthRepo                          │
│  ContentRepository ──► AssetContentRepo (JSON in assets/)     │
├─────────────────────────────────────────────────────────────┤
│                         SERVICES                              │
│  AudioService · HapticService · LocalNotificationService     │
│  QrService · MediaService (photos) · ThrottledTicker(30fps)  │
└─────────────────────────────────────────────────────────────┘
```

**Key decisions & why**

| Decision | Why |
|---|---|
| Single codebase, feature-first folders | Small team/agents; features are independent workstreams (see PARALLEL_AGENTS.md) |
| Repository interfaces from day 1 | Firestore swap later without touching features; APK dev runs offline |
| Content-driven level engine | 20 levels = 20 JSON files + assets, ONE engine. New plants are data. |
| Riverpod | Compile-safe DI + reactive state; controllers testable without widgets |
| Local storage: single JSON file (path_provider + dart:io) | Isar v3's generator is incompatible with current Dart/analyzer (dependency deadlock); this app's data (1 profile, 1 wallet, 4 plants, badges, streak) is tiny — one JSON blob is simpler and has zero codegen. Reactivity comes from Riverpod, not DB watch-streams. Swappable behind `ProgressRepository` the same as Isar would've been. |
| Rive over frame-by-frame | State machines give input-reactive characters at tiny file size |

## 2. Folder Structure (create exactly this)

```
lib/
  main.dart                      # bootstrap: Firebase.init, Isar.open, runApp
  app/
    router.dart                  # go_router config, route guards (auth, unlock)
    app.dart                     # MaterialApp.router, theme, global overlays
  core/
    theme/                       # colors, typography, spacing (from DESIGN_SYSTEM.md)
    widgets/                     # LaarishButton, StickerCard, SpeechBubble, HudBar...
    motion/                      # springs, curves, ThrottledTicker, transitions
    audio/                       # AudioService
    utils/
  content/
    models/                      # LevelContent, StepSpec, QuizSpec (json_serializable)
    content_repository.dart
  features/
    auth/                        #   S2 login + parent gate
    onboarding/                  #   S1 splash, S3 QR, S4 profession, S5 intro, S6 video, S7 questions
    roadmap/                     #   S8 garden path map
    level_engine/                #   S9 generic level runner + step widgets + minigames
    garden_home/                 #   S10 daily care, missions, streak
    rewards/                     #   S11 badge book, S12 certificate, RewardOverlay
    profile/                     #   S13 settings (parent-gated)
  data/
    local/                       # entity classes + JsonFileProgressRepo
    firebase/                    # FirebaseAuthRepo, firestore_stub.dart
    repositories.dart            # abstract interfaces
assets/
  content/                       # tommy_l1.json ... methi_l5.json, questions.json, missions.json
  rive/                          # mascots, gate, buttons, nodes
  images/                        # pre-rendered 3D art (webp), per-biome backgrounds
  lottie/                        # confetti, shine, sparkle
  audio/                         # bgm/, sfx/
  shaders/                       # sky.frag, glow.frag, water.frag
  video/                         # story.mp4 (or streamed later)
test/
  domain/                        # unlock, rewards, streak, economy tests
  content/                       # JSON schema validation test (all 20 levels parse)
```

## 3. Low-Level Design

### 3.1 Domain entities (plain Dart classes, JSON-serialized to one file)

```dart
// Profile: one per device-child
Profile { id, name, buddy /*rishi|ayra*/, avatarSeed, createdAt }

// Wallet
Wallet { sunPoints /*XP, never spent*/, seedCoins /*soft currency*/ }

// PlantProgress: one per plant
PlantProgress {
  plantId /*tommy|okki|chilly|methi*/,
  levelsDone /*0..5*/,
  stars /*per level 0..3*/,
  stage /*enum: locked→nursery→thinned→graduated→growBag→flowering→harvested(→round2 for methi)*/,
  realDates { plantedAt, sproutedAt, transplantedAt, harvestedAt },
  photos [localPaths]
}

// Badge
Badge { id, earnedAt }        // ids fixed in RewardTable (firstSprout_tommy, ... proudAgriculturist)

// Streak
Streak { current, best, lastCompletedDay }

// Mission (generated daily, not stored long-term)
Mission { id, plantId, type /*mist|water|check|thin|patience|photo*/, done }
```

### 3.2 Unlock policy (pure functions — test these)

```
levelUnlocked(plant, level)   = level == 1 ? plantUnlocked(plant) : levelsDone(plant) >= level-1
plantUnlocked(tommy)          = professionStarted   // GameSave.kitActivated, set on ProfessionScreen confirm
plantUnlocked(okki)           = tommy.levelsDone == 5
plantUnlocked(chilly)         = okki.levelsDone == 5
plantUnlocked(methi)          = chilly.levelsDone == 5
professionComplete            = all four levelsDone == 5   → certificate + proudAgriculturist badge
```
`UnlockPolicy.plantUnlocked`/`levelUnlocked` take `professionStarted` as a required named param — callers pass `GameSave.kitActivated`, not a hardcoded `true`.
Gating exception: L3→L4→L5 additionally gate on real-time checkpoints (e.g. L5 harvest requires
stage ≥ flowering). `stage` advances via realTask confirmations + date thresholds from content JSON.

### 3.3 Level content model (JSON)

```jsonc
// assets/content/tommy_l2.json
{
  "plantId": "tommy", "level": 2, "title": "Seeding Day!",
  "biome": "tommy",
  "steps": [
    { "type": "mascotIntro", "rive": "tommy_wave", "lines": ["It's planting day!", "Let's wake up Corky!"] },
    { "type": "interaction", "game": "soak",  "prompt": "Soak Corky for 5 minutes", "asset": "corky_bowl" },
    { "type": "interaction", "game": "fill",  "prompt": "Fill with nursery mix. Leave 10 mm!", "target": {"gapMm": 10} },
    { "type": "interaction", "game": "poke",  "prompt": "Poke ONE hole, 6 mm deep. Diggy checks!", "target": {"depthMm": 6} },
    { "type": "interaction", "game": "drop",  "prompt": "Drop in 2 tomato seeds. Cover gently.", "count": 2 },
    { "type": "interaction", "game": "label", "prompt": "Label your cup: TOMMY + date" },
    { "type": "interaction", "game": "mist",  "prompt": "Mist with Misty!" },
    { "type": "realTask",   "prompt": "Now do it for real with your kit!", "confirm": "photoOptional" },
    { "type": "quiz", "q": "How many seeds in one cup?", "options": ["1","2","5"], "answer": 1 },
    { "type": "reward", "stars": true, "sunPoints": 50, "seedCoins": 10 }
  ]
}
```
`LevelRunner` = finite state machine over `steps[]`; each `type` maps to a step widget.
Minigame set (`soak/fill/poke/drop/label/mist/pour/snip/scatter/pick/match/count`) lives in
`level_engine/minigames/` — 12 small interaction widgets reused across all 20 levels.

### 3.4 Reward flow (sequence)

```
LevelRunner(step: reward)
  → EconomyController.award(RewardTable[levelId])      // pure math, tested
  → RewardOverlay.show(items)                          // spring-in, confetti, count-up
  → ProgressRepository.save(levelResult)               // Isar txn
  → StreakController.tickIfDailyDone()
  → router: back to roadmap → camera scrolls to next node → node bloom animation
```

### 3.5 Firestore-later contract

`ProgressRepository` interface is the seam. v2 adds `FirestoreProgressRepo` + a
`SyncService` (last-write-wins per collection, child data under `users/{uid}/...`).
No feature code changes. Do not design sync logic now (YAGNI) — only keep the interface clean:
all writes go through repository methods, no direct Isar access from features.

### 3.6 Performance budget

| Item | Budget |
|---|---|
| Frame build+raster | ≤ 8 ms build, ≤ 8 ms raster (mid Android) |
| Roadmap path | painted once, cached Picture; repaint only on theme change |
| Parallax layers | Transform-only (no relayout); images pre-scaled webp |
| Ambient drift/blur FX | via ThrottledTicker 30fps (project convention — throttle, never remove) |
| Rive artboards live simultaneously | ≤ 3 (current node mascot, HUD, one FX) |
| Image memory | per-biome sprites lazy-loaded/evicted on biome scroll change |
| App size | ≤ 60 MB APK: webp, ogg audio, 720p video, Rive vectors |

### 3.7 Error handling

- Auth errors → friendly mascot messages, mapped table (no raw Firebase strings to kids).
- Isar write failures → retry once, then in-memory queue + banner "your garden will save soon" (never lose a level result silently — queue drains on next open).
- Content JSON parse errors → fail loudly in debug (schema test catches in CI), fallback "level resting" screen in release.
- Video/asset missing → skip gracefully to next flow step.
