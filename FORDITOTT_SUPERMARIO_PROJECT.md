# Fordított SuperMario – teljes projektösszefoglaló

## 1. Alapkoncepció

A projekt egy **fordított szereposztású, mobilra készülő 3D platform-akciójáték**.

A klasszikus platformjáték-logikát megfordítjuk:

- a játékos nem a „jó hős”, hanem a történet **gonosz / antihős szereplője**;
- a pályán a „jók” próbálják megállítani;
- a főhős célja, hogy átverekedje magát a pályán és eljusson a végső célponthoz;
- a világ hangulata meseszerű, de saját karakterekkel, saját vizuális világgal és saját pályadizájnnal készül.

A „Fordított SuperMario” jelenleg **munkacím / koncepcióleírás**. Publikus kiadáshoz eredeti neveket, karaktereket, modelleket, zenéket és pályákat kell használni; Nintendo/Mario asseteket nem használunk.

## 2. Célplatform

Elsődleges cél:

- **Android APK**
- telefonos, érintőképernyős vezérlés
- később opcionálisan Android AAB / Play Store, Windows debug build és gamepad támogatás.

A játék **nem böngészős projekt**.

## 3. Technológiai döntés

### Engine
**Godot 4**

### Renderer
**Mobile Renderer**

Indok:

- Androidon jobb teljesítmény és kisebb GPU-terhelés;
- mobil hardveren reálisabb cél;
- teljes 3D jelenetek készíthetők;
- támogatja a CharacterBody3D alapú mozgást;
- egyszerű GitHub Actions build alakítható ki.

### Jelenlegi célverzió
**Godot 4.7.2 stable**

A projektet úgy készítjük, hogy ne kelljen helyben minden alkalommal kézzel exportálni: a GitHub CI feladata lesz APK-t készíteni.

## 4. Kamera

A játék nem oldalnézetes klasszikus 2D klón. A kamera **3D third-person**, a karakter mögött / fej mögött helyezkedik el, enyhén magasabbról néz előre és követi a főhőst.

Később: kameraütközés, falon átmenés megakadályozása, finom követési késleltetés, harci célpontkövetés és dinamikus FOV sprintnél.

## 5. Játékos – „gonosz” főhős

A játékos egy eredeti antihős karakter.

Első prototípus mechanikák:

- előre / hátra / balra / jobbra mozgás;
- ugrás;
- gravitáció;
- fordulás a mozgás irányába;
- támadás;
- védekezés / block;
- HP rendszer;
- halál / újraindítás.

Később: sprint, dodge, combo rendszer, erős támadás, levegőből támadás, speciális képesség, stamina, lock-on, fegyverek és fejlődési rendszer.

## 6. Harcrendszer

Az MVP harcrendszer tartalmaz közelharci ütést rövid hatótávval és cooldownnal, block funkciót, amely csökkenti a beérkező sebzést, valamint HP rendszert.

Később: combo 1–2–3, parry, dodge, stagger, hit reaction, knockback és boss mechanikák.

## 7. Ellenfelek – a „jók”

A világban a játékos ellenfelei a hagyományos történet „jó” szereplői.

Első AI:

- érzékeli a játékost;
- megközelíti;
- közel érve támad;
- sebződik;
- HP elfogyásakor eltűnik.

Későbbi típusok: közelharcos őr, pajzsos lovag, íjász, mágus, gyors kis ellenfél, repülő ellenfél, miniboss és pályavégi boss.

## 8. Pályastruktúra

A játék platform-elemeket és harcot kombinál. Lehetnek platformok, szakadékok, lépcsők, hidak, mozgó elemek, csapdák, ellenfélcsoportok, titkos útvonalak, gyűjthető tárgyak, checkpointok és végső célterület.

Az első prototípus sík tesztpályát, néhány platformot, több ellenfelet és a pálya végén célt tartalmaz.

## 9. Cél / „hercegnő”

A korábbi ötlet szerint a pálya végén egy **hercegnőhöz / végcélhoz** kell eljutni. A prototípusban ezt placeholder Goal objektum jelképezi.

A későbbi történet teljesen eredeti karakterekkel készülhet, akár erkölcsileg szürke konfliktussal, ahol a főhős saját szemszögéből nem feltétlenül gonosz.

## 10. Grafikai irány

A cél szép, stilizált, mobilra optimalizált 3D megjelenés erős sziluettekkel, rajzfilmes/fantasy hangulattal, ésszerű polygon-számmal, jó fényekkel és mobilbarát PBR anyagokkal.

A prototípus primitive mesh-eket használ, hogy előbb a programozás és az APK build működjön. Utána Blender/saját modellek, animációk, saját UI, textúrák, hangok és zene kerülnek be.

## 11. Vezérlés

### PC debug
- W/A/S/D – mozgás
- Space – ugrás
- J – támadás
- K – block

### Android
Képernyős irány-, ugrás-, attack- és block gombok. Később virtuális joystick.

## 12. Első MVP

Az első buildelhető APK célja:

- elindul Androidon;
- van 3D pálya és third-person kamera;
- a játékos mozog, ugrik, támad és blockol;
- ellenfelek követik és támadják;
- HP rendszer működik;
- elérhető a pálya végi cél;
- win/death állapot megjelenik;
- újraindítható.

Még nem cél: végleges grafika, teljes animációs csomag, történet, inventory, mentés, több pálya, boss vagy multiplayer.

## 13. Projektstruktúra

```text
reverse-supermario/
├─ project.godot
├─ export_presets.cfg
├─ README.md
├─ FORDITOTT_SUPERMARIO_PROJECT.md
├─ scenes/
│  └─ main.tscn
├─ scripts/
│  ├─ player.gd
│  ├─ enemy.gd
│  └─ game.gd
└─ .github/
   └─ workflows/
      └─ android-build.yml
```

## 14. GitHub / CI terv

Minden `main` branch push után Android debug build: checkout, Godot környezet, Android export, `ReversePlatformer-debug.apk`, majd GitHub Actions artifact feltöltés.

Később saját Android keystore, signed release APK, AAB, versionCode/versionName és GitHub Release automatizálás.

## 15. Verzióterv

### v0.0.1 – Prototype
Projekt indul, basic scene, player, kamera.

### v0.0.2 – Combat prototype
Attack, block, enemy HP, player HP.

### v0.0.3 – Mobile controls
Touch UI, stabil Android input.

### v0.0.4 – Gameplay loop
Goal, death, restart, több ellenfél.

### v0.1.0 – First playable
Első rövid pálya, alap UI, egyszerű hang, első saját karaktermodellek.

### v0.2.x
Animációk, combo, dodge, jobb AI, checkpoint.

### v0.5.x
Több pálya, boss, progression.

### v1.0
Teljes mobiljáték.

## 16. Következő fejlesztési prioritás

1. GitHub repo;
2. Godot projektváz;
3. GitHub Actions APK build;
4. APK tényleges indítási teszt Androidon;
5. touch kontroll finomítása;
6. kamera;
7. harcérzet;
8. animáció;
9. grafikai assetek;
10. első valódi pálya.

A legfontosabb, hogy először legyen egy **biztosan forduló és telepíthető APK pipeline**, utána építjük tovább a grafikát és a játékmenetet.
