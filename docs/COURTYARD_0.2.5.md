# 0.2.5 – egységes kőanyag, kisebb ugrás és indulási terhelés

A 0.2.4 nyitószakaszán elfogadott képgenerált mészkőanyag a teljes Várudvar
előtéri falazatára/párkányára, kőpilléreire, fedköveire és kőakadályaira kiterjed.
Nincs 100m-es anyaghatár. A fugázott falmezők meglévő atlasza, fa, növényzet,
burkolat és karakterek megmaradnak; ez nem minden modell Meshy-újratextúrázása.
A textúra és eredeti prompt: [AI_MATERIAL_PILOT.md](AI_MATERIAL_PILOT.md).

Az első pályán a mozgás **7,2 → 5,4 m/s**, ugrósebesség **8 → 6,4 m/s**.
Az alap 9,8 m/s² gravitációval számított ugrásmagasság 3,27 → 2,09 m;
ez ideális ballisztikus becslés, a valódi talajkontaktust a bejárási teszt méri.
Easy/Normal/Hard rései 2,2/2,8/3,4 m; híd rései 1,8/2,4/3,0 m.
Az első 100m gyakorlórése 1,8/2,2 m, Hard recovery területe rés nélkül marad.
A többi kilenc pálya mozgásparaméterei változatlanok.

## Terheléscsökkentés

- A régi 3D udvar és külön 3D-kapu csak szabad kameranézetre váltáskor töltődik.
  Oldalnézetben a később betöltött legacy díszlet láthatatlan, árnyékot sem rajzol.
- Az első pálya távoli őreinek/csapdáinak teljes process/animáció/fizika ága
  szünetel. 45m mögött / 65m előtt aktiválódnak, oda-vissza visszakapcsolhatóan.
- A fizikai szegmensablak továbbra is 100/240m; a látható díszletablak 35/65m.
- A menü háttérben tölti a jelenetet; a kezdőkép néhány képkockán át a
  betöltési fedő alatt megjelenik, a játékos és harc addig szünetel.
- Android exportnál shader baker bekapcsolva. Ez nem süt GPU-specifikus
  pipeline cache-t, és önmagában nem bizonyítja az akadás megszűnését.

A pálya továbbra is egyszer épül fel a jelenet létrehozásakor: nem állítunk
valódi instantiate/free streaminget. A készülékes akadás pontos oka és a
telefonos FPS csak új APK kipróbálásával/profilozásával igazolható.

Ellenőrzés: teljes fizikai bejárás mindhárom nehézségen; első akadály valós
ütközése és átugrása; teljespályás anyag-lefedettség; induláskor nem betöltött
legacy udvar; távoli actor feldolgozásának leállítása és reaktiválása;
ismételt kameraváltás duplikálás nélkül; HUD, harc és seed-szabályok.

Meshy hozzáférési út és offline GLB-kit: [MESHY_WORKFLOW.md](MESHY_WORKFLOW.md).
Meshy API-hívás vagy kreditvásárlás még nem történt.
