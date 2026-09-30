# Blender modellcsomag – második modellezési kör

Referencia: a korábbi szarvas, bordó köpenyes lovag karakterlapja (`image-gen-1(10).png`) és a várudvari mockup. A modell saját, eljárásosan létrehozott geometriából áll.

## Elkészült

- `source/knight_study.blend`: külön szerkeszthető páncélelemek, sisak, hajlított szarvak, réteges vállpáncél, bordó köpeny, kard és pajzs; stúdióvilágítás.
- `../assets/models/knight_study.glb`: 14 csontos, mereven súlyozott karakter, egyetlen háló és egyetlen sütött PBR anyag; öt alapmozgás (`idle`, `run`, `attack`, `block`, `jump`).
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
```

## Készültség és következő lépés

Ez második modellváltozat, nem végleges mockupminőség. A szín, normál, érdesség és fémesség sütött textúrát kapott (karakter: 1024×1024 atlasz; fegyverek: 512×512). A felület finom procedurális szemcsézettséget tartalmaz; kézzel festett kopás még nincs. A köpeny a mellkashoz kötött, nincs szövetszimuláció. Az animációk első mozgásvázlatok, nem végleges harci koreográfiák. Android telefonon teljesítményteszt még nem történt.

A következő modellezési kör: sisak és vállpáncél formáinak további finomítása a referencia alapján, valódi köpenydeformáció és kopásrészletek. A várudvar kapuja, kövei és növényzete még nem része ennek a csomagnak.

## Ellenőrzés

`tests/knight_model_smoke.gd` ellenőrzi a 14 csontot, az öt importált mozgást, a két kézcsatolást és a támadás/védekezés animációváltását. Az ellenőrzés Godot 4.7.2-ben futott. A grafikai ellenőrzés asztali szoftveres rendereléssel történik; nem helyettesít Androidon mért FPS-t.
