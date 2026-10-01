# Side-view visual references — 2026-10-01

These notes preserve the exact role of the reference images supplied in the design chat.

> The binary chat attachments are not automatically transferable through the GitHub connector used for this pass. Do **not** replace them with generated approximations. When the original files are uploaded to the repository, keep the filenames below.

| Planned filename | Meaning |
| --- | --- |
| `hero_knight_sheet.jpg` | Hero character sheet: dark graphite plate armor, aged bronze/gold trim, burgundy scarf/tabard/cape, horned helmet, broad sword; front, side, back and 3/4 views plus helmet/clasp details. |
| `castle_environment_kit.jpg` | Castle kit sheet: warm limestone floor tiles, low/crenellated walls, square pillar, gate, tower, stair/obstacle block, crate, barrel, torch, red/gold banner, cypress tree, shrubs and statue accents. |
| `enemy_weapon_sheet.jpg` | Enemy/weapon sheet: sword guard, shield guard and archer, plus broad sword, red/gold shield, bow and arrow. |
| `gameplay_target.jpg` | Primary visual target: bright side-view castle courtyard, layered pale-stone fortifications, cypress trees and flowers, red/gold banners, warm braziers, dark/red hero, blue/gold enemies, mobile HUD. |
| `stage1_phone_before_pass.jpg` | Actual phone screenshot before the 0.1.9 reference pass. |

## Phone screenshot observations

The 2026-10-01 phone screenshot shows:
- correct side-view gameplay direction;
- the detailed horned hero already present;
- a bright castle panorama in the far background;
- foreground gameplay wall made from large pale rectangular blocks;
- a free-standing red banner;
- simple green trees/bushes;
- crate and barrel props;
- joystick lower-left and jump/block/attack lower-right;
- health/objective top-left and navigation top-right.

The main visual mismatch is not the camera concept. It is **integration**:
- the far background looks more finished than the real-time foreground;
- the foreground wall is too flat/repetitive;
- props and vegetation still read as prototype art;
- the hero needs stronger scale/contact/readability;
- there is not yet a convincing middle-distance gate/tower/wall layer;
- warm directional lighting and shadows need to connect all layers.

## Current rule

For now, development targets only Stage 1 side view. The 3D camera view and art replacement for Stages 2–10 are postponed until this first side-view courtyard is accepted on phone.

Canonical implementation plan: [../../../docs/SIDE_VIEW_REFERENCE_ROADMAP_2026-10-01.md](../../../docs/SIDE_VIEW_REFERENCE_ROADMAP_2026-10-01.md).
