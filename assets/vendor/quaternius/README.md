# Quaternius – selected first-100m assets

These are selected models from the **free Standard** editions, downloaded on
2026-10-01 from the author's itch.io pages:

- [Medieval Village MegaKit](https://quaternius.itch.io/medieval-village-megakit)
- [Fantasy Props MegaKit](https://quaternius.itch.io/fantasy-props-megakit)

Both ZIPs explicitly include **CC0 1.0 Universal** in `License_Standard.txt`.
Their unmodified, pack-specific license texts are retained as
`village_LICENSE.txt` and `props_LICENSE.txt`. The archive SHA-256 hashes,
original paths and model dimensions are recorded in `manifest.json`.

The general Quaternius website license has a newer QAL text. This selection
uses the explicit CC0 license shipped inside these two Standard downloads.
No Pro/Source edition or paid content is included.

## Adaptation

`tools/import_quaternius_first100.py` reproduces the selection from the two
original ZIPs. It retains mesh detail/UVs, normalizes bounds for runtime fitting,
and shares external textures across models. Color maps are limited to 1024px;
normal and roughness maps to 512px. Stone is tinted warm ivory and ivy dark green.
The original archive and all unused pack models are omitted.

The game uses simple colliders around crates, benches and stones, and cylinders
around barrels. Scenery behind the playable corridor has no collision. The
normalized origin is at the bottom centre, except stone and paving at the centre.

Models by **Quaternius**. CC0 does not require attribution; this project keeps it
for provenance and to credit the author.
