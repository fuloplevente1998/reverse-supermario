# Térbeli környezet – 0.1.5 grafikai teszt

A `feature/0.1.3-stage1-models` ág munkájának folytatása az új, köpenyes lovag mellett.
A korábbi kőtextúrák, udvar, kapu, négy udvari kellék és öt ellenfélmodell megmaradtak.

## Elkészült és játékba kötött modellek

- Várudvar: textúrázott, szabálytalan térbeli kőlapok, szűkebb fugák; 4 anyagcsoport.
- Várkapu: két torony, külön modellezett toronykövek, pártázat, boltív, zászlók, oroszlánok.
- Favázas ház: külön gerendák, ajtódeszkák, ablakrácsok, kémény és térbeli tetőcserepek.
- Tölgyfa: törzs, oldalágak, gyökérnyúlványok, több aszimmetrikus lombtömeg.
- Fenyőfa, sziklakészlet, tagolt várfal, kovácsműhely és vízimalom.
- Hordó, láda, zászló és az első pálya kőakadályai a korábbi modellkészletből.
- Az első udvarhoz falakon túli házsor, növényzet, talaj és távoli dombok.
- A további 9 pálya a közös modellkészletből kapott a pályához illő első környezeti elrendezést.

A statikus dekoráció anyagai összevonva: az udvar 6 háló, a díszítő háló 16 anyagfelület.
A várudvar dekorációja kb. 212 ezer háromszög, a kapu kb. 24 ezer; telefonos teljesítménymérés még szükséges.

## Blender-források

`art/source/world/*.blend`: külön szerkeszthető részek, beágyazott kőtextúrák.
`assets/models/*.glb`, `courtyard_environment.gltf` + a hozzá tartozó `.bin` fájlok: játékhoz összevont, exportált változatok.
`tools/blender/generate_world.py`: a régebbi generátorokat bővítő új környezetgenerátor.

Újragenerálás a projekt gyökeréből:

```sh
blender --background --factory-startup --python tools/blender/generate_world.py
blender --background --factory-startup --python tools/blender/generate_enemies.py -- --output assets/models --source art/source/world
```

A csapás javítása külön: `tools/blender/update_knight_clips.py` a már textúrázott lovag Blender-forrását nyitja meg.
A kézben a kard pengéje felfelé áll. A csapás felkészítést, előre irányuló átlós vágást és visszaállást tartalmaz.
A `knight_model_smoke.gd` a penge valós világpozícióját is ellenőrzi.

## Ellenőrzés és jelenlegi határok

Godotban ellenőrizve: karakteranimációk, kard iránya és előrehaladó csapásíve,
textúrás udvar, mind a 10 pálya környezeti modelljei, az 5 korábbi ellenfélmodell,
30 pálya/nehézség kombináció, akadályok, joystick, kapu és sebzés.

A mellékelt képek a játék tényleges renderjei (`tests/world_preview.gd`).
A házak kívülről modellezettek; belső tér nincs. A növények és a malomkerék jelenleg statikusak.
A további pályák közös elemekből felépített első grafikai körök; a hidak és egyes csapdák még a korábbi geometriát használják.
A környezet a korábbi játékmeneti ütközéseket követi; a díszletek a játékfolyosón kívül helyezkednek el.
A köpeny csontanimáció, nem fizikai szimuláció. Telefonos látvány- és FPS-próba nincs elvégezve.
