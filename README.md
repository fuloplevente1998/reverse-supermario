# Reverse Platformer (working title)

Android third-person action-platformer prototype built with Godot 4 Mobile renderer. Two playable levels: castle courtyard and the guard's broken bridge.

See `FORDITOTT_SUPERMARIO_PROJECT.md` for the complete Hungarian design summary.

## Prototype controls

Desktop:
- WASD: move
- Space: jump
- J: attack
- K: block
- C: switch between behind-the-character and side camera

Android:
- on-screen directional/action buttons
- NÉZETVÁLTÁS: switch camera; in side view, right moves toward the gate

Reaching the first gate unlocks level two and saves progress locally. The second level adds moving bridges, spike traps, a checkpoint, and a separate finish. Falling into a gap costs health and returns the player to the latest checkpoint. Use the next-level button at the first gate or the stage button after unlocking it.

## Art pipeline

The current first level has original procedural 3D armor, animated cape, paved courtyard, trees and castle gate. It runs as a native Godot game. Detailed models and animations can be authored in Blender and exported as glTF 2.0 (.glb) into Godot. Keep a source .blend file and exported .glb together, use small shared materials and texture atlases, and profile the result on Android hardware.

## Engine

Godot 4.7.2 stable, Mobile renderer.

## IP note

“Fordított SuperMario” is a concept nickname only. This repository contains no Nintendo assets, characters, level data, audio or code. The production game should use fully original names and assets.
