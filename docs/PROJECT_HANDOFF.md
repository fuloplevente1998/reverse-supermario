# Reverse Platformer – folytatási és tervezési leírás
Állapot: 0.1.8-art-sample, 2026-09-30. Aktív fejlesztési ág: `art/blender-knight-study`.

A legfrissebb grafikai mintaszakasz döntései, forrásai, tesztjei és korlátai: [SIDE_SAMPLE_0.1.8.md](SIDE_SAMPLE_0.1.8.md).\nA 2026-10-01-i, referencia-közeli oldalnézeti folytatás rögzített célja és lépéssora: [SIDE_VIEW_REFERENCE_ROADMAP_2026-10-01.md](SIDE_VIEW_REFERENCE_ROADMAP_2026-10-01.md).
Az alábbi 0.1.7 útvonal és történeti ellenőrzés megmarad; a legújabb eredményeket mindig a hozzá tartozó CI commit alapján kell olvasni.

## A felhasználó által rögzített irány
- Először kizárólag az 1. pálya oldalnézetes változatát kell kidolgozni.
- A klasszikus oldalra haladó platformjátékok mozgása és áttekinthetősége a cél, saját lovaggal, ellenfelekkel és várudvari grafikával.
- A korábbi pálya 3–5-szörös hosszúsága; az implementált döntés négyszeres, 60 helyett 240 méter.
- A talaj a kép alsó részén legyen, a járható útvonalat ne fedje el előtéri fa, ház vagy fal.
- A környezet nagy része statikus háttér. A tényleges út ne legyen végig sík: dombok, lejtők, völgyek, lyukak és vizes árok.
- Láthatatlan külső ütközési határok, kerítés nélkül.
- A 3D-s nézet és a további pályák teljes átdolgozása későbbi feladat.
- Minden forrás, háttér, Blender-forrás, terv és folytatási információ kerüljön GitHubra. A telefonra egyetlen telepíthető APK kell.

## Referenciák
A felhasználó két mockupot adott: `1830.png` és `1831.png`.
Az oldalnézeti referencia világos kővárat, vörös-arany zászlókat, növényzetet, a kép alsó részén futó jól olvasható játékteret és külön háttérdíszletet mutat. A másik a karakter mögötti 3D-s irány referenciája.
A két eredeti PNG nincs ebben a commitban: a megszakadt munkakörnyezet csatolmányai a folytatáskor nem voltak elérhetők. Ezt nem szabad kész exportként feltüntetni. Visszakerülésükkor a fájlok helye: `art/references/1830.png`, `art/references/1831.png`.
Az APK által használt új háttér viszont verziózott fájl: `assets/backgrounds/courtyard_side_panorama.jpg`; a prompt: [SIDE_VIEW_0.1.7.md](../art/SIDE_VIEW_0.1.7.md).

## Mi hol található?
| Terület | Forrás |
| --- | --- |
| Első oldalnézeti pálya, terepprofil, rések, víz, ellenőrzőpontok | `scripts/side_stage_one.gd` |
| Pályaválasztás és korábbi 2–10. pályák | `scripts/stage_generator.gd`, `scenes/` |
| Kamera, előretekintés, terepkövetés, rajzolási rétegek | `scripts/camera_rig.gd` |
| Mozgás, ugrás, harc és animáció | `scripts/player.gd` |
| Visszatérés, élet, pályateljesítés, UI | `scripts/game.gd` |
| Ellenfelek és csapdák | `scripts/enemy.gd`, `scripts/stage_hazard.gd` |
| Statikus háttér | `assets/backgrounds/` |
| Játékmodellek és textúrák | `assets/models/`, `assets/terrain/` |
| Szerkeszthető modellek | `art/source/`, `art/source/world/*.blend` |
| Generálás és udvaroptimalizálás | `tools/blender/`, `tools/verify_courtyard_runtime.py` |
| Korábbi karakter- és környezettervek | `art/BLENDER_STUDY.md`, `art/WORLD_ART.md` |
| Kezdeti koncepció – történeti dokumentum | `FORDITOTT_SUPERMARIO_PROJECT.md` |
| Android build, ellenőrzések és export | `.github/workflows/android-build.yml` |

