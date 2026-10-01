# Change to Unreal Engine Mobile

> Migration plan for rebuilding Reverse Supermario / Reverse Platformer as an Unreal Engine mobile game.
>
> **Target:** Unreal Engine 5.8, Android first, full 3D world with **two gameplay views initially**: Side View and Third Person.
>
> **Rule:** The ten supplied mockups are the visual specification. The first milestone is not to recreate the old Godot implementation 1:1; it is to build a reusable Unreal architecture that can produce all ten long stages with three difficulty profiles and reference-near visual quality.

The 10 mockups support a much better architecture than writing ten unrelated level scripts. The project should use:

**1 common C++ stage system + 10 stage definitions + reusable segments + 3 difficulty profiles.**

The mockups have strong individual visual identities while sharing the same gameplay language and many reusable building blocks.

---

## 1. Do not write ten independent C++ level scripts

Avoid this:

```text
Level1Generator.cpp
Level2Generator.cpp
Level3Generator.cpp
...
Level10Generator.cpp
```

Use a shared system instead:

```text
AStageGenerator
 ├─ UStageDefinition
 ├─ UBiomeDefinition
 ├─ UDifficultyProfile
 ├─ UStageSegmentDefinition
 ├─ UEncounterDirector
 └─ UCameraModeController
```

Each stage is data/configuration. The generator is common code.

---

## 2. The ten stages become separate stage definitions

Planned definitions:

```text
DA_Stage01_Courtyard
DA_Stage02_RoyalGardens
DA_Stage03_EagleCliff
DA_Stage04_FrozenBastion
DA_Stage05_Forge
DA_Stage06_WindmillValley
DA_Stage07_Catacombs
DA_Stage08_ShadowCanyon
DA_Stage09_BlackForest
DA_Stage10_CrownCitadel
```

Each definition controls:

```text
Biome
Stage length
Lighting
Sky
Fog
Music
Wall assets
Floor assets
Vegetation
Decorative assets
Bridges
Gates
Towers
Enemy pool
Hazard pool
Checkpoint frequency
Segment selection weights
Mini-boss / end section
```

The same C++ generator can therefore build ten visually different worlds.

---

## 3. Use hybrid generation, not unrestricted random generation

The game should be **procedural + hand-authored**.

The generator should assemble a library of carefully designed reusable segments, for example:

```text
SEG_Start
SEG_Combat_Small
SEG_Combat_Large
SEG_Bridge
SEG_Gap
SEG_Stairs
SEG_Hazard
SEG_ArcherAmbush
SEG_Vista
SEG_Checkpoint
SEG_Tower
SEG_Gate
SEG_MiniBoss
SEG_End
```

Then create biome variants:

```text
SEG_Bridge_Garden
SEG_Bridge_Cliff
SEG_Bridge_Ice
SEG_Bridge_Forge
SEG_Bridge_Village
SEG_Bridge_Catacomb
```

The gameplay grammar can repeat while the art, hazards, enemy composition and decoration change.

This is the desired behavior: **recognizable repeated elements inside a stage, with enough variation that repetition does not look copied.**

---

## 4. Make every stage substantially longer

The old first stage is roughly 240 m. The Unreal rebuild should begin with longer stages.

Initial targets:

| Stage | Target length |
| --- | ---: |
| 1. Várudvar – A Belső Kapu | 700–800 m |
| 2. A Királyi Kertek – Az Elveszett Ösvény | 750–850 m |
| 3. Sas-szirt – A Mélység Felett | 800–900 m |
| 4. Dermedt Bástya – A Jégkapu | 800–900 m |
| 5. Vaskohó – A Tűz Negyede | 850–950 m |
| 6. Szélmalom-völgy – Az Ostrom Előtt | 850–950 m |
| 7. Az Elfeledett Katakombák – A Holtak Útja | 900–1000 m |
| 8. Árnyékszurdok – A Törött Híd | 900–1050 m |
| 9. Feketeerdő Erődje – Az Utolsó Őrség | 950–1100 m |
| 10. A Korona Citadellája – A Végső Ostrom | 1100–1300 m |

The meter value is a design target, not a rigid requirement. **Play time, pacing and segment variety matter more than the exact distance.**

A typical 800 m stage can contain roughly 15–20 major gameplay segments.

---

## 5. Example Stage 1 structure

### Várudvar – A Belső Kapu

```text
START
 ↓
Castle wall
 ↓
Small combat
 ↓
Fountain / garden
 ↓
Archer encounter
 ↓
Bridge
 ↓
Checkpoint
 ↓
Inner courtyard
 ↓
Watch tower
 ↓
Hazard section
 ↓
Large combat
 ↓
Stepped castle wall
 ↓
Checkpoint
 ↓
Gate approach
 ↓
Mini-boss / elite guards
 ↓
Inner gate
```

