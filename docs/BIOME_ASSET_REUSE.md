# A tíz mockup saját környezete – közös assetek, eltérő pályák

Összesen tíz pálya van. A teljes Várudvar kitje után **kilenc** saját biome és
pálya kidolgozása következik. A név és a környezet forrása az eredeti mockup,
a kanonikus lista pedig `scripts/generation/stage_catalog.gd`.

A következő táblázat fejlesztési terv, nem elkészült környezetek listája.

| Pálya | Újrahasználható alap | Saját anyag / néhány új elem |
| --- | --- | --- |
| 1. VÁRUDVAR – A BELSŐ KAPU | Kőfal, boltív, kapu, láda, hordó, pad, ciprus, zászló | Meleg mészkő, vörös-arany díszek; kit végig bekötve |
| 2. A KIRÁLYI KERTEK – AZ ELVESZETT ÖSVÉNY | Burkolat, kőhíd, szökőkút, pad, ciprus | Sövény, rózsa, lugas, tópart és pavilon |
| 3. SAS-SZIRT – A MÉLYSÉG FELETT | Torony, korlát, fa kellékek, kőmodulok | Sziklafalak, kötélhíd, vízesés, daru és mélységi háttér |
| 4. DERMEDT BÁSTYA – A JÉGKAPU | Fal, kapu, torony, burkolat | Hó-, jég- és fagyott kőanyag, jégcsap, befagyott vízesés |
| 5. VASKOHÓ – A TŰZ NEGYEDE | Ládák, hordók, kapu és szerkezeti modulok | Kormos kő, fémplatform, lánc, kohó, olvadék és prés |
| 6. SZÉLMALOM-VÖLGY – AZ OSTROM ELŐTT | Quaternius fa/ház elemek, kocsi, láda, kerítés | Malomlapát, búza, falusi híd és ostromnyomok |
| 7. AZ ELFELEDETT KATAKOMBÁK – A HOLTAK ÚTJA | Boltív, kőfal, kapu, padló, fém kellékek | Sötét nyirkos kő, sírfülke, csont, gyertya, ketrec |
| 8. ÁRNYÉKSZURDOK – A TÖRÖTT HÍD | Hídmodul, torony, kőelemek | Romos/szakadt változatok, láncok, szikla és köd |
| 9. FEKETEERDŐ ERŐDJE – AZ UTOLSÓ ŐRSÉG | Torony, kapu, fa kellékek, kőromok | Mohás anyagok, erdei fák, gyökerek és paliszád |
| 10. A KORONA CITADELLÁJA – A VÉGSŐ OSTROM | Kapu, torony, fal, zászló és udvari kit | Nagyobb lépték, királyi díszek, óriásszobrok és ostromrészletek |

## Képalapú anyagváltozatok

A geometria, UV-k és ütközés sok helyen megtartható. A meglévő atlaszokhoz
külön anyagváltozat készülhet: tiszta mészkő, mohás kő, havas kő, kormos kő,
kopott fa, rozsda és jég. A közös anyagbank csökkenti az ismételt munkát.
Új, egyedi formákhoz külön modell szükséges; például egy malomlapát vagy
oroszlánszobor felületátfestéssel nem jön létre.

Képből használható textúrázó eszközök (2026-10-01-én ellenőrzött dokumentáció):

- [Meshy AI Texturing](https://docs.meshy.ai/en/webapp/guides/3d-model/ai-texturing):
  meglévő GLB/OBJ/FBX mesh újratextúrázása szöveggel vagy referenciaképpel;
  Base Color, Normal, Roughness és Metallic térképek.
- [Adobe Substance 3D Sampler Image-to-Texture](https://experienceleague.adobe.com/en/docs/substance-3d-sampler/using/features-and-workflows/generative-workflows):
  képből négyzetes, ismételhető textúraváltozatok.
- [Sampler Image-to-Material](https://experienceleague.adobe.com/en/docs/substance-3d-sampler/using/filters/tools/image-to-material):
  anyagtérképek, beleértve normal/height/roughness és a belesütött megvilágítás eltávolítását.

Javasolt próba: a Várudvar mockupból néhány anyagrészlet, egy kőmodul és egy
falmező újratextúrázása; majd összehasonlítás a jelenlegi CC0 készlettel Godotban.
Csak a működő próba után érdemes az egész közös anyagbankot lecserélni.
Az első mészkő albedo-próba beépített képgenerálással elkészült a nyitószakaszon;
az eredeti/AI Godot összehasonlítás és a prompt az [AI_MATERIAL_PILOT.md](AI_MATERIAL_PILOT.md)
fájlban szerepel. Meshy/Adobe nem futott, előfizetést nem vásároltunk.

Az egyes biome-ok saját háttérképet, fényt és pályaszerkezetet kapnak. A
játékmechanikák is a saját mockuphoz igazodnak: jégcsúszás, valódi szakadék,
láva/prés, törött híd és katakombacsapda külön rendszer, a kit újrahasznosítása
nem helyettesíti ezek megépítését és tesztelését.
