"""Export the tested working tree, source artwork, plans and generated runtime."""
import hashlib, json, os, re, shutil, subprocess, zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
out = root / "delivery"
out.mkdir(exist_ok=True)

preset = (root / "export_presets.cfg").read_text(encoding="utf-8")
match = re.search(r'^version/name="([^"]+)"', preset, re.MULTILINE)
version_name = match.group(1) if match else "dev"
release_version = version_name.split("-", 1)[0]

tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=root).decode().split("\0")
paths = {p for p in tracked if p and (root / p).is_file()}
paths.add("art/source/world/runtime_optimization.json")
paths.update(str(p.relative_to(root)) for p in (root / "assets/models").glob("courtyard_environment_part*.bin"))

project_zip = out / f"ReversePlatformer-{release_version}-project.zip"
with zipfile.ZipFile(project_zip, "w", zipfile.ZIP_DEFLATED) as archive:
    for name in sorted(paths):
        if (root / name).is_file():
            archive.write(root / name, name)
    for p in sorted((root / "previews").glob("*.png")):
        archive.write(p, f"art/validation/{release_version}/{p.name}")
    archive.writestr("BUILD_INFO.json", json.dumps({
        "version": version_name,
        "commit": os.environ["GITHUB_SHA"],
        "run": os.environ["GITHUB_RUN_ID"],
        "validation": "All preceding CI tests and screenshot generation completed successfully",
        "phone_validation": "Pending user device testing",
        "reference_notes": "art/references/stage-mockups-2026-10-01/README.md",
        "reference_binaries": "All ten original stage mockups are stored by stage title under art/references/stage-mockups-2026-10-01/."
    }, indent=2))

apk = out / f"ReversePlatformer-{release_version}-teszt.apk"
shutil.copyfile(root / "artifact/ReversePlatformer-debug.apk", apk)
checksum = hashlib.sha256(apk.read_bytes()).hexdigest()
(out / (apk.name + ".sha256")).write_text(checksum + "  " + apk.name + "\n")

for name in [
    "sample_idle_16_9.png",
    "sample_attack.png",
    "sample_block.png",
    "sample_run.png",
    "sample_physical_jump.png",
    "sample_wide.png",
]:
    shutil.copyfile(root / "previews" / name, out / name)

if release_version in ("0.2.2", "0.2.3", "0.2.4", "0.2.5"):
    for pattern, filename in [("side_course_03_*.png", "Varudvar-kozepe.png"), ("side_course_06_*.png", "Varudvar-kapu.png"), ("side_course_wide.png", "Varudvar-szeles.png")]:
        image = next(iter(sorted((root / "previews").glob(pattern))), None)
        if image is None:
            raise RuntimeError(f"Missing full-course visual validation: {pattern}")
        shutil.copyfile(image, out / filename)

if release_version == "0.2.5":
    subprocess.run(["python3", str(root / "tools/meshy_retexture.py"), "kit", "--zip", str(out / "Meshy-Varudvar-kit.zip")], check=True)
    shutil.copyfile(root / "previews/title_startup_ready.png", out / "title_startup_ready.png")
    for name in ["first100_00.png", "first100_02.png", "first100_04.png", "first100_wide.png", "material_pilot_original.png", "material_pilot_ai.png"]:
        shutil.copyfile(root / "previews" / name, out / name)
    notes = (
        "# 0.2.5 – egységes AI mészkő és nyugodtabb mozgás\n\n"
        "A teljes Várudvar előtéri kőelemei, pillérei, fedkövei és kőakadályai "
        "a kedvelt nyitószakasz képgenerált mészkőanyagát használják. A fugázott "
        "falmezők, fa és növényzet meglévő anyagai megmaradnak.\n\n"
        "Az első pályán a mozgás 7,2 helyett 5,4 m/s, az ugrósebesség 8,0 helyett "
        "6,4 m/s. A réseket és hidat az új ugráshoz igazítottuk; mindhárom "
        "teljes útvonalat valódi játékosfizikával ellenőrzi a CI.\n\n"
        "Oldalnézetes induláskor a régi 3D udvar nem töltődik be; nézetváltáskor "
        "egyszer betöltjük. A távoli őrök és csapdák feldolgozása/animációja "
        "szünetel. A menü háttérben tölti a jelenetet, majd rövid betöltési "
        "szakasz alatt kirajzoljuk a nyitórészt. Ez célzott terheléscsökkentés, "
        "a telefonos akadás megszűnését és FPS-t még ellenőrizni kell.\n\n"
        "A Meshy API előkészítő elkészült: tools/meshy_retexture.py, "
        "docs/MESHY_WORKFLOW.md. Meshy-generálás még nem futott; nincs "
        "hozzákapcsolt fiók/API-kulcs.\n\n"
        f"Commit: {os.environ['GITHUB_SHA']}\n"
    )
