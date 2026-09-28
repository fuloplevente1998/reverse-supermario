# Reverse Platformer (working title)

Android third-person action-platformer prototype built with Godot 4 Mobile renderer. Ten playable levels, three difficulty settings, touch joystick, and switchable cameras.

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

Each gate unlocks the next level and saves progress locally. The second level adds moving bridges, spike traps and a checkpoint. Levels 3–10 use one stage template and eight authored recipes with deterministic decoration, fixed jump distances and different colors, guard placements and hazards. Falling into a gap costs health and returns the player to the latest checkpoint. The PÁLYÁK menu shows unlocked levels and lets you choose KÖNNYŰ, NORMÁL or NEHÉZ; changing difficulty restarts the current level.

The Android preview uses package `com.fuloplevente.reverseplatformer.preview`, so it installs beside the earlier prototype. Its debug signing key is cached in GitHub Actions for subsequent test builds. The cache can expire; a production release must use a privately stored release signing key.

## Art pipeline

The current first level has original procedural 3D armor, animated cape, paved courtyard, trees and castle gate. It runs as a native Godot game. Detailed models and animations can be authored in Blender and exported as glTF 2.0 (.glb) into Godot. Keep a source .blend file and exported .glb together, use small shared materials and texture atlases, and profile the result on Android hardware.

## Engine

Godot 4.7.2 stable, Mobile renderer.

## IP note

“Fordított SuperMario” is a concept nickname only. This repository contains no Nintendo assets, characters, level data, audio or code. The production game should use fully original names and assets.
