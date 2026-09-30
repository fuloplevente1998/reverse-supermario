# Blender modellcsomag – harmadik modellezési kör

Referencia: a korábbi szarvas, bordó köpenyes lovag karakterlapja (`image-gen-1(10).png`) és a várudvari mockup. A modell saját, eljárásosan létrehozott geometriából áll.

## Elkészült

- `source/knight_study.blend`: külön szerkeszthető páncélelemek, sisak, hajlított szarvak, réteges vállpáncél, bordó köpeny, kard és pajzs; stúdióvilágítás.
- `../assets/models/knight_study.glb`: 17 csontos karakter, három külön köpenycsonttal, egyetlen háló és egyetlen sütött PBR anyag; öt alapmozgás (`idle`, `run`, `attack`, `block`, `jump`). A páncél merev kötést, a köpeny több csont közötti átmenetes súlyozást kapott.
- `../assets/models/broadsword_study.glb`: külön kard, helyi origón.
- `../assets/models/kite_shield_study.glb`: külön pajzs, helyi origón.
- `source/knight_front.png`, `knight_three_quarter.png`, `knight_back.png`: a valódi modell Blender renderképei.
- `source/model_stats.json`: mért geometriaszámok.

## Használat

Nyisd meg a `.blend` fájlt Blenderben. A forrás páncélelemek külön szerkeszthetők; a rejtett `KnightRuntime` az összevont játékexport. A textúrák be vannak csomagolva a Blender fájlba és a GLB-be.

A játékos vizuális kódja már az új modellt használja. A kard és pajzs kézcsontokhoz csatlakozik. A futás, támadás, védekezés és ugrás a játékállapot szerint vált animációt. A harcszabályok, ütközőtest és ellenfelek grafikája megmaradtak.

Újragenerálás Blender 4.5.3-mal:

```bash
blender --background --python tools/blender/build_knight_study.py
blender --background --python tools/blender/prepare_game_assets.py
blender --background --python tools/blender/verify_cape.py
```

## Készültség és következő lépés

Ez harmadik modellváltozat, nem végleges mockupminőség. A szín, normál, érdesség és fémesség sütött textúrát kapott (karakter: 1024×1024 atlasz; fegyverek: 512×512). A felület procedurális kopásfoltokat és változó érdességet tartalmaz; kézzel festett kopás még nincs. A köpeny három csonton deformálódik, a vállrögzítése fix; az egyes mozgások saját köpenylengést kaptak. Ez előre animált mozgás, nincs fizikai szövetszimuláció vagy környezeti ütközés. Az animációk első mozgásvázlatok, nem végleges harci koreográfiák. Android telefonon teljesítményteszt még nem történt.

A sisak új homlokdíszt, a mellpáncél külön címert, a vállpáncél szegecseket kapott. A következő modellezési körben a várudvar kapuja, kövei és növényzete készülhet el; ezek még nem részei ennek a csomagnak.

## Ellenőrzés

`tests/knight_model_smoke.gd` ellenőrzi a 17 csontot, a köpeny mozgását, az öt importált mozgást, a két kézcsatolást és a támadás/védekezés animációváltását. Az ellenőrzés Godot 4.7.2-ben futott. `verify_cape.py` ténylegesen kiértékelt Blender-hálókoordinátákból ellenőrzi a köpeny deformációját; eredménye a `source/cape_verification.json` fájlban van. A `source/cape_run.gif` valódi Godot-képkockákból készült. A grafikai ellenőrzés asztali szoftveres rendereléssel történik; nem helyettesít Androidon mért FPS-t.


## 0.1.5 folytatás

A kard helyes kéztengellyel és fogásponttal rögzül; új felkészítő–vágó–visszaálló támadóanimáció. A penge világpozícióját is ellenőrzi a karakterteszt. A korábbi GitHub-kőburkolat és ellenfélmodellek átvéve, a továbbépített környezeti modellek részletei: [WORLD_ART.md](WORLD_ART.md).