elif release_version == "0.2.4":
    for name in ["material_pilot_original.png", "material_pilot_ai.png"]:
        shutil.copyfile(root / "previews" / name, out / name)
    for name in ["first100_00.png", "first100_02.png", "first100_04.png", "first100_wide.png"]:
        shutil.copyfile(root / "previews" / name, out / name)
    notes = (
        "# 0.2.4 – teljes Várudvar a mintaszakasz stílusában\n\n"
        "A 700–800 méteres első pálya végig a 0.2.3 mintaszakasz Quaternius CC0 "
        "assetkészletét használja. Textúrázott falazat, burkolat, kapuk, zászlók, "
        "borostyán, ciprusok és udvari kellékek kísérik az útvonalat. "
        "A híd fa korlátot, a torony külön textúrázott építményt kapott.\n\n"
        "Easy 22, Normal 23, Hard 20 valódi ütköző akadálycsoportot tartalmaz. "
        "A későbbi pihenőszakaszok eleje 18 méteren szabad, a végükben legfeljebb "
        "egy alacsony padakadály lehet. Az első 100 méter íjászok utáni pihenője, "
        "a checkpointok, a teljes boss-felvezetés és a végső kapu előtti tér szabad marad. "
        "Az aréna két alacsony kőakadállyal egészül ki.\n\n"
        "A statikus díszleteket szegmensenként közös mesh-csoportokba rendezzük. "
        "A CI ellenőrzi a teljes útvonalat mindhárom nehézségen, a pálya minden "
        "harmadának akadályait és grafikáját, valamint a harcot és a mobil HUD-ot. "
        "A további kilenc pálya saját mockup-alapú környezetének terve a "
        "docs/BIOME_ASSET_REUSE.md fájlban szerepel.\n\n"
        "A nyitószakasz kőpillérei és előtéri kőelemei mockup-alapú AI mészkő "
        "színtextúra-próbát kaptak. Az eredeti/AI összehasonlító képek mellékelve. "
        "Beépített képgenerálással készült; Meshy/Substance nem futott. "
        "Telefonos megjelenés és teljesítménymérés továbbra is szükséges.\n\n"
        f"Commit: {os.environ['GITHUB_SHA']}\n"
    )
elif release_version == "0.2.3":
    for name in ["first100_00.png", "first100_02.png", "first100_04.png", "first100_wide.png"]:
        shutil.copyfile(root / "previews" / name, out / name)
    notes = (
        "# 0.2.3 – Várudvar: első 100 méter\n\n"
        "Quaternius Medieval Village és Fantasy Props ingyenes Standard assetek "
        "kerültek az első kb. 100 méterre. A csomagok saját mellékelt licence CC0; "
        "a források és licencek az assets/vendor/quaternius könyvtárban szerepelnek. "
        "Textúrázott falak, kapuk, borostyán, zászlók és udvari kellékek váltják a korábbi díszletet.\n\n"
        "Easy és Normal hat ütköző akadálycsoportot és egy valódi talajrést kap. "
        "Hard öt akadálycsoportja az íjászok mellett jelenik meg, a harc utáni pihenő szabad. "
        "Ládák, hordók, padakadály és kétlépcsős ládasor tényleges ugrást igényelnek. "
        "A collider a látható tárgyhoz igazodik. A későbbi pályarészek további art passra várnak.\n\n"
        "A CI ellenőrzi az ütközést, az első akadály átugrását, mindhárom teljes útvonalat, "
        "a nehézséget, a harcot, a kezelőfelületet és a képi előnézeteket. "
        "Telefonos kipróbálás és teljesítménymérés még szükséges.\n\n"
        f"Commit: {os.environ['GITHUB_SHA']}\n"
    )
