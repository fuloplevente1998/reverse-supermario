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
with zipfile.ZipFile(out/"ReversePlatformer-0.1.7-project.zip", "w", zipfile.ZIP_DEFLATED) as archive:
    for name in sorted(paths):
        if (root/name).is_file():
            archive.write(root/name, name)
    for p in sorted((root/"previews").glob("*.png")):
        archive.write(p, "art/validation/0.1.7/"+p.name)
    archive.writestr("BUILD_INFO.json", json.dumps({
        "version":"0.1.7-side", "commit":os.environ["GITHUB_SHA"],
        "run":os.environ["GITHUB_RUN_ID"],
        "validation":"All preceding CI tests and screenshot generation completed successfully",
        "phone_validation":"Pending user device testing",
        "original_mockups":"1830.png and 1831.png not yet available for byte-for-byte export"
    }, indent=2))
apk = out/"ReversePlatformer-0.1.7-teszt.apk"
shutil.copyfile(root/"artifact/ReversePlatformer-debug.apk", apk)
checksum = hashlib.sha256(apk.read_bytes()).hexdigest()
(out/(apk.name+".sha256")).write_text(checksum+"  "+apk.name+"\n")
for name in ["side_course_004.png","side_course_101.png"]:
    shutil.copyfile(root/"previews"/name, out/name)
(out/"RELEASE_NOTES.md").write_text(
    "# 0.1.7 – első oldalnézeti pálya\n\n"
    "Egyetlen telepíthető APK. 240 m-es első pálya, statikus várháttér, dombok, "
    "lejtők, völgyek, valódi rések, vizes árok és három ellenőrzőpont.\n\n"
    "A projekt ZIP tartalmazza a forráskódot, terveket, Blender-forrásokat, "
    "játékmodelleket, textúrákat, háttérképet és a CI-ben készített játékfotókat. "
    "A docs/PROJECT_HANDOFF.md írja le a döntéseket és a folytatást.\n\n"
    "Automatizált tesztek sikeresek; telefonos próba még szükséges. "
    "A két eredeti referencia-PNG külön exportja hozzáférés hiányában még hátra van.\n\n"
    "Commit: "+os.environ["GITHUB_SHA"]+"\n"
)
print("DELIVERY_OK", checksum)
