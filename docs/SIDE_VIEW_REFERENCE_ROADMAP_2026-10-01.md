# Side-view reference target and visual roadmap — 2026-10-01

Branch: `art/side-reference-pass-0.1.9`  
Parent work: `art/blender-knight-study`  
Scope: **first stage, side-view only**. The 3D camera mode and the remaining stages are intentionally out of scope until the side-view art direction is accepted.

## Why this document exists

The 0.1.8 art sample established the correct technical direction, but the phone screenshot from 2026-10-01 shows that the first stage is still visually closer to a prototype than to the supplied target image. This file records the visual decisions from the current design discussion so future work does not drift away from the approved direction.

The goal is not merely “better graphics”. The goal is a **reference-near 2.5D side-scrolling presentation**: fixed side camera, 3D characters and props, layered castle scenery, coherent materials, readable silhouettes and mobile-friendly performance.

## Reference package

Files in `art/references/side-view-2026-10-01/`:

- `hero_knight_sheet.jpg` — dark steel / bronze-red hero, front/side/back/3-quarter views, sword, helmet and cape clasp.
- `castle_environment_kit.jpg` — limestone floor tiles, walls, crenellations, pillar, gate, tower, stairs, crate, barrel, torch, banners, cypress trees, shrubs and statue accents.
- `enemy_weapon_sheet.jpg` — guard, shield guard and archer variants plus sword, shield and bow designs.
- `gameplay_target.jpg` — primary side-view gameplay composition and lighting target.
- `stage1_phone_before_pass.jpg` — actual phone state before this reference pass.

The image files are visual references, not assets to copy pixel-for-pixel. Production geometry, textures, symbols and proportions remain original project work.

## Locked visual direction

### Camera and composition

- Keep the first stage in side view.
- Orthographic / near-orthographic framing remains the gameplay camera.
- The playable strip sits in the lower part of the screen.
- The route ahead must remain readable.
- Foreground decoration may frame the scene, but must not cover hazards, gaps, enemies or the player's feet.
- Background should be visibly separated into gameplay plane, middle distance and far castle/mountain layers.
- The background image must not carry all of the scene detail by itself; near and mid-distance geometry must visually belong to the same world.

### Hero

Target traits:
- dark graphite/blackened steel armor;
- bronze/gold trim;
- burgundy/red scarf, tabard and cape;
- strong horned-helmet silhouette;
- broad shoulders and compact heroic proportions;
- large broad sword;
- visible material separation between cloth, steel and bronze;
- readable silhouette at mobile size.

The current detailed 17-bone hero rig remains the gameplay basis. The art pass may change scale, pose presentation, materials and model detail while preserving collision and combat behavior.

### Enemies

- Same overall visual family as the hero, but clearly coded as opposing guards.
- Primary enemy coding: blue cloth / shield accents, steel and gold trim.
- First priority variants: sword guard, shield guard and archer.
- Each role needs a distinct silhouette, not merely a tint swap.
- The existing detailed blue guard is retained as the current functional baseline.

### Castle kit

Primary architectural language:
- warm pale limestone;
- thick block courses;
- recessed mortar joints;
- bevelled / chipped edges;
- darker base courses;
- bronze/gold accent pieces used sparingly;
- red-and-gold banners;
- crenellated walls, square pillars, towers, gate and stairs;
- props: crates, barrels and torches.

The current uniform rectangular foreground wall is not considered final. The front-facing gameplay wall must read as real masonry, not as a flat repeated tile strip.

### Vegetation

- Tall narrow cypress-style trees for strong vertical rhythm.
- Dense shrubs with irregular silhouettes.
- Small flowers / red accents around stone and wall bases.
- Vines or ivy may be used on background walls.
- Avoid simple stacked spheres/cones in the final presentation.

### Lighting

- Bright warm daylight / late-afternoon feel.
- Warm sun on limestone and bronze.
- Cooler indirect fill so dark armor remains readable.
- Stronger contact and cast shadows near gameplay geometry.
- Moderate atmospheric separation for distant scenery.
- Avoid making the unshaded background substantially brighter than the 3D foreground.

### HUD

The current mobile layout is broadly correct:
- health top-left;
- stage/objective below it;
- navigation top-right;
- joystick lower-left;
- jump/block/attack lower-right.

Continue improving legibility, spacing, safe-area behavior and consistency with the medieval gold/dark UI style without stealing attention from gameplay.

## Current visual gap observed on the phone screenshot