elif release_version == "0.2.2":
    notes = (
        "# 0.2.2 – Várudvar: végig díszített, változatos útvonal\n\n"
        "Az első pálya teljes 700–800 méterén falazott talaj, burkolat, "
        "borostyán, virágok, ciprusok és Blenderben készített várfalak jelennek meg. "
        "Teraszok, emelkedők, lejtők és ismétlődő ugróakadályok váltják a sík tesztpályát. "
        "A szökőkút és torony valódi GLB díszletet kapott. A rések nyitva maradnak, "
        "a checkpointok és veszélyek utáni pihenők ugróakadály nélküliek.\n\n"
        "Mindhárom teljes útvonalat valódi játékosfizikával ellenőrzi a CI. "
        "Külön teszt ellenőrzi a burkolatot a pálya végéig, a terep és az ütközés "
        "egyezését, valamint a késői díszletek láthatóságát. "
        "A tíz eredeti mockup pályanév szerint a projektben szerepel; "
        "a további kilenc pálya saját biome-jának kidolgozása későbbi feladat. "
        "Telefonos elfogadás még szükséges.\n\n"
        f"Commit: {os.environ['GITHUB_SHA']}\n"
    )
elif release_version == "0.2.1":
    notes = (
        "# 0.2.1 – javított Várudvar-generátor és nehézség\n\n"
        "A kötelező pályarészek és checkpointok helyfoglalása, a mini-boss biztonságos "
        "felvezetése és az egységes nehézségi profil bekötése javítva. "
        "Az elit bónuszok aktívak, az új checkpoint egyszer gyógyít, a híd ugrástávja "
        "és középső landolója oldalnézetben is eltér a három nehézségen.\n\n"
        "A CI 1920 külön pályaterv-seedet és az első pálya mindhárom teljes "
        "útvonalát valódi játékosfizikával ellenőrzi. A kilenc további mockup "
        "saját környezetének és szegmenskészletének megépítése későbbi feladat. "
        "A hosszú Várudvar végleges grafikája és telefonos ellenőrzése még hátravan.\n\n"
        f"Commit: {os.environ['GITHUB_SHA']}\n"
    )
elif release_version == "0.2.0":
    notes = (
        "# 0.2.0 – generátor-alapú hosszú Várudvar\n\n"
        "Az első pálya már az új Godot generator rebuild runtime-ot használja. "
        "A Várudvar nehézségtől és seedtől függően 700–800 méter közötti, "
        "mockup-alapú signature szegmensekkel, checkpointokkal, valós résekkel, "
        "difficulty-aware geometriával és szabályvezérelt szegmenssorrenddel.\n\n"
        "A generátor kötelező recovery szabályokat alkalmaz gap, bridge, hazard, "
        "checkpoint és nagy combat szakaszok körül. Easy/Normal/Hard eltérő "
        "geometriát és encounter-sűrűséget is kaphat, miközben a Várudvar biome "
        "és fő landmarkjai közösek maradnak.\n\n"
        "A 0.1.9 referencia-art nyitószakasz, karakter, harc, HUD és mobil vezérlés "
        "megmaradt. A hosszú pálya további szegmenseinek végleges PackedScene/GLB "
        "grafikai kidolgozása következő art pass.\n\n"
        f"Commit: {os.environ['GITHUB_SHA']}\n"
    )
elif release_version == "0.1.9":
    notes = (
        "# 0.1.9 – referencia-közeli oldalnézeti grafikai pass\n\n"
        "Az első pálya oldalnézeti/2.5D grafikai fejlesztésének következő ellenőrizhető buildje. "
        "A 0.1.8-as működő mintára épül, de a cél most már kifejezetten a 2026-10-01-i "
        "referenciákhoz közelebb álló várudvari összhatás.\n\n"
        "Első pass: mélyebb és változatosabb mészkő előtér, fugázott alapszerkezet, középtéri "
        "várfal/kapu, vörös-arany zászlók, sűrűbb növényzet, meleg fáklya/brazier fények, "
        "nagyobb főhős- és őr-sziluett, valamint újrahangolt meleg kulcsfény és háttér-kontraszt.\n\n"
        "A 240 m-es útvonal, lyukak, vizesárok, checkpointok, harcrendszer és mobil vezérlés "
        "változatlan. A CI a teljes első pályát, a karakterriget, a mobil HUD-ot, a harcot és "
        "a screenshot-generálást ellenőrzi.\n\n"
        "A készülékes Android Mobile/Vulkan vizuális ellenőrzés továbbra is szükséges. "
        "A referencia-képek szerepe és a további Pass A–F lépések a repository dokumentációjában rögzítve vannak.\n\n"
        f"Commit: {os.environ['GITHUB_SHA']}\n"
    )
else:
    notes = (
        f"# {release_version} – Reverse Platformer preview\n\n"
        "CI által ellenőrzött fejlesztői build és forráscsomag.\n\n"
        f"Commit: {os.environ['GITHUB_SHA']}\n"
    )

(out / "RELEASE_NOTES.md").write_text(notes, encoding="utf-8")
print("DELIVERY_OK", version_name, checksum)