There should be multiple variants of common pieces.

Example:

- 3 castle-wall segments
- 4 courtyard arrangements
- 3 bridge variants
- several enemy-placement patterns
- several decoration seeds

Replaying a stage therefore does not have to reproduce every section in exactly the same arrangement.

---

## 6. Three difficulty levels must not become thirty maps

Do **not** build:

**10 stages × 3 difficulties = 30 maps**

Build:

**10 stage definitions + 3 difficulty profiles**

### Easy

- fewer enemies;
- fewer archers;
- lower incoming damage;
- more checkpoints;
- slower hazards;
- more health/healing opportunities.

### Normal

The baseline intended experience.

### Hard

- more enemies;
- elite variants;
- combined encounters;
- faster hazards;
- more damage;
- fewer healing opportunities;
- optional dangerous platform/hazard variants become active.

The visual world stays recognizably the same. Difficulty changes gameplay composition.

---

## 7. Repeating environment pieces should use Unreal instancing

Walls, pillars, crates, barrels, fences, stones, vegetation and similar repeated objects should use Unreal instancing wherever appropriate.

The core castle kit may be built from pieces such as:

```text
Stone_A
Stone_B
Stone_C
Stone_D
Corner_A
Pillar_A
Battlement_A
Battlement_B
Arch_A
Arch_B
```

These can build hundreds of meters of architecture without making the repetition obvious.

The runtime generator should favor **Instanced Static Mesh / Hierarchical Instanced Static Mesh** components for dense repeated decoration.

---

## 8. Reusable authored chunks should use Level Instances / Packed Level Actors

A detailed section such as:

**Garden Fountain Courtyard**

can be authored once and reused with:

- different rotations;
- different vegetation;
- different prop sets;
- different encounter placement;
- different lighting accents.

The project should use reusable authored chunks for important hero compositions, while lighter decoration is generated around them.

---

## 9. The ten mockups become the biome bible

The mockups are not generic inspiration. They define the identity of each stage.

### 1. Várudvar – A Belső Kapu

- warm pale limestone;
- red/gold banners;
- cypress trees;
- statues;
- fountains;
- braziers;
- castle gate and towers.

### 2. A Királyi Kertek – Az Elveszett Ösvény

- hedges;
- roses;
- pavilions;
- ponds;
- small stone bridges;
- statues;
- flower-covered arches;
- bright palace gardens.

### 3. Sas-szirt – A Mélység Felett

- cliff faces;
- waterfalls;
- rope/suspension bridges;
- cranes;
- mountain fortress;
- clouds and extreme depth;
- strong vertical composition.

### 4. Dermedt Bástya – A Jégkapu

- snow;
- ice;
- icicles;
- frozen bridges;
- blue heraldry;
- frozen waterfalls;
- ice gate;
- cold blue lighting with warm fire accents.

### 5. Vaskohó – A Tűz Negyede

- metal platforms;
- chains;
- furnaces;
- molten metal;
- lifting machinery;
- industrial castle structures;
- strong orange/red emission against dark metal.

### 6. Szélmalom-völgy – Az Ostrom Előtt

- timber-frame houses;
- wheat fields;
- windmills;
- wagons;
- fences;
- village bridges;
- approaching siege visible in the distance.

### 7. Az Elfeledett Katakombák – A Holtak Útja

- crypts;
- bones;
- candles;
- chains;
- suspended cages;
- tomb niches;
- dark stone;
- skeleton enemies;
- warm candle/fire light inside deep blue/black ambience.

### 8. Árnyékszurdok – A Törött Híd

- cliff walls;
- ruined bridges;
- chains;
- fog;
- guard towers;
- broken traversal;
- large depth drops;
- isolated fire light.

### 9. Feketeerdő Erődje – Az Utolsó Őrség

- dense pine forest;
- mossy ruins;
- wooden watch towers;
- palisades;
- fog;
- darker fortress stone;
- red/black enemy heraldry.

### 10. A Korona Citadellája – A Végső Ostrom

- monumental pale citadel;
- siege machines;
- giant bridges;
- giant statues;
- banners and crowds;
- waterfalls;
- layered fortress approach;
- final-scale battle composition.

---

## 10. Build only two camera/gameplay views first

The Unreal world is always true 3D. Initially only two gameplay modes are required.

### Side View

Primary gameplay mode:

- player constrained to the gameplay plane;
- side-facing camera;
- platformer movement;
- combat readability prioritized;
- mockups are composed primarily for this view.

