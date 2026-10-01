# 0.2.3 – Várudvar, az első kb. 100 méter

A felhasználói APK-teszt alapján a 0.2.2 változatos talaja önmagában kevés volt:
a tényleges akadályok ritkák maradtak, a díszletek pedig grafikai munkát igényeltek.
Ez a pass a pálya első 100 méterére összpontosít, a tíz mockup közül továbbra is
csak a **VÁRUDVAR – A BELSŐ KAPU** környezetét dolgozza ki.

## Grafika

A -15…85 m közötti szakasz textúrázott Quaternius Medieval Village/Fantasy Props
Standard elemeket használ. Kőfal, íves ajtó/ablak, kapu, láda, hordó, pad,
udvari kocsi, zászló és borostyán ad részletet a jelenetnek. A talaj falazata
és burkolata is textúrázott kit-mesh; a lejtőt és a nyitott rést követi.
A szegmens, amely a 100 m határt metszi, a végéig megtartja ezt a talajanyagot.
A korábbi 25 m-es próbadíszlet helyét ez a mintaszakasz veszi át.
Saját ciprusmodellünk finomabb, simított változata egészíti ki a csomagot.

A csomagok mellékelt licence **CC0**. Források, eredeti licencszövegek,
archive-hash és reproducibilis import: `assets/vendor/quaternius/` és
`tools/import_quaternius_first100.py`. Nincs megvásárolt asset a változtatásban.

## Fizikai akadályok

| Nehézség | Akadálycsoport | Plusz talajrés | Pihenő |
| --- | --- | --- | --- |
| Easy | 6 | 2,4 m | Generátorszabály szerint |
| Normal | 6 | 3,0 m | Generátorszabály szerint |
| Hard | 5 | Nincs extra | Íjásztámadás után szabad |

A csoportok ládasor, hordósor, padakadály, kétlépcsős ládasor és alacsony
kőakadály típusokat váltanak. Hardon a kőakadály nem férne el az íjászok és a
csapda között, ezért kimarad. A csoportok nem fedik az ellenfelek/csapda
kezdőhelyét, és legalább 9 méterre követik egymást. Magasságuk 0,65–1,495 m;
a játékos 8 m/s-os ugrása valóban átjut rajtuk. A collider mérete a látható
modellhez igazodik. Hordónál henger, a többi tömör akadálynál doboz használatos.
A réseknél a fizikai talaj és az előtéri burkolat egyaránt megszakad.

Az íjászok, a csapda és az első őr harca megmarad. Checkpoint, recovery és boss
felvezetés nem kap új ugróakadályt. A többi kilenc pálya biome-ja nincs átalakítva.

## Ellenőrzés

- `first100_smoke.gd`: valódi ütközők, legalább négy különféle akadály,
  textúrák, szabad recovery, ugrás nélküli megállás és valódi játékosugrás.
- `first_course_smoke.gd`: mindhárom teljes 700–800 m útvonal fizikai bejárása.
- Meglévő difficulty, terep/collision, 1920 seed, harc, HUD és mobil touch tesztek.
- `first100_preview.gd`: öt különböző pont és széles képarány képi ellenőrzése.

A képek desktop Compatibility renderrel készülnek. Az Android Mobile/Vulkan
megjelenést és a telefonos képkockaszámot a készüléken kell még ellenőrizni.
Ez egy kidolgozottabb grafikai mintaszakasz, nem a tíz mockup végleges adaptációja.
