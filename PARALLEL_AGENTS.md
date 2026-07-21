# PARALLEL_AGENTS.md — Multi-Agent Parallel Workplan

How multiple AI subagents (or devs) build Laarish simultaneously with zero merge conflicts.
Every agent reads AGENT.md + ARCHITECTURE.md + DESIGN_SYSTEM.md first. One agent = one workstream = one directory ownership.

## 1. Ground rules

1. **Ownership = write access.** An agent writes ONLY inside its owned paths (table below). Reading anything is fine.
2. **Shared files are owned by the Foundation agent** (`pubspec.yaml`, `router.dart`, `app.dart`, `main.dart`, theme). Other agents REQUEST changes (list them in their handoff note); Foundation applies them. This kills 90% of conflicts.
3. **Contracts before code.** Phase 0 freezes: repository interfaces, `LevelContent` JSON schema, theme tokens, route names, Riverpod provider names. After freeze, agents depend on contracts, not on each other's code.
4. **Stubs first.** Foundation ships compiling stubs for every interface (in-memory repo, placeholder content, empty screens registered in router) so every workstream builds & runs against stubs from day one.
5. **Each agent ships its own tests** in `test/<workstream>/` (also disjoint).
6. **Git:** one branch per workstream (`ws/roadmap`, `ws/level-engine`, ...). Rebase on main daily. Foundation merges in dependency order.
7. **Assets are pre-namespaced** (`assets/images/<biome>/`, `assets/rive/`, per table) — no two agents touch the same asset folder. Asset manifest additions go through Foundation.

## 2. Workstreams & ownership map

| WS | Agent | Owns (write) | Depends on |
|---|---|---|---|
| **WS0 Foundation** | foundation | `lib/main.dart`, `lib/app/`, `lib/core/`, `lib/data/repositories.dart` (interfaces), `pubspec.yaml`, CI, stubs | — (goes first) |
| **WS1 Auth & Onboarding** | onboarding | `lib/features/auth/`, `lib/features/onboarding/`, `assets/rive/gate*`, `assets/images/onboarding/`, `assets/video/` | WS0 contracts |
| **WS2 Roadmap** | roadmap | `lib/features/roadmap/`, `assets/images/biome_*/`, `assets/shaders/glow.frag`, `assets/shaders/sky.frag` | WS0 |
| **WS3 Level Engine** | level-engine | `lib/features/level_engine/`, `lib/content/`, `assets/content/`, minigame assets `assets/images/minigames/` | WS0; schema frozen in Phase 0 |
| **WS4 Garden Home & Missions** | garden | `lib/features/garden_home/`, `assets/images/garden/`, notification service impl | WS0 |
| **WS5 Rewards & Economy** | rewards | `lib/features/rewards/`, domain `RewardTable`/`UnlockPolicy` impl + tests, `assets/lottie/`, badge art | WS0 |
| **WS6 Data Layer** | data | `lib/data/isar/`, `lib/data/firebase/` | WS0 interfaces |
| **WS7 Content & Audio** | content | 20 level JSONs, curiosity questions, missions JSON, all copywriting, `assets/audio/` | WS3 schema |
| **WS8 QA/Perf** | qa | `test/integration/`, perf scripts, DevTools audits (writes reports only) | all, last |

## 3. Interface contracts (frozen at end of Phase 0)

- `ProgressRepository`, `AuthRepository`, `ContentRepository` — exact method signatures in `lib/data/repositories.dart`.
  `AuthRepository.currentUserId` (nullable) is part of the freeze for WS6's future Firestore path. `ContentRepository.loadJson(assetPath)` is the generic loader WS1/WS4/WS7 use for `questions.json`/`missions.json` — don't add per-content methods, extend this one.
- `LevelContent` JSON schema (ARCHITECTURE.md §3.3) + `schema_test.dart` that validates every file in `assets/content/`.
- `RewardOverlay.show(RewardBundle)` API — everyone celebrates through this one door (owned WS5, stubbed WS0).
- `AudioService.play(Sfx.pop)` enum — WS7 fills files, enum frozen early.
- Route table in `router.dart`: `/login, /qr, /profession, /intro, /story, /questions, /map, /level/:plant/:n, /garden, /badges, /certificate, /settings`.
- Theme tokens `LaarishColors.*`, `LaarishMotion.*` — names frozen, values tweakable by WS0 only.

## 4. Execution order

```
Phase 0 (solo, WS0): scaffold app, contracts, stubs, theme, CI          ← nothing parallel yet
Phase 1 (PARALLEL ×6): WS1, WS2, WS3, WS4, WS5, WS6 against stubs
Phase 2 (PARALLEL ×2): WS7 content fills engine · WS8 integration+perf
Phase 3 (solo, WS0): merge train (WS6 → WS5 → WS3 → WS2 → WS1 → WS4 → WS7), polish pass, release APK
```

## 5. Handoff note format (every agent, end of task)

```md
## WS<id> handoff
- Done: <files/features>
- Requests for Foundation: <pubspec deps, router entries, asset manifest lines>
- Contract deviations: none | <what + why>
- Tests: <paths, all passing>
- Known gaps: <list>
```

## 6. Conflict tripwires (abort & escalate if hit)

- Needing to edit a file outside your ownership → write it in the handoff request instead.
- Needing a contract change after freeze → stop, escalate to Foundation, all dependents notified.
- Two agents needing the same new core widget → Foundation builds it in `core/widgets/`, both consume.
