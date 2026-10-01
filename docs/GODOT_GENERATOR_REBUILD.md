# Godot Generator Rebuild — 10 hosszú pálya, 3 nehézség, 2 nézet

Állapot: megkezdett újratervezés, 2026-10-01.  
Kiinduló commit: `f9439cdde045d06365641483288110996cfeeabe` — a sikeres 0.1.9 / CI #79 Godot checkpoint.  
Aktív ág: `godot/generator-rebuild`.

## Döntés

A játék fő fejlesztési motorja **Godot 4.7.2 Mobile renderer** marad.

Az Unreal-kísérleti ág megmarad összehasonlítási és későbbi lehetőségként, de a teljes, automatizálható fejlesztési lánc jelenleg Godotban működik:

```text
GitHub
→ Godot headless import
→ smoke tesztek
→ gameplay screenshotok
→ Android export
→ APK aláírás-ellenőrzés
→ telefonos teszt
```

Az Unrealhez megtervezett jó architektúrát átültetjük Godotba:

**1 közös pályagenerátor + 10 pályadefiníció + újrahasználható szegmensek + 3 nehézségi profil + 2 kameramód.**

Nem készül 10 egymástól független, nagy pályaszkript.

---

## Alapelv

A generátor **a pálya szerkezetét generálja, nem a grafikai minőséget**.

Tilos a végleges látványt `BoxMesh`, `SphereMesh`, `CylinderMesh` tömeges használatával helyettesíteni.

A végleges rendszer:

```text
StagePlanGenerator
       ↓
kiválasztott, kézzel megtervezett szegmens
       ↓
PackedScene / GLB assetek
       ↓
MultiMesh / instancing dekoráció
       ↓
világítás + VFX + ellenfelek
```

A mockupok a vizuális specifikációk.

---

## Új architektúra

```text
scripts/generation/
├── stage_catalog.gd
├── difficulty_profiles.gd
├── segment_catalog.gd
├── stage_plan_generator.gd
├── runtime_stage_builder.gd          # következő implementációs blokk
├── segment_streamer.gd               # következő implementációs blokk
└── encounter_director.gd             # következő implementációs blokk

stages/
├── shared/
│   ├── start/
│   ├── combat/
│   ├── bridge/
│   ├── hazard/
│   ├── checkpoint/
│   └── finish/
└── biome/
    ├── courtyard/
    ├── royal_gardens/
    ├── eagle_cliff/
    ├── frozen_bastion/
    ├── forge/
    ├── windmill_valley/
    ├── catacombs/
    ├── shadow_canyon/
    ├── black_forest/
    └── crown_citadel/
```

A pályák adatai külön katalógusban maradnak; a generátor csak ezeket értelmezi.

---

## A 10 új pálya

| # | Pálya | Vizuális identitás | Célhossz |
|---|---|---|---:|
| 1 | Várudvar – A Belső Kapu | világos mészkő, vörös/arany zászlók, ciprusok, szobrok, szökőkutak | 700–800 m |
| 2 | A Királyi Kertek – Az Elveszett Ösvény | sövények, rózsák, pavilonok, tavak, kőhidak | 750–850 m |
| 3 | Sas-szirt – A Mélység Felett | sziklafalak, vízesések, függőhidak, daruk, hegyi vár | 800–900 m |
| 4 | Dermedt Bástya – A Jégkapu | hó, jég, jégcsapok, fagyott hidak, kék heraldika | 800–900 m |
| 5 | Vaskohó – A Tűz Negyede | fémplatformok, láncok, kohók, olvadt fém, gépezetek | 850–950 m |
| 6 | Szélmalom-völgy – Az Ostrom Előtt | favázas házak, búzamező, malmok, szekerek, ostrom | 850–950 m |
| 7 | Az Elfeledett Katakombák – A Holtak Útja | kripták, csontok, gyertyák, ketrecek, láncok | 900–1000 m |
| 8 | Árnyékszurdok – A Törött Híd | szurdok, romhidak, köd, láncok, őrtornyok | 900–1050 m |
| 9 | Feketeerdő Erődje – Az Utolsó Őrség | sötét fenyves, mohás romok, paliszád, őrtornyok | 950–1100 m |
| 10 | A Korona Citadellája – A Végső Ostrom | monumentális citadella, ostromgépek, hidak, szobrok, tömegjelenet | 1100–1300 m |

