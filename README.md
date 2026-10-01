# Reverse Platformer (working title)

Android action-platformer prototype built with Godot 4 Mobile renderer. Current focus: the generated 700–800 m courtyard level, with three difficulty profiles, safe segment ordering, real jump gaps and checkpoints. The other nine stages retain their earlier prototype layouts; their distinct mockup-based environments and segment kits are future work.

**Godot generator rebuild:** [docs/GODOT_GENERATOR_REBUILD.md](docs/GODOT_GENERATOR_REBUILD.md). **0.1.8 art sample:** [docs/SIDE_SAMPLE_0.1.8.md](docs/SIDE_SAMPLE_0.1.8.md). **0.1.9 side-view reference roadmap:** [docs/SIDE_VIEW_REFERENCE_ROADMAP_2026-10-01.md](docs/SIDE_VIEW_REFERENCE_ROADMAP_2026-10-01.md). **Current design and continuation guide:** [docs/PROJECT_HANDOFF.md](docs/PROJECT_HANDOFF.md). **0.1.7 side-view notes:** [art/SIDE_VIEW_0.1.7.md](art/SIDE_VIEW_0.1.7.md). **Asset inventory:** [docs/ASSET_MANIFEST.md](docs/ASSET_MANIFEST.md).

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

The game opens on a start screen with Continue/Start, level selection and difficulty. The in-game menu and end screen return to the start screen. All ten stages have invisible solid outer boundaries without railings, while their intentional internal jump gaps remain. The scene uses brighter daylight and lighter ground materials.

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

All ten stages support Easy/Normal/Hard. A shared difficulty profile controls player health, enemy/elite health and damage, enemy movement and hazard damage. The generated courtyard additionally uses profile-driven encounter density, trap timing, one-time checkpoint healing, jump distances and longitudinal bridge landing lengths. The earlier stages retain their legacy layout/count/timing rules until their own mockup-specific rebuilds. Five enemy types: guard, quick scout, frontal-armored brute, ranged archer and captain. Attacks have visible windup markers; shots collide with cover. Brutes take full damage from behind or while preparing an attack. The stage menu pauses gameplay.

CI checks 30 stage/difficulty combinations and captures desktop compatibility-renderer previews. Android uses Mobile renderer; device frame rate, touch feel and Vulkan appearance still need phone testing.


### Grafikai tesztág: 0.1.5

Az `art/blender-knight-study` ág az új, textúrázott és köpenyes lovagot a `feature/0.1.3-stage1-models` ág környezetével és ellenfélmodelljeivel egyesíti. Javított kardfogás és csapásív; részletesebb várudvar, házak, fák, falak, sziklák, kovácsműhely és malom. A szerkeszthető Blender-források és a modellgenerátorok is bekerültek. Részletek és korlátok: [art/WORLD_ART.md](art/WORLD_ART.md).
