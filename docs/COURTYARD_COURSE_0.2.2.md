# Várudvar – 0.2.2

## Javított probléma

A 0.2.1 nyitó 25 méterén volt részletes burkolat. A hosszú generált útvonal többi része főként 0,8 m vastag, sík tesztpadlókból és egyszerű landmark jelölőkből állt. A kamerához használt `height_at` mindig nullát adott vissza.

## Aktuális első pálya

- A `long_stage_one.gd` minden szakaszhoz folytonos terepprofilt rendel. Az ütközés, a kamera, az ellenfelek és a cél magassága ugyanebből a profilból készül.
- A szakaszhatárok talajmagassága nulla, így nincs illesztési lépcső. A rövid maradékszakaszok síkak; a rámpák meredeksége korlátozott.
- Teraszok, emelkedők, lejtők, kőakadályok és valódi rések tagolják az útvonalat. Az akadálymagasság könnyű/normál/nehéz fokozaton 0,65/0,85/1,05 m.
- A checkpointok, a veszélyek utáni pihenők és a teljes boss-felvezetés nem kapnak ugróakadályt.
- A `courtyard_course_art.gd` a teljes fizikai talajt borítja relief falazattal, párkánnyal és járólapokkal. A valódi réseken nincs burkolat vagy ütközés.
- Hat új Blender/GLB modell: faragott kő, várfal, torony, szökőkút, ciprus és virágos borostyán. A kőelemek MultiMesh kötegekben készülnek, a díszlet szakaszonként követi a meglévő streaming ablakot.
- Az elfogadott nyitó minta és a karakterek megmaradnak. A hosszú úton várfalak, növényzet és kellékek ismétlődnek, a szökőkút és torony a megfelelő landmarkhoz kerül.

## Ellenőrzés

A `first_course_smoke.gd` mindhárom 700–800 m-es útvonalat valós játékosfizikával járja végig. A `courtyard_coverage_smoke.gd` ellenőrzi a talajgrafikát minden szakaszon, a terep és ütközés egyezését, a szintkülönbséget mindhárom pályaharmadban, a biztonságos felvezetéseket és a késői díszlet streaming láthatóságát. A CI hét ponton és széles képaránnyal képet készít a pályáról.

A telefonos teljesítmény és vizuális elfogadás felhasználói próbája még szükséges. A kilenc további pálya saját környezetének megépítése nincs ebben a változatban. Az eredeti, cím alapján azonosított tíz mockup: `art/references/stage-mockups-2026-10-01/`.

## Szerkeszthető grafikai forrás

`tools/blender/generate_courtyard_course_kit.py` determinisztikusan előállítja a modelleket. A szerkeszthető `.blend` fájlok az `art/source/world/courtyard_course/` könyvtárban, a runtime GLB-k az `assets/models/` alatt találhatók. A referencia színpaletta sRGB értékeit export előtt lineáris színekké alakítja.
