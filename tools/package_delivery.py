"""Export the tested working tree, source artwork, plans and generated runtime."""
import hashlib, json, os, shutil, subprocess, zipfile
from pathlib import Path
root = Path(__file__).resolve().parents[1]
out = root / "delivery"
out.mkdir(exist_ok=True)
tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=root).decode().split("\0")
paths = {p for p in tracked if p and (root/p).is_file()}
paths.add("art/source/world/runtime_optimization.json")
paths.update(str(p.relative_to(root)) for p in (root/"assets/models").glob("courtyard_environment_part*.bin"))
with zipfile.ZipFile(out/"ReversePlatformer-0.1.8-project.zip", "w", zipfile.ZIP_DEFLATED) as archive:
    for name in sorted(paths):
        if (root/name).is_file():
            archive.write(root/name, name)
    for p in sorted((root/"previews").glob("*.png")):
        archive.write(p, "art/validation/0.1.8/"+p.name)
    archive.writestr("BUILD_INFO.json", json.dumps({
        "version":"0.1.8-art-sample", "commit":os.environ["GITHUB_SHA"],
        "run":os.environ["GITHUB_RUN_ID"],
        "validation":"All preceding CI tests and screenshot generation completed successfully",
        "phone_validation":"Pending user device testing",
        "original_mockups":"1830.png and 1831.png not yet available for byte-for-byte export"
    }, indent=2))
apk = out/"ReversePlatformer-0.1.8-teszt.apk"
shutil.copyfile(root/"artifact/ReversePlatformer-debug.apk", apk)
checksum = hashlib.sha256(apk.read_bytes()).hexdigest()
(out/(apk.name+".sha256")).write_text(checksum+"  "+apk.name+"\n")
for name in ["sample_idle_16_9.png","sample_attack.png","sample_block.png","sample_run.png","sample_physical_jump.png","sample_wide.png"]:
    shutil.copyfile(root/"previews"/name, out/name)
(out/"RELEASE_NOTES.md").write_text(
    "# 0.1.8 – játszható grafikai mintaszakasz\n\n"
    "Egy telepíthető APK; 25 m-es mintaszakasz a megőrzött 240 m-es pálya elején. "
    "Mészkőburkolat, tagolt oldalfal, díszkert és meglévő Blender-kellékek. "
    "A főhős eredeti rigje és öt animációja, részletes kék/arany őr, új piros életerősáv "
    "és körgombok. Képarányhoz és biztonságos területhez igazodó UI.\n\n"
    "A ZIP a teljes forrásprojektet, meglévő Blender-forrásokat, új shader/SVG/grafikai "
    "előállító kódot és a tényleges Godot-játékfotókat tartalmazza.\n\n"
    "Automatizált ellenőrzések és asztali Compatibility render készült. "
    "Az Android Mobile/Vulkan megjelenés, fizikai telefonos többujjas vezérlés és FPS "
    "még készüléktesztet igényel. A grafika továbbra sem éri el a referencia kézzel kidolgozott "
    "anyag- és animációminőségét.\n\n"
    "A referencia-csatolmányok képpontjai a munkamenetben láthatók, de eredeti fájlbájtjaik "
    "nem exportálhatók az elérhető eszközökkel; 1830.png nem volt vizuálisan megnyitható.\n\n"
    "Commit: "+os.environ["GITHUB_SHA"]+"\n", encoding="utf-8"
)
print("DELIVERY_OK", checksum)