### Third Person

Secondary mode:

- perspective camera;
- freer character movement;
- same world, same stage and same actors;
- no duplicated level.

Architecture:

```text
URPCameraModeComponent

SideView
ThirdPerson
```

A level is never duplicated just because the camera mode changes.

---

## 11. What the C++ stage generator should receive

Do not give the system a vague command such as:

> Generate a beautiful castle.

Use explicit data:

```text
Stage = RoyalGardens
Length = 850m
Seed = 12411

Required:
1 Start
3 Vista
4 Checkpoint
8 Combat
3 Bridge
2 Hazard
1 MiniBoss
1 Finish

Allowed modules:
GardenWall
Hedge
RoseArch
Gazebo
StoneBridge
Pond
Fountain
Statue
Cypress
RoyalBanner
```

The generator builds the gameplay skeleton.

The environment system then fills suitable areas with:

- grass;
- flowers;
- trees;
- rocks;
- vines;
- small debris;
- decorative props;
- repeated architectural modules.

This gives predictable gameplay while still producing visual richness.

---

## 12. Stage 1 is the first Unreal vertical slice

Do not attempt to polish all ten stages simultaneously.

Build **Stage 1 Vertical Slice** first, but build the architecture for all ten from day one.

Target Stage 1 length:

**approximately 700–800 m**

Suggested structure:

```text
Start
→ Courtyard
→ Wall
→ Combat
→ Fountain
→ Bridge
→ Tower
→ Large courtyard
→ Inner gate
```

The Unreal architecture is accepted when Stage 1 proves:

- Side View;
- Third Person View;
- modular stage generation;
- three difficulty profiles;
- mobile controls;
- enemy encounters;
- checkpoints;
- hazards;
- long-stage streaming;
- reusable environment pieces;
- acceptable Android performance;
- visual direction close to the supplied mockup.

Only then should the same architecture be filled out for Stages 2–10.

---

## 13. Mobile is a first-class target, not a late optimization pass

The mockup density must not be implemented with desktop-only assumptions.

The project is Android-first.

Initial quality concept:

```text
Mobile Medium
Mobile High
Mobile Ultra
```

Every major art/system milestone must be tested on a real Android phone.

Track:

- frame rate;
- frame time;
- thermal behavior;
- memory;
- texture memory;
- draw calls;
- triangle counts;
- shader complexity;
- loading/streaming hitches;
- input latency.

Current Unreal Android documentation requires a modern Android toolchain and Google Play target SDK 35. UE 5.7+ supports the required target; this migration targets UE 5.8.

Official references:

- https://dev.epicgames.com/documentation/unreal-engine/android-development-requirements-for-unreal-engine
- https://dev.epicgames.com/documentation/unreal-engine/android-quick-start
- https://dev.epicgames.com/documentation/unreal-engine/rendering-features-reference

---

## 14. Core architectural rule

**Do not write ten independent stage scripts.**

Write one stage-building framework.

The ten mockups define ten biome/stage configurations.

Improving the common generator should improve all ten stages at once, while each stage remains visually distinct through its stage definition, palette, segment pool, encounter pool and environment assets.

---

## 15. Initial implementation order

### Phase 0 — migration foundation

- Unreal 5.8 C++ project;
- Android-first configuration;
- Side View + Third Person camera architecture;
- common stage/difficulty data types;
- ten built-in stage specs;
- deterministic seeded generation;
- segment grammar;
- instancing-friendly decoration system;
- stage length targets;
- three difficulty profiles.

### Phase 1 — Stage 1 vertical slice

- 700–800 m layout;
- courtyard segment library;
- combat encounters;
- checkpoints;
- hazards;
- castle wall/gate/tower modules;
- fountains/statues/banners/cypress/flowers;
- hero + guard + shield guard + archer;
- mobile HUD;
- Android build and profiling.

### Phase 2 — stages 2–5

- Royal Gardens;
- Eagle Cliff;
- Frozen Bastion;
- Forge.

### Phase 3 — stages 6–10

- Windmill Valley;
- Catacombs;
- Shadow Canyon;
- Black Forest Fortress;
- Crown Citadel.

### Phase 4 — polish

- variation passes;
- mobile LOD/HLOD/instancing;
- VFX;
- audio;
- animation polish;
- difficulty tuning;
- loading/streaming;
- device quality profiles.

---

## Decision

The Unreal migration is approved to begin from the successful Godot 0.1.9 side-view checkpoint.

The old Godot implementation remains in repository history as reference and fallback. The new Unreal implementation lives on a dedicated migration branch until the Unreal Stage 1 vertical slice is demonstrably stronger than the Godot version on a real Android device.