## Az első pálya konkrét felépítése
A haladás Z irányú; oldalnézetben a játékos és az ellenfelek X=0 síkon mozognak. A pálya kezdete Z=-15, vége Z=225, a kapu Z=220.
| Z intervallum | Terepmagasság / szerep |
| --- | --- |
| -15–10 | Sík indítás, első akadály és őr |
| 10–22 | Emelkedő: 0 → 2,2 m |
| 22–34 | Magasabb gerinc, ugróelemek |
| 34–46 | Lejtő: 2,2 → 0 m |
| 46–49 | 3 m széles valódi rés |
| 49–62 | Lejtő: 0 → -1,6 m |
| 62–73 | Völgyalj |
| 73–86 | Emelkedő: -1,6 → 0 m |
| 86–94 | Vizesárok előtti megközelítés |
| 94–100 | 6 m széles vizes árok |
| 100–113 | Sík szakasz és emelt ugróelem |
| 113–124 | Emelkedő: 0 → 2,4 m |
| 124–137 | Második gerinc |
| 137–140 | 3 m széles rés |
| 140–149 | Felső terasz |
| 149–163 | Lejtő: 2,4 → -1 m |
| 163–174 | Mélyebb megközelítés |
| 174–179 | 5 m széles rés |
| 179–189 | Emelkedő: -1 → 0 m |
| 189–225 | Rövid lépcsős szakasz, végső őrök és cél |

Ellenőrzőpontok: Z=44, 104, 168, a helyi talajmagasság + 1,1 méteren. Vízbe vagy mély szakadékba esés életerővesztéssel visszavisz az aktív ellenőrzőpontra. Az új területet 8 alapellenfél, normál módban +1, nehéz módban +2 őr védi.

## Kamera és látvány
Ortografikus kamera, 12 m függőleges képtartomány, 3,6 m előretekintés. A talaj a képernyő alsó negyedéhez igazodik; a kamera a terepprofilt követi, a szokásos ugrást nem.
Rajzolási rétegek: 1 – fizikai pálya és szereplők; 2 – korábbi 3D-díszlet; 4 – az első pálya statikus oldalnézeti háttere és célzászlója. A panorámapanelek felváltva tükrözöttek a szélillesztéshez.
Az új pálya valódi lejtős ütközőgeometriát használ, nem a háttérképben festett platformokon járunk.
A kép művészeti referencia, nem ígéret a mockup teljes részletességének reprodukálására.

## Tesztek és elfogadási feltételek
A megszakítás előtt helyben sikeresen futott: karakter/kard/köpeny; környezet; tíz pálya oldalnézeti mozgása; 30 pálya–nehézség-kombináció; az új teljes 240 m-es útvonal valódi játékosfizikával, minden résen átugorva, tényleges vízbeesés és visszatérés.
A CI ezeket újra futtatja, majd 7 pályaponton és széles telefonképarányban képeket készít.
Parancsok: `godot --headless --editor --import`, majd `godot --headless --audio-driver Dummy --script res://tests/first_course_smoke.gd`. A többi teszt a workflow-ban szerepel.
Telefonon még ellenőrizendő: FPS, Android Mobile/Vulkan látvány, kényelmes ugrások, érintőgombok, olvasható rések és víz. A sikeres CI nem helyettesíti ezt.

## Build és átadás
Godot 4.7.2 stable; Android azonosító `com.fuloplevente.reverseplatformer.preview`; versionCode 17.
A build az eredeti Blender-forrásból frissíti az optimalizált udvart. Az exportcsomag a kódot, terveket, textúrákat, Blender-forrásokat, az optimalizált futtatómodelleket, mérési jelentést és a tényleges játékfotókat együtt őrzi.
Az APK aláírását és SHA-256 ellenőrzőösszegét a CI ellenőrzi. Csak sikeres build és tesztek után készül GitHub előzetes kiadás egyetlen APK-val és a teljes projekt ZIP-jével.
Privát aláírókulcs, token és átmeneti környezetadat nem része az exportnak.

## Következő munka
1. A CI játékfotóinak ellenőrzése, szükség esetén látványjavítás.
2. Az APK kipróbálása telefonon, visszajelzés az ugrásokról, harcról és kameráról.
3. Az első pálya további finomítása a visszajelzés alapján.
4. A két eredeti mockup PNG hozzáadása, amikor újra hozzáférhető.
5. Csak az első oldalnézeti pálya elfogadása után továbblépés a többi pályára / 3D-re.
