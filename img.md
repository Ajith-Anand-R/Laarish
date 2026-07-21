# img.md — Laarish Visual Asset Prompts

All artwork the app needs, with ready-to-paste generation prompts. Music/SFX/video are out of scope here — this file is **visuals only**.

Canon source of truth: `CANON.md` §1 (cast), §8 (visual canon). Never change a character's costume or colors.

---

## 0. GLOBAL RULES (read once, applies to every prompt)

**Art style (paste as a prefix or keep consistent every time):**
> Pixar-style 3D render, cute kawaii mascot, big glossy expressive eyes, soft rounded forms, warm sunlight, soft global-illumination shadows, subtle subsurface glow, smooth clay-like matte surfaces, children's-book charm, high detail, centered, full body in frame.

**Background rule — CRITICAL:**
- **Characters, mascots, tools, badges, props** → generate on a **PURE BLACK (#000000) background**, nothing else behind the subject. This is required: `tool/cutout.py` flood-removes pure black to transparency. Any other bg color breaks the cutout.
- **Scene backgrounds / biome art / app icon** → full opaque scene, no cutout.

**Negative prompt (always):**
> text, letters, words, watermark, signature, logo, extra limbs, duplicate character, deformed hands, blurry, low-res, busy background, multiple backgrounds, gradient background, drop shadow on floor edges cut off, frame, border.

**After generating any cutout asset:**
1. Save as `.jpeg` (or `.png`) into `images/` using the exact filename below.
2. Add its base name to the `CUTOUTS` list in `tool/cutout.py` (if new).
3. Run `python tool/cutout.py` → produces the transparent PNG in `assets/images/`.
4. Tell me — I wire it into the screens.

**Consistency tip:** generate the whole set in ONE session / same seed family so all six characters share one look. If you regenerate one mascot, regenerate its card too so they match.

---

## 1. 🔴 PRIORITY — MISSING NOW (blocks Okki everywhere)

Okki currently shows a fallback blob on every screen. These two unblock it.

### `images/okki_mascot.jpeg`  (1024×1024, black bg, cutout)
> [STYLE PREFIX] A cheerful okra-pod superhero mascot named Okki, THE SPEEDSTER. Tall slender bright-green okra pod body with faint vertical ridges, big friendly eyes, wide happy smile. Wears a **yellow bandana tied around the head with the tails flying back** as if running fast, and **green sneakers**. Dynamic mid-run pose, one arm pumping, leaning forward with speed, motion energy. Radiating fast/energetic vibe. Pure black background.

### `images/okki_card.jpeg`  (1024×1536, black bg — see §4 note on cards)
> [STYLE PREFIX] Trading-card portrait of Okki the okra-pod speedster mascot (yellow bandana with flying tails, green sneakers, running pose) standing next to a small cheerful boy with curly dark hair in a yellow t-shirt and brown shorts. Below them, three small circular icons: an alarm clock, a water-soak drop, a fast okra pod. Clean layout, generous empty margins, NO text. Pure black background.

---

## 2. Plant Mascots — full set (regenerate only if you want them matched)

You already have Tommy, Chilly, Methi. Prompts kept here so a re-gen stays on-canon. All 1024×1024, black bg, cutout → `images/{plant}_mascot.jpeg`.

### tommy_mascot — THE CLIMBER (have ✅)
> [STYLE PREFIX] A tomato superhero mascot named Tommy. Round glossy red tomato body with a green leafy top, big brave eyes, confident open smile. Wears a **green cape**, a **green belt with a golden "T" buckle**, and **red boots**. Heroic pose, one fist raised triumphantly. Powerful, patient, worth-the-wait vibe. Pure black background.

### chilly_mascot — THE SLOW BURN (have ✅)
> [STYLE PREFIX] A red chilli-pepper mascot named Chilly. Long glossy curved red chilli body with a small green stem cap, cool confident smirk. Wears **black sunglasses** and **red boots**, **arms crossed**, a subtle **warm flame aura** glowing behind. Cool, calm, patient, slightly smug vibe. Pure black background.

### methi_mascot — THE QUICK GREENS (have ✅)
> [STYLE PREFIX] A round fenugreek (methi) mascot named Methi. Round bright-green body, **leafy fenugreek-frond hair on top**, big excited eyes, wide generous grin. Wears a **yellow headband** and **green boots**, **holding a small pair of garden scissors**. Speedy, generous, "many plants!" vibe. Pure black background.

---

## 3. Kids / Buddies (have all 3 ✅ — prompts for re-gen)

Portrait 1024×1536, black bg, cutout → `images/{name}.jpeg`.

### rishi_character  (+ `rishi_character_alt` = second pose)
> [STYLE PREFIX] A cheerful young boy named Rishi, age ~7, **curly dark hair**, **yellow t-shirt**, **brown shorts**, white sneakers. Curious friendly expression, pointing as if explaining a tip. Full body standing. Pure black background.

### ayra_character
> [STYLE PREFIX] A warm cheerful young girl named Ayra, age ~7, **long curly hair with a yellow flower tucked in it**, **yellow dress**, sandals. Encouraging happy expression, one hand giving a thumbs up. Full body standing. Pure black background.

### all_characters (have ✅) — group hero shot
> [STYLE PREFIX] Group shot: boy Rishi (curly hair, yellow tee, brown shorts) and girl Ayra (yellow dress, flower in hair) kneeling together, with the four plant mascots in front — Tommy (tomato, green cape), Okki (okra, yellow bandana), Chilly (chilli, sunglasses, flame), Methi (green, leafy hair, scissors). All smiling at camera, arranged in a friendly row. Pure black background.

---

## 4. Kit Tool Characters (NEW — nice-to-have, replace icon placeholders in minigames)

Each is a named cute character (CANON §1). 768×768, black bg, cutout → `images/tool_{name}.jpeg`. I'll wire these into the matching minigames.

| File | Prompt subject |
|---|---|
| `tool_corky` | A cute **coir/coco-fiber nursery cup** character named Corky — short round brown fibrous pot with a friendly face, tiny arms, soft smile. Damp dark-brown look. |
| `tool_diggy` | A cute **wooden ruler/dibber** character named Diggy — flat wooden stick with black measurement marks (mm), a friendly face near the top, tiny arms, one hand giving a helpful point. |
| `tool_misty` | A cute **spray bottle** character named Misty — small translucent spray bottle with a trigger, big eyes, a happy face, a tiny water droplet sparkle at the nozzle. |
| `tool_cuppy` | A cute **100 ml measuring cup** character named Cuppy — small clear measuring cup with a "100 ml" line, friendly face, tiny arms. |
| `tool_growbag` | A cute **white 12"×12" LDPE grow-bag** character with a friendly face, a little soil peeking at the top, tiny arms. |
| `tool_label` | A cute **wooden plant-label stake** character, blank cream label area at top (no text), pointed bottom, small friendly face. |

Each prompt = `[STYLE PREFIX]` + subject above + " Pure black background."

**Note on the four `*_card.jpeg` poster cards:** AI bakes garbled text (existing cards say "SUPER HUMBER"/"SUFER POWER"). **Recommendation:** generate cards with the character + power icons but **NO baked text**; the app renders titles/labels crisply on top. If you want text baked anyway, proof-read every letter.

---

## 5. Minigame Prop Stills (NEW — optional polish, per-interaction)

Small hero props for the 12 minigames. 512×512, black bg, cutout → `images/mg_{key}.jpeg`. Currently code-drawn blobs stand in; these upgrade them. Style prefix + " Pure black background."

| File | Prompt subject | Canon number to respect |
|---|---|---|
| `mg_soak` | okra seeds soaking in a small bowl of water overnight, moon + alarm-clock accent | soak 8–12 hrs |
| `mg_fill` | Corky cup filled with dark crumbly nursery soil, 10 mm gap at the rim marked | leave 10 mm space |
| `mg_poke` | Diggy ruler poking a single hole in soil, depth marks visible | 6 mm (tomato/chilli), 12 mm (okra) |
| `mg_drop` | two seeds dropping into a soil hole | 2 seeds |
| `mg_label` | a wooden name-label stake pushed into a cup (blank label) | — |
| `mg_mist` | Misty spray bottle misting fine water droplets over a sprout | 10–15 sprays, 10 cm |
| `mg_pour` | Cuppy measuring cup pouring water in a circle around a grow-bag edge | 4 Cuppys / 400 ml (Methi 200 ml, Chilly 300 ml) |
| `mg_snip` | small scissors snipping the weaker of two sprouts at soil level | never pull |
| `mg_scatter` | a hand pinching and scattering tiny methi seeds over soil | cover 5 mm |
| `mg_pick` | a hand plucking a ripe red tomato / okra pod / red chilli | pick when ripe |
| `mg_match` | a tidy flat-lay of the kit tools (Corky, Diggy, Misty, Cuppy) for a matching game | — |
| `mg_count` | a basket / pile of harvested produce to count | — |

---

## 6. Biome Backgrounds & Roadmap Foliage (NEW — opaque scenes, NOT cutout)

Vertical scene art behind the roadmap and level screens, one warm palette per plant biome. 1080×1920 portrait, **opaque full scene** → `assets/images/biome_{plant}.jpg` (place directly, no cutout).

Palette per plant: Tommy = warm red/green tomato garden; Okki = fresh yellow-green okra field; Chilly = warm sunset red-orange chilli patch; Methi = bright lime-green leafy bed.

> [STYLE PREFIX minus "full body"] A soft dreamy children's-book **garden background scene**, gentle rolling hills, a warm sunny sky with soft clouds, blurred foliage, {PLANT} plants growing, cream-and-{BIOME COLOR} palette, calm and inviting, plenty of empty sky space at top for UI, no characters, no text. Painterly 3D, soft depth-of-field.

Also (optional) tiling foliage sprite strips for parallax: `images/foliage_{plant}.png` — a horizontal row of {plant} leaves/bushes on black bg (cutout), for the roadmap foreground layer.

---

## 7. Badges — gold rosette seals (NEW — Badge Book S11 + reward drops)

CANON §6 + GAMIFICATION.md §2. All identical seal style, only the center icon + ribbon differ. 512×512, black bg, cutout → `images/badge_{id}.jpeg`.

**Shared seal prompt (swap the CENTER ICON each time):**
> [STYLE PREFIX] A shiny **gold rosette award badge** — pleated gold medal disc with a scalloped edge, two **red ribbon tails** hanging below, glossy metallic highlights, a raised circular center medallion. In the center: **{CENTER ICON}**. Celebratory, premium, sticker-seal look. Pure black background. No text.

**Canon badges (physical sticker twins — must exist):**
| File | Center icon |
|---|---|
| `badge_tommy_sprout` | a tiny tomato sprout |
| `badge_tommy_harvest` | a ripe red tomato |
| `badge_okki_sprout` | a tiny okra sprout |
| `badge_okki_harvest` | a green okra pod |
| `badge_chilly_sprout` | a tiny chilli sprout |
| `badge_chilly_harvest` | a red chilli |
| `badge_methi_round1` | a bundle of fresh methi greens with a small "1" laurel |
| `badge_methi_round2` | a bundle of fresh methi greens with a small "2" laurel |

**App-only badges (same seal style):**
| File | Center icon |
|---|---|
| `badge_first_seed` | a single seed |
| `badge_thinning_brave` | small scissors over a sprout |
| `badge_graduation_day` | a graduation cap on a sprout |
| `badge_big_move` | a plant moving into a grow bag |
| `badge_first_flower` | a small yellow/white flower |
| `badge_five_rules` | a checklist with 5 ticks |
| `badge_patience_master` | a calm clock with a chilli |
| `badge_photo_reporter` | a little camera |
| `badge_curious_mind` | a glowing question-mark/lightbulb |
| `badge_streak_3` / `_7` / `_14` / `_30` | a flame with the number |
| `badge_proud_agriculturist` | a golden trophy with all four mascots tiny around it (the grand badge) |

---

## 8. Certificate (NEW — S12)

- `images/cert_seal.png` — 512×512, black bg, cutout. A large ornate **gold wax-seal / rosette** with green leaf laurels around it, empty center (app stamps the child's name). Premium, official, kids-friendly.
- `images/cert_frame.png` — 1200×1600, black bg, cutout. An ornate but playful **certificate border frame** (leaves, vines, sunflowers in the corners), empty middle. App renders "Proud Agriculturist" + child name inside.

---

## 9. App Icon (NEW — opaque, no cutout)

- `assets/images/app_icon.png` — 1024×1024, **opaque, full-bleed**. The Laarish logo mark on a warm cream/green rounded background, or Tommy's happy face peeking over a seedling. Bold, readable at small sizes, no fine text. (Wire later via `flutter_launcher_icons`.)

---

## 10. Onboarding / Splash Scene (optional, opaque)

- `assets/images/splash_scene.jpg` — 1080×1920. Cover scene (CANON §8): Rishi & Ayra kneeling in a sunny garden with a wooden Laarish seed shelf, the four mascots in front, blue sky. Warm, inviting, empty top area for the logo.

---

## Delivery checklist

- [ ] §1 Okki mascot + card (unblocks Okki) ← **do first**
- [ ] §7 the 8 canon badges (needed for Badge Book parity)
- [ ] §6 four biome backgrounds
- [ ] §4 six tool characters
- [ ] §5 minigame props · §8 certificate · §9 icon · §10 splash scene
- [ ] Re-run `python tool/cutout.py` after adding any black-bg asset
- [ ] Ping me → I wire each into its screen and run `flutter analyze && flutter test`

**Recap of what already exists:** `logo.jpeg`, `tommy/chilly/methi_mascot`, `rishi/ayra_character`, `all_characters`, `tommy/chilly/methi_card`. Everything else above is new.
