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