A méterérték célérték. A játékidő, ritmus és változatosság fontosabb, mint a pontos távolság.

---

## Szegmens-nyelvtan

A teljes pályákat nem egyetlen kézzel megírt koordinátalista alkotja.

Alap szegmenstípusok:

```text
start
traversal
combat_small
combat_large
bridge
gap
stairs
hazard
archer_ambush
vista
checkpoint
tower
gate
mini_boss
finish
```

Egy szegmens több biome-változatot kaphat.

Példa:

```text
bridge/courtyard_a.tscn
bridge/garden_a.tscn
bridge/cliff_rope_a.tscn
bridge/ice_a.tscn
bridge/forge_a.tscn
bridge/village_a.tscn
bridge/catacomb_a.tscn
```

A játékmeneti szerep ismétlődhet, de a megjelenés, a veszélyek, az ellenfelek és a dekoráció biome-specifikus.

---

## Pályán belüli ismétlődés

Az ismétlés kívánatos, ha nem mechanikus másolás.

Például a Várudvar használhatja:

```text
Wall_A / Wall_B / Wall_C
Courtyard_A / Courtyard_B / Courtyard_C
Bridge_A / Bridge_B
Tower_A / Tower_B
Combat_A / Combat_B / Combat_C
```

Ugyanaz a szegmens más:

- seedet;
- prop-elhelyezést;
- növényzetet;
- banner-variánst;
- ellenfélkombinációt;
- hazardot;
- világítási akcentust

kaphat.

---

## Három nehézség

Nem készül 30 külön pálya.

```text
10 pálya × ugyanaz a pályadefiníció
+
Easy / Normal / Hard profil
```

### Easy

- kb. 0,72× ellenfélsűrűség;
- 0,75× ellenséges sebzés;
- lassabb hazard;
- sűrűbb checkpoint;
- több gyógyulási lehetőség;
- kevés elit.

### Normal

A tervezett alapélmény.

### Hard

- kb. 1,35× ellenfélsűrűség;
- 1,25× sebzés;
- gyorsabb hazard;
- ritkább checkpoint;
- kevesebb gyógyulás;
- több elit és kombinált encounter.

A nehézség nem cseréli le a biome-ot vagy a pálya vizuális identitását.

---

## Két nézet az első teljes verzióban

### Side View

Ez a fő játékmód és a 10 mockup elsődleges célja.

- 3D világ;
- játékos oldalirányú síkra korlátozva;
- ortografikus / közel ortografikus kamera;
- platformok, ellenfelek és hazardok olvashatósága elsődleges.

### Third Person

Ugyanaz a pálya és ugyanazok az objektumok.

- perspektivikus kamera;
- szabadabb 3D mozgás;
- nincs második map.

A jelenlegi `camera_rig.gd` már jó migrációs alap.

---

## Streaming

A 700–1300 m-es pályák miatt nem kell a teljes pályát folyamatosan teljes részletességgel aktívan tartani.

Tervezett ablak:

```text
~80–100 m játékos mögött
~200–250 m játékos előtt
```

A szegmensek:

- betöltődnek / aktiválódnak a játékos előtt;
- távoli logikájuk leállhat;
- mögötte felszabadíthatók vagy alacsony költségű állapotba tehetők;
- a fontos checkpoint/haladás állapot külön megmarad.

---

## Grafikai pipeline

A fő környezeti elemek Blenderből / kész, jogtisztán használható assetből érkeznek.

Példa Stage 1 kit:

```text
castle_wall_a.glb
castle_wall_b.glb
castle_arch_a.glb
castle_tower_a.glb
castle_gate_a.glb
stone_bridge_a.glb
fountain_a.glb
lion_statue_a.glb
banner_red_gold_a.glb
cypress_a.glb
cypress_b.glb
crate_a.glb
barrel_a.glb
brazier_a.glb
```

Godot feladata ezek:

- példányosítása;
- variálása;
- ütközése;
- streamelése;
- encounterökkel való összekötése.

