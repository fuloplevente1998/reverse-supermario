# Reverse Platformer (working title)

Android third-person action-platformer prototype built with Godot 4 Mobile renderer. Ten playable levels, three difficulty settings, touch joystick, and switchable cameras. You play the attacking villain, breaking through the castle's defenders to reach the princess.

See `FORDITOTT_SUPERMARIO_PROJECT.md` for the complete Hungarian design summary.

## Prototype controls

Desktop:
- WASD: move
- Space: jump
- J: attack
- K: block
- C: switch between behind-the-character and side camera

Android:
- left virtual joystick around the lower two-thirds of the screen and jump/attack/block buttons
- NÉZETVÁLTÁS: switch camera; in side view, right moves toward the gate

The game opens on a start screen with Continue/Start, level selection and difficulty. The in-game menu and end screen return to the start screen. All ten stages have solid outer boundaries with visible low railings, while their intentional internal jump gaps remain. The scene uses brighter daylight and lighter ground materials.

Each gate unlocks the next level and saves progress locally. The final gate requires defeating the captain. Ten authored stage layouts introduce jump hurdles, moving bridges, timed spikes, fire jets, sweeping saws, ice patches and stair ridges. Falling into a gap costs health and returns the player to the latest checkpoint. The PÁLYÁK menu pauses gameplay and allows unlocked level selection; changing difficulty restarts the current level.

The Android preview uses package `com.fuloplevente.reverseplatformer.preview`, so it installs beside the earlier prototype. Its debug signing key is cached in GitHub Actions for subsequent test builds. The cache can expire; a production release must use a privately stored release signing key.

## Art pipeline

The current stages use original procedural 3D armor, animated cape, trees, pillars and castle gates. It runs as a native Godot game. Detailed models and animations can be authored in Blender and exported as glTF 2.0 (.glb) into Godot. Keep a source .blend file and exported .glb together, use small shared materials and texture atlases, and profile the result on Android hardware.

## Engine

Godot 4.7.2 stable, Mobile renderer.

## IP note

“Fordított SuperMario” is a concept nickname only. This repository contains no Nintendo assets, characters, level data, audio or code. The production game should use fully original names and assets.


## 0.0.7 — distinct stages and mobile controls

The joystick now uses explicit top-left anchors and a fixed 220×220 area. Its center is at 73% of screen height. Tests verify the actual control rectangle at three viewport sizes and release outside its touch area.

| Stage | Main challenge |
| --- | --- |
| 1 Várudvar | Staggered jump hurdles and introductory guards |
| 2 Törött híd | Moving bridges, barricades and a moving saw |
| 3 Tüskekert | Alternating hedge maze and timed spikes |
| 4 Jéggerinc | Low-friction ice patches, pillars and gaps |
| 5 Parázskohó | Alternating fire jets and cover |
| 6 Fűrészmalom | Three sweeping saws and moving bridges |
| 7 Őrtorony | Two stair ridges and ranged guards |
| 8 Hídlánc | Four moving bridge crossings |
| 9 Alkonyút | Mixed fire, saw, spike and wall obstacles |
| 10 Trónőrség | Arena cover and a captain required to finish |

All ten stages support Easy/Normal/Hard. Difficulty affects health, damage, enemy count, trap timing, bridge width and movement. Five enemy types: guard, quick scout, frontal-armored brute, ranged archer and captain. Attacks have visible windup markers; shots collide with cover. Brutes take full damage from behind or while preparing an attack. The stage menu pauses gameplay.

CI checks 30 stage/difficulty combinations and captures desktop compatibility-renderer previews. Android uses Mobile renderer; device frame rate, touch feel and Vulkan appearance still need phone testing.

## 0.0.8 — Blender villain and fortress gate (preview branch)

The player is the villain, not a rescuing hero. Fight through the castle's guards, scouts, armored knights and captains across ten levels to reach the princess. The familiar plumbers are an early fan-story idea only: this public repository uses original designs and does not contain their likeness, names as playable characters, or Nintendo game assets. A distributable game needs its own rival duo or a separate license.

