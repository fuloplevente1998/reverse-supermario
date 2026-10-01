# Képalapú mészkő anyagpróba – 0.2.4

Eszköz: beépített imagegen képgenerálás, nem CLI és nem Meshy vagy Adobe.
Referencia: `art/references/stage-mockups-2026-10-01/stage01-varudvar.png`.
Kimenet: `assets/materials/ai/courtyard_limestone_v1.png`, 1254×1254 PNG.
Anyag: `assets/materials/ai/courtyard_limestone_v1.tres`.

Csak a -15 m-nél kezdődő első generált szegmens kapja: az előtéri falazat
és párkány, valamint a díszletek MI_RockTrim kőfelületei (pillérek, fedkövek).
A burkolat, fa, növényzet és további szegmensek eredeti anyagai megmaradnak.
A mesh anyagváltozata másolat; a vendor atlaszokhoz és UV-khoz nem nyúlunk.
Világtérbeli triplanar leképezés: 0,65 ismétlés/m; roughness 0,88; metallic 0.
Az albedo szorzó 0,70 a jelenlegi meleg jelenetfény túlexponálásának csökkentésére.
Az első összehasonlítás alapján a falmező MI_UnevenBrick anyaga megmarad:
a sima textúra eltüntetné az atlaszban lévő fugákat és blokkhatárokat.
Nincs új normal/height/roughness térkép: ez albedo-próba, nem teljes PBR csomag.

A prompt ismételhető felületet kér. A generálás önmagában nem bizonyít
pixelpontos varratmentességet. Játékbeli kamera és ismétlődő modulok mellett
ellenőrizzük; a biome anyagbank kiépítése előtt külön UV/varrat vizsgálat indokolt.
Az Android/Vulkan készülékes kép és teljesítmény még ellenőrzésre vár.

Azonos kamerájú összehasonlítás: `tests/material_pilot_preview.gd`;
képek `previews/material_pilot_original.png` és `previews/material_pilot_ai.png`.
A CI ezeket a kiadáshoz is csomagolja. A courtyard_assets teszt ellenőrzi,
hogy a pilot pontosan egy szegmensre korlátozódik mindhárom nehézségen.

## Végleges generálási prompt

```text
Create a game-ready seamless square albedo texture by extracting ONLY the warm pale limestone material appearance from the supplied courtyard game mockup. The output must be a flat orthographic diffuse material swatch filling the entire image, evenly lit, tileable across all four edges. Stylized believable medieval limestone: creamy beige and light honey tones, restrained fine mineral pores, subtle chisel wear and tiny chipped flecks. Broad calm color fields suitable for a mobile game seen at medium distance. NO masonry joints, NO brick outlines: the existing 3D stone blocks provide their own geometry and joints. NO objects, buildings, people, vegetation, text, UI, borders, perspective, directional lighting, baked shadows, ambient occlusion, specular highlights or vignette. Preserve the restrained warm stone palette of the reference. This is an albedo texture, not a rendered scene or a normal map. 1024x1024 square.
```

A kért 1024×1024 méret helyett az eszköz 1254×1254 képet adott; az eredeti
kimenetet használjuk. Átlátszó háttér kikapcsolva. Egy generálás készült.