Sok ismétlődő dekorációhoz `MultiMeshInstance3D` használható.

---

## Első vertical slice

Elsőként **Stage 1 – Várudvar** készül újra kb. 700–800 méterben.

Tervezett ritmus:

```text
START
→ külső várfal
→ kis harc
→ szökőkutas udvar
→ íjászos rész
→ kőhíd
→ checkpoint
→ belső kert
→ őrtorony
→ hazard
→ nagy udvar
→ nagy harc
→ lépcsős várfal
→ checkpoint
→ kapuelőtér
→ elit őrök / mini-boss
→ belső kapu
```

A régi 240 m-es Stage 1 addig referencia/fallback marad, amíg az új generált Stage 1 nem megy át ugyanazon a CI- és telefonos tesztláncon.

---

## Implementációs sorrend

### G0 — architektúra
- [x] 10 új pályadefiníció
- [x] 3 nehézségi profil
- [x] determinisztikus stage-plan generátor
- [x] új generator smoke test
- [ ] runtime builder

### G1 — Stage 1 hosszú blockout
- [ ] 700–800 m generált járható útvonal
- [ ] checkpointok
- [ ] bridge/gap/stairs/hazard segmentek
- [ ] encounter director
- [ ] finish/gate
- [ ] régi 240 m fizika teszt helyett új hosszú traversal teszt

### G2 — Stage 1 végleges vizuális kit
- [ ] várfal-modulok
- [ ] kapu + tornyok
- [ ] szökőkút / szobor
- [ ] cypress + növényzet
- [ ] banner / crate / barrel / brazier
- [ ] világítás/VFX
- [ ] referencia-közeli side-view kompozíció

### G3 — streaming + mobil
- [ ] segment streamer
- [ ] MultiMesh dekor
- [ ] LOD/távolsági lekapcsolás
- [ ] memória/FPS mérések
- [ ] Android Mobile/Vulkan telefonos teszt

### G4 — Stage 2–10
Mind ugyanazt a generátort használja, biome-specifikus segment és asset poollal.

---

## Elfogadási szabály

Egy generált pálya csak akkor tekinthető elkészültnek, ha:

1. determinisztikus seed mellett reprodukálható;
2. a saját biome-ját vizuálisan felismerhetően képviseli;
3. nem csak újraszínezett másolata egy másik pályának;
4. Easy/Normal/Hard ugyanazt a világot használja, de ténylegesen eltérő encounter/hazard ritmust ad;
5. Side View és Third Person ugyanazon a pályán működik;
6. a teljes útvonal fizikai traversal teszten átmegy;
7. az Android APK CI-ben elkészül;
8. valódi telefonon ellenőrizhető.

## Fontos

A Godot generator rebuild nem dobja el a 0.1.9 munkát. A karakter, harc, UI, kamera, Blender pipeline és mobil buildlánc újrahasznosul.

A változás fő célja: **a korábbi rövid, külön koordinátalistákból álló pályarendszert egy hosszú, moduláris, mockup-alapú pályageneráló rendszerre cserélni.**


---

## Difficulty-aware geometria

Nem követelmény, hogy Easy / Normal / Hard ugyanazt a pályageometriát használja.

A közös generátor és ugyanaz a stage/biome definíció szolgálja ki mindhárom nehézséget, de a difficulty profile a geometriai generálást is módosíthatja.

Példák:

- **Easy:** szélesebb hidak, kisebb rések, több biztonságos landing, egyszerűbb platformritmus;
- **Normal:** az alap tervezett geometria;
- **Hard:** nehezebb platformkombinációk, nagyobb rések, több mozgó elem, veszélyesebb alternatív útvonalak, ritkább safe recovery.

A biome, fő landmarkok, történeti helyszín és vizuális identitás ugyanaz maradjon, de a konkrét útvonal és szegmenssorrend eltérhet.

## Szegmens-sorrendi szabályok / pályanyelvtan

A weighted random választás fölött kötelező constraint/grammar réteg működik. A generátor nem tehet tetszőleges szegmenseket egymás után.

Alapszabályok:

- nagy gap vagy precíz ugrás után jöjjön biztonságos landing / traversal;
- nagy hazard után ne jöjjön közvetlenül újabb nagy hazard;
- két nagy combat encounter között legyen traversal, vista, checkpoint vagy rövid pihenő;
- checkpoint előtt és után legyen biztonságos, jól olvasható szakasz;
- mini-boss előtt legyen felvezetés, utána ne jöjjön azonnal újabb nagy encounter;
- bridge / moving-platform szakasz után legyen stabil talaj;
- archer ambush csak akkor kombinálható precíz platformozással, ha a difficulty szabályai ezt megengedik;
- a pálya eleje egyszerűbb, a közepe változatosabb, a vége intenzívebb legyen;
- a stage-spec signature segmentjei biztosan kerüljenek be;
- ha a pálya vége felé még hiányzik kötelező signature/segment típus, kapjon prioritást;
- Easy több safe recoveryt, Hard sűrűbb és összetettebb, de teljesíthető kombinációkat enged.

Ez nem fix sorrend, hanem szabályvezérelt generálás.


## Stage 1 generator/difficulty javítás — 2026-10-01

Az aktuális runtime-feladat kizárólag **Stage 1 – Várudvar**. A 2–10. pálya
katalógusbejegyzései tervek: a saját mockupjaik alapján később külön környezet,
szegmens- és assetkészlet, ellenfél- és veszélyválaszték készül hozzájuk.
A közös generátor nem jelent azonos biome-ot vagy kész kilenc új pályát.

- A kötelező landmarkok és checkpointok együtt kapnak helyet a pályatervben.
  A helyfoglalás az átvezető szakaszokat is számolja, a landmarkok teljes
  hossza megmarad. Random filler csak a fennmaradó keretet használhatja.
- A mini-boss előtt külön 38 m biztonságos felvezetés van; a lezárás is
  áthalad a sorrendi ellenőrzésen. A teljes pálya a kisorsolt célhosszra készül.
- A profil a játékos életét, ellenfél életét/sebzését/mozgását és csapdasebzést
  egy helyen határozza meg. Az elit 1,25× élet- és 1,15× sebzésbónusza aktív.
  A szorzók ismételt alkalmazáskor nem halmozódnak.
- Az első pálya új checkpointjának első aktiválása 20 alapélet ×
  healing_multiplier gyógyulást ad (Easy 27, Normal 20, Hard 13), maximum
  a játékos maximális életéig. Ugyanaz a pont nem ad ismét gyógyulást.
- A híd két valódi, Z irányú ugrásból és középső landolóból áll. Ez oldalnézetben
  is nehézségkülönbséget ad; a híd X szélessége a 3D-s nézetben is változik.

| Profil | Játékos HP | Ellenfél HP | Ellenfél sebzés | Csapdasebzés | Híd rése | Középső landoló |
|---|---:|---:|---:|---:|---:|---:|
| Easy | 120 | 0,82× | 0,75× | 0,75× | 2,4 m | 8 m |
| Normal | 100 | 1× | 1× | 1× | 3,3 m | 6 m |
| Hard | 80 | 1,25× | 1,25× | 1,25× | 4,2 m | 4,5 m |

A checkpoint_interval célérték, nem pontos távolsági ígéret: a landmarkok és
biztonságos felvezetések miatt a pontok helye eltérhet. A Várudvar jelenlegi
700–800 m terve legalább 5/4/3 pontot tartalmaz Easy/Normal/Hard sorrendben.
Más, még nem megépített biome definícióban a kötelező biztonságos váz
helyigénye korlátozhatja a checkpointok számát.

Ellenőrzések: `stage_grammar_smoke.gd` 1920 külön seedet vizsgál a közös
tervező adatain; ez nem a kilenc jövőbeli pálya fizikai vagy vizuális elfogadása.
`difficulty_runtime_smoke.gd` az első pálya tényleges objektumait és profiljait
ellenőrzi. `first_course_smoke.gd` mindhárom elsőpálya-útvonalon a valódi
játékosfizikával halad végig. Az Android-látvány, érintés és játékegyensúly
telefonon továbbra is ellenőrzendő. A hosszú pálya környezete még blockout;
a végleges mockup-közeli várudvari assetkészlet külön feladat.