1. **Foreground/background mismatch** — the detailed painted castle backdrop and the simpler real-time foreground do not yet feel like one scene.
2. **Gameplay wall is too flat and repetitive** — large uniform blocks and clean joints read as placeholder geometry.
3. **Props are still prototype-like** — tree, bush, banner, crate and barrel need richer silhouettes, materials and scale relationships.
4. **Hero reads too small / detached from the ground** — visual scale, contact shadow and local lighting need tuning.
5. **Scene lacks a strong middle-distance anchor** — the target has gates, towers, banners, braziers and enemy staging that produce a “hero scene”.
6. **Depth is underdeveloped** — the target has clear foreground, gameplay plane, middle castle structures and distant architecture.
7. **Lighting integration is incomplete** — the foreground requires stronger warm key light and more convincing contact with the terrain.

## Implementation order

### Pass A — visual foundation
- [ ] Replace the flat-looking sample masonry with deeper, bevelled, varied limestone modules.
- [ ] Add a dedicated top cap/cornice profile with less repetition.
- [ ] Improve walkway stones and edge breakup while preserving exact collision height.
- [ ] Tune hero side-view scale and foot contact without changing the gameplay capsule.
- [ ] Rebalance warm key light vs cool fill so armor and limestone match the backdrop.
- [ ] Enable/retain practical mobile-safe cast/contact shadows where they have the highest visual value.

### Pass B — middle-distance scene
- [ ] Place a substantial castle wall/gate/tower composition behind the first 25 m.
- [ ] Add pillars / crenellations and red banners to break the horizontal wall line.
- [ ] Add at least one torch/brazier light accent.
- [ ] Use cypress trees and shrubs as layered framing, not simple evenly spaced placeholders.
- [ ] Keep all decoration outside gameplay collision and sight lines.

### Pass C — props
- [ ] Upgrade stage-1 crate.
- [ ] Upgrade stage-1 barrel.
- [ ] Upgrade banner geometry/materials.
- [ ] Replace simple garden trees / bushes with reference-direction versions.
- [ ] Add small flower, ivy and stone-cluster accents.

### Pass D — combat scene readability
- [ ] Present the first guard as a clear blue/gold opponent.
- [ ] Add shield-guard presentation.
- [ ] Add archer presentation for later encounters.
- [ ] Verify enemy/hero silhouettes are readable against both bright stone and vegetation.
- [ ] Ensure attack windups remain clear after art changes.

### Pass E — depth and polish
- [ ] Add middle and far scenic layers with controlled parallax or depth placement.
- [ ] Reduce visible repetition in long background sections.
- [ ] Match saturation, value and contrast between backdrop and 3D objects.
- [ ] Add selective edge wear, roughness variation and material response.
- [ ] Review the full stage at representative checkpoints, not only the starting 25 m.

### Pass F — mobile verification
- [ ] Run Godot headless/import and existing smoke suites.
- [ ] Build Android APK with Mobile renderer.
- [ ] Capture first-stage screenshots from CI.
- [ ] Test Vulkan/Mobile appearance on phone.
- [ ] Check FPS, thermals and input responsiveness.
- [ ] Compare phone screenshots side-by-side with `gameplay_target.jpg`.
- [ ] Only after the side-view target is accepted should the other stages or 3D view receive equivalent art work.

## First checkpoint for this branch

The immediate checkpoint is a **single convincing opening courtyard scene**, not all ten stages.

It should contain:
- hero at reference-appropriate scale;
- one detailed enemy;
- improved limestone gameplay wall and paving;
- castle wall/gate/tower middle-distance anchor;
- red/gold banners;
- upgraded crate and barrel;
- cypress trees / shrubs;
- at least one warm fire/torch accent;
- coherent warm daylight and readable shadows;
- unchanged gameplay collision, camera behavior and mobile controls.

## Acceptance criteria for the checkpoint

The pass is considered ready for phone review when:

- The foreground no longer looks like flat placeholder blocks against a finished backdrop.
- The hero and enemy are clearly readable at normal phone size.
- Feet visually contact the ground; no obvious floating impression.
- At least three distinct depth layers are visible.
- The route, hazards and controls remain readable.
- No new decorative mesh blocks the gameplay corridor.
- Existing first-stage traversal and side-view smoke tests still pass.
- CI produces an installable APK and screenshots for comparison.

## Development discipline

- Work remains on an art branch until phone review.
- Every substantial visual change must be committed with a descriptive message.
- Keep editable Blender sources beside exported runtime assets.
- Do not replace source references with generated approximations.
- Do not claim reference-level parity solely from code presence; use real rendered screenshots and phone testing.
- Preserve the existing 240 m route, gaps, water ditch, checkpoints, enemy logic and mobile input unless a separate gameplay change is explicitly approved.
