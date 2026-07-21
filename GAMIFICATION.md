# GAMIFICATION.md — Reward Economy & Retention Loops

Goal: a child WANTS to return daily — because the game celebrates them and the real plant needs them.
The real plant is the ultimate retention mechanic; the app amplifies it.

## 1. Currencies & meters

| Currency | Earned by | Spent on | Notes |
|---|---|---|---|
| ☀️ **Sun Points** (XP) | every step, quiz, mission | never spent | drives Gardener Rank |
| 🪙 **Seed Coins** | levels, chests, streaks, perfect quizzes | cosmetics: buddy outfits (hats, boots, tools), garden decorations for My Garden, sticker frames | soft currency, generous |
| ⭐ **Stars** | per level 1–3 (completion / quiz correct / real-task confirmed) | gate nothing (no punishment); fill plant Star Meter → bonus chest at 12–15 stars per plant | replay levels to improve |
| 🔥 **Streak** | all daily missions done | streak badges at 3/7/14/30; streak shield item (1 miss forgiven, earned weekly) | resets gently: "Tommy missed you!" never shaming |

**Gardener Rank (Sun Points):** Sprout → Helper → Grower → Green Thumb → Plant Hero → **Proud Agriculturist**.
Rank-up = full celebration + new title on profile signpost.

## 2. Badge Book (mirrors physical guidebook stickers)

Digital sticker album, same art as guidebook badge seals (gold rosette, red ribbon tails).

**Canon badges (exact guidebook names — physical sticker twins, CANON.md §6):**
`FIRST SPROUT` + `FIRST HARVEST` for Tommy, Okki, Chilly · `ROUND 1 HARVEST!` + `ROUND 2 HARVEST!` for Methi.
When earned, app prompts: "Stick your real badge in your book too!" — physical/digital parity.

**App-only extra badges (same seal style, new art):**
`First Seed`, `Thinning Brave` (snipped the weaker sprout — never pulled!), `Graduation Day`
(4 signs checklist), `Big Move` (transplant), `First Flower`, `5-Rules Keeper` (followed all 5 Rules a full week),
`Patience Master` (Chilly days 10–14 check-ins), `Photo Reporter` (5 plant photos),
`Curious Mind` (all curiosity questions), streak badges,
and the final 🏆 **Proud Agriculturist** + 📜 Certificate (child's name, animated gold seal, saveable image).

## 3. Daily loop (the core habit)

```
Open app → My Garden (S10): plants greet you (Rive wave)
  → Today's Missions (2–4, from plant stage + guidebook schedule):
      "Mist Tommy with Misty" · "Check for sprouts!" · "Water 4 Cuppys slowly in circles"
      "Patience mission: Chilly is sleeping. Come back tomorrow — nothing to do IS the job!"
  → each mission: tiny interaction + real-world act + optional photo
  → all done → streak flame +1 → daily chest (Seed Coins, sometimes cosmetic)
```

- Local notifications (parent-approved, max 1/day): mascot-voiced reminders — "Misty is thirsty for work! 💦".
- **Growth check-in:** photo timeline per plant ("Tommy's diary") — before/after slider at harvest. Emotional payoff.

## 4. Session pacing & waiting design

Real growth = waiting. Waiting is designed, not hidden:
- **Sprout countdown:** "Tommy sprouts in 5–7 days" — soil mound with animated "?" that cracks a little each day (anticipation).
- While waiting, unlock **side content**: curiosity quiz packs, buddy dress-up, garden decoration, replay levels for 3 stars.
- **Chilly teaches patience explicitly** (canon: "Slow sprouting? Totally normal!") — patience missions reward waiting itself.

## 5. Moment-to-moment juice (from DESIGN_SYSTEM.md — mandatory)

- Every step completion: SFX + haptic + sparkle + Sun Points fly to HUD.
- Level complete: RewardOverlay full celebration; roadmap node blooms on return.
- Quiz correct: flower blooms per correct answer; wrong: mascot encourages, retry free.
- Idle screens: something always alive (mascot blink, butterfly, floating pollen).

## 6. Encouragement rules (children ≥ safety)

- No failure states, no lives, no timers that punish, no losing currency ever.
- Wrong answers → "Almost! Try again 🌱" with hint; infinite retries.
- Missed streak → warm welcome-back mission worth double, never guilt.
- All rewards deterministic (no gambling-style random loot beyond cosmetic chest variety).
- Comparison-free: no leaderboards in v1.

## 7. Reward table (initial values — balance later, keep in `RewardTable`, tested)

| Event | Sun Points | Seed Coins |
|---|---|---|
| Lesson step | 10 | — |
| Interaction step | 15 | — |
| Real task confirmed | 30 | 5 |
| Quiz correct (first try) | 20 | 2 |
| Level complete | 50 | 10 |
| Level 3-star | +30 | +10 |
| Daily missions all done | 25 | 5 + chest |
| Badge earned | 100 | 20 |
| Plant completed (L5) | 250 | 50 |
| Profession complete | 1000 | 200 + certificate |
