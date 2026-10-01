# 0.2.4 – teljes Várudvar a 100m-es minta alapján

A 0.2.3-ban létrehozott CC0 Quaternius assetkészletet a teljes első pályára
kiterjesztettük. A kit általános helye: `scripts/generation/courtyard_asset_kit.gd`.
A pad, láda, hordó, kőakadály, kapu, fal, borostyán, burkolat és zászló ugyanazt
a textúra- és modellkészletet használja a pálya elejétől a végéig.

A híd rövid, textúrázott fa korlátelemei a nyitott résekhez igazodnak. Az
őrtorony négy oldalból, kőpillérekből és pártázatból épül. Szökőkutas udvar,
pihenő, ellátmányos udvar, torony és végső kapu eltérő díszletet kap.
A statikus díszletek szegmensenként MultiMesh csoportokban szerepelnek, így
az útvonal hosszával nem az egyedi modellek száma szerint nő a rajzolási hívás.
A fizikai akadályok külön, látható modellhez illesztett ütközőkkel maradnak.

| Nehézség | Valódi akadálycsoport | Talajrések | Hossz |
| --- | --- | --- | --- |
| Easy | 22 | 3 | 744,3 m |
| Normal | 23 | 5 | 757,8 m |
| Hard | 20 | 2 | 703,7 m |

A későbbi recovery szegmensek elején **18 m szabad pihenő** marad. Ezt
legfeljebb egy alacsony padakadály követheti a szegmens végén. Az első 100 m
ígért íjászok utáni pihenője teljesen szabad. A checkpointok és a 38 m-es boss
felvezetés teljes hossza, valamint a végső kapu térsége szintén akadálymentes.
A boss arénájának első 8 métere szabad, utána két alacsony kőakadály van.
Az ellenségek kiindulóhelyétől legalább 4 m távolság marad az új akadályokig.

## Ellenőrzés

- `first_course_smoke.gd`: mindhárom teljes pálya bejárása a valós játékosfizikával.
- `courtyard_assets_smoke.gd`: assetkit minden szegmensben, ütközők és legalább
  öt akadálytípus, fizikai akadályok minden harmadban, recovery/boss szabad tér,
  statikus díszletek tényleges csoportosítása.
- `courtyard_coverage_smoke.gd`: talaj, burkolat, terep és collision egyezése,
  nyitott rések, késői díszletek és streaming.
- Meglévő első 100m, difficulty, 1920 seed, harc, HUD és touch ellenőrzések.
- Képek hét pályapontból, széles képarányban és a korábbi 100m mintából.

A nyitószakasz kőpillérei, fedkövei és előtéri kőelemei AI mészkő albedo-próbát
kaptak, a többi szakasz a CC0 anyagokat használja. Az eredeti vendor fájlok
változatlanok; részletek és reprodukciós prompt: [AI_MATERIAL_PILOT.md](AI_MATERIAL_PILOT.md).
Meshy/Adobe nem futott. A mockup összes egyedi szobra és részlete további art pass
része lehet; az Android Mobile/Vulkan megjelenést és FPS-t készüléken kell mérni.

A maradék kilenc pálya tervét a `BIOME_ASSET_REUSE.md` rögzíti.