**No local Blender installation is needed to test:** GitHub Actions installs Blender, runs `tools/blender/generate_art.py` in headless mode, creates `villain_knight.glb` and `fortress_gate.glb`, and includes them in the Android debug APK. Download the `blender-art-source-and-models` workflow artifact to get the generated editable `.blend` files and GLBs. The procedural visuals are retained as a fallback for local source checkouts without Blender.

The Blender model exports keep four stable node names (`Chest`, `LegLeft`, `LegRight`, `WeaponPivot`) so Godot's existing damage flash, walk cycle, attack and blocking motion still work. Stage one loads an original modular castle gate, while stage two through ten keep the existing art for this first graphics pass. `tests/art_smoke.gd` verifies both GLBs import and the stage instantiates them; it does not replace a real Android frame-rate and gameplay test.

To regenerate in Blender locally later: `blender --background --factory-startup --python tools/blender/generate_art.py -- --output assets/models --source build/blender`. CI generates the same files without requiring a developer PC.

### 0.0.8 visual upgrade: first-stage castle assault
The image mockup is cinematic target art rather than a promise of identical real-time mobile graphics. The headless Blender generator now builds a third GLB with a material-batched stone road, castle parapets, cypresses, banners, braziers and an off-lane fountain; the gateway adds tall towers and two original heraldic lion statues. The new props are visual only and do not interfere with established game collisions. All three GLBs and editable Blender sources are uploaded by GitHub Actions; test FPS and camera framing on the actual Android phone before merging.

## 0.0.9 preview — five distinct Blender defenders

The castle assault now has five original headless-Blender defenders: blue steel guard with tower shield, fast green scout with paired knives, heavily armored brute with war hammer, hooded archer with bow and quiver, and red/gold captain with greatsword and royal shield. Generated source `.blend` files and Android-ready `.glb` imports appear in the GitHub Actions art artifact. All retain `Chest`, `LegLeft`, `LegRight` and `WeaponPivot` nodes for runtime hit, walk and attack animations; procedural fallback visuals still work without Blender assets. The unchanged ten-level campaign still needs physical Android frame-rate and touch-playtesting before release.

## 0.1.0 — Rigged hero prototype (separate draft branch)

This follows the 0.0.9 Blender scenery and five enemy models. The main branch is intentionally unchanged until device QA. The main character is generated with tools/blender/rigged_villain.py in headless Blender 4.0:

- Original sculpt-inspired mesh components: lofted body armor and helmet, swept horns, curved gauntlets, molded pauldrons, a shaped thick cape and a separate, hand-attached broad sword.
- Exactly three PBR materials use a common 2048×2048 base-color and metallic/roughness texture atlas with explicit UV unwrapping.
- A skinned humanoid armature with Idle and Run animation clips; attack/block/jump/hurt controls remain while later skeletal clips are pending.
- villain.blend, villain.glb, atlas PNGs, front/side/back preview renders are uploaded as Actions artifacts; the game loads a copy as assets/models/villain_knight.glb.
- The Blender generator reimports the exported GLB to verify the rig and sword. Godot additionally tests Skeleton3D, Idle and Run, runtime binding and stage smoke tests.
- Large binary .blend models stay in CI artifacts; reproducible Python generation is version-controlled.

Mobile asset target below 20,000 triangles; exact count appears in build/blender/model_report.json. FPS and animation appearance require phone QA.

## 0.1.1 visual correction (independent draft branch)
The real on-device screenshot exposed a mismatch between the cinematic design target and the current prototype: uniform blue sky, flat light-colored paving, duplicated low-poly trees, dark hero silhouette and oversized top-right menu. This pass prioritizes the first-stage actual Godot frame instead of relying on Blender renders. It replaces rectangular white paving with 150 chamfered, irregular limestone stones, a warm mortar underlay and four original 512 px grain textures; removes procedural trees when Blender scenery exists; adds a shadow-free camera-side fill, an art-directed sky, smaller translucent menu buttons and a bottom-left anchored joystick. Gameplay collisions, route geometry, all ten stages and the three difficulties are retained. CI's image capture provides actual Godot screenshots, not marketing mockups. This is an intermediate correction, not a claim that the full fantasy art target has been reached.
