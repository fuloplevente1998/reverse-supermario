# 0.1.8 – első oldalnézeti pálya: 25 méteres grafikai minta

## Határ
Ág: art/blender-knight-study. Alap: 362f6545be0153a780e78519ea47bb10ca78dbf8.
A main ág nem változik. A mintaszakasz Z=-15..10, az első útvonal teljes hossza 240 méter.
A terep, négy rés, vizes árok, három ellenőrzőpont és ütközések megmaradnak.
A további pályák modelljei és a 3D-környezet nem kapnak új grafikai készletet.

## Ellenőrzött kiindulás
Nincs AGENTS.md a repo rekurzív fájlfájában.
A README, PROJECT_HANDOFF, ASSET_MANIFEST, SIDE_VIEW_0.1.7 és Blender-generátorok megvizsgálva.
A 0.1.7 sikeres CI tényleges képein a problémák reprodukálhatók:
- A KnightRuntime részletes, animált modell betöltődik; profilból nagyon keskeny.
- Az enemy_guard GLB valóban betöltődik, eredeti anyagai kékesek, de egyszerű doboz/gömb geometriájúak.
- A főhős és talaj fényerőben elmarad az unshaded háttértől.
- A terepháló fordított háromszög-sorrendje befelé mutató normálokat generált; a Godot SurfaceTool/Plane forrása alapján javítva. A teszt közvetlenül ellenőrzi a normálok irányát.
- A talajoldal ugyanazt a triplanáris térkőtextúrát használja, mint a burkolat.
- A ProgressBar a témára hagyatkozik; saját piros fill és keret nincs.
- A projektben nincs expand stretch aspect: a mobilkép oldalsávjával összhangban a keep alapérték szerepel.
  Az Androidon látható oldalsáv megszűnését készüléken is ellenőrizni kell.

## Megvalósítás
- A meglévő lovag GLB, 17 csont, kard, pajzs és öt mozgás megmarad.
- 0.55 radián vizuális fordítás a kamera felé; a fizikai támadásirány külön, változatlan.
- Az első pálya oldalnézeti függőleges képtartománya 8.8 m, a talaj továbbra is az alsó negyedben.
- Külön árnyékmentes kamerafelőli derítőfény és erősebb indirekt fény oldalnézetben.
- A részletes őr ugyanazt a szerkeszthető lovagriget használja, kék/arany shaderrel és saját AnimationPlayerrel.
  Ez megosztott geometria, nem újonnan kézzel modellezett ellenség. A korábbi többi ellenféltípus megmarad.
- A 25 m-es minta tagolt, eltolt fugájú mészkő homlokfalat, felső szegélyt és térkőlapokat kap.
  MultiMesh kötegek, közös anyagok; a szegély és burkolat legfeljebb 0.01 m-rel tér el a meglévő járófelülettől.
- Meglévő Blender-hordók, ládák, zászlók, fenyők, kis virágágyások a játéksík mögött.
- Saját SVG mészkőtextúra és ugrás/pajzs/kard ikonok.
- Piros HP, sötét háttér és aranykeret; körgombok.
- Expand képarány, safe-area alapú HUD; minden akciógomb saját érintésazonosítót tart.
  Felengedés az érintési felületen kívül és fókuszvesztéskor is működik.
- Android versionCode=18; csomagazonosító és keystore cache folyamat megőrizve.

## Források és folytatás
Új grafikai forrás: scripts/side_sample_art.gd, assets/terrain/sample_limestone.svg,
assets/ui/*.svg, assets/materials/side_guard.gdshader.
Közös szerkeszthető karakter: art/source/knight_study.blend.
Kellékek: art/source/world/stage1_*.blend, pine_tree.blend.
Nem szükséges új glTF-export a közös rig vagy Blender-forrás lecserélése nélkül.
A generátor a tényleges játékba épít, nem egy külön látványképet készít.

A mostani csatolmányok 1838/1839/1840/1841 képpontjai a beszélgetésben látszanak,
de a megadott scratch fájlok nem érhetők el az eszközkészlettel.
A korábbi 1830.png ismert fájlpéldányának megnyitása sem adott képpontokat.
Az eredeti referenciák byte-for-byte exportja ezért még hiányzik; helyüket nem töltjük ki kitalált képekkel.

## Tesztelés
A CI újra futtatja a knight_model_smoke, world_art_smoke, side_view_smoke,
first_course_smoke és stage_smoke teszteket.
Az új side_sample_smoke a beépített grafikát, blue guard riget, valódi játékostámadást és
legyőzést, 3 képarányt, biztonságos területet és többujjas bemenetet ellenőriz.
A side_sample_preview valódi Godot-jelenetet renderel, determinisztikus idle/run/attack/block pózokkal,
egy fizikai ugrással és széles kijelzővel. Ezek nem telefonképek.
Az eredmények a CI-hez és a kiadási commit SHA-jához tartoznak, nem pusztán a kód jelenlétéből következnek.

## Ismert hiányok
A 1830 elsődleges kompozíció vizuális ellenőrzése hozzáférés hiányában nem teljes.
Nincs kézzel festett, referencia-minőségű páncél, új ellenfél-sziluett vagy végleges harci koreográfia.
A köpeny csontanimáció, nem fizikai szövet. A referencia díszes kapuja és lépcsőkészlete nincs újraalkotva.
A mintán kívüli terep és az egyéb ellenféltípusok a korábbi grafikai készletet használják.
Valódi telefonon még: Mobile/Vulkan anyagok, safe area és oldalsáv, többujjas érintés,
kényelmes ugrás/harc, teljesítmény és hőterhelés. Mért mobil-FPS állítás nincs.
