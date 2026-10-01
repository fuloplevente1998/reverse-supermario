# ReversePlatformerUE

Android-first Unreal Engine 5.8 rebuild.

## Current architecture

- one common C++ stage generator;
- ten built-in stage specifications;
- three difficulty profiles;
- Side View and Third Person camera modes;
- Data Asset extension points for stage definitions, segment definitions and biome palettes;
- reusable authored segment actors;
- deterministic seeded layouts;
- instancing-ready environment architecture.

The existing Godot project is intentionally retained outside this folder as a reference while the Unreal vertical slice is being built.

See [../../docs/CHANGE_TO_UNREAL_ENGINE_MOBILE.md](../../docs/CHANGE_TO_UNREAL_ENGINE_MOBILE.md).
