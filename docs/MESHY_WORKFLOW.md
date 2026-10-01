# Meshy – előkészített újratextúrázás

A plugin-keresés nem talált Meshy plugint ebben a munkamenetben. Nincs
hozzákapcsolt Meshy-fiók/API-kulcs. Meshy generálás még nem futott.
A jelenlegi AI mészkő OpenAI beépített képgenerálásából származik.

Az offline előkészítő `tools/meshy_retexture.py` a meglévő CC0 modellek
geometriáját, material slotjait és UV-it megtartva önálló GLB-t csomagol.
Két kezdő modul: kőblokk és fugázott fal. A kiadás melléklete a
`Meshy-Varudvar-kit.zip`: stone.glb, wall.glb és limestone-reference.png.
Ezek a Meshy webes AI Texturing felületére is feltölthetők.

API út: Meshy-fiók Developer Platform / API Keys oldala, API-kreditkeretes
kulcs, majd a kulcs környezeti változóként a fejlesztői futtatókörnyezetben.
Kulcs nem kerül az APK-ba, repóba vagy kérésfájlba. Előfizetést nem vásárolunk.
A submit kreditfelhasználással jár; a prepare és kit teljesen offline.

```sh
python3 tools/meshy_retexture.py prepare --asset stone --out-dir /tmp/meshy-stone
# A MESHY_API_KEY környezeti változó biztonságos beállítása után:
python3 tools/meshy_retexture.py submit --request /tmp/meshy-stone/stone-request.json --task-file /tmp/meshy-stone/task.json
python3 tools/meshy_retexture.py status --task-id TASK_ID
python3 tools/meshy_retexture.py download --task-id TASK_ID --out-dir /tmp/meshy-stone/result
```

A request meshy-6, 2k, PBR, eredeti UV-megtartás, lighting removal és GLB
kimenetet kér. Az API fő végpontja `POST /openapi/v1/retexture`.
A generálás nincs a játékba beépítve; fejlesztéskor készített modelleket kap.
Letöltés után ellenőrizni kell a fugákat, UV-varratokat és material slotokat;
mobilra méretezés, collision-egyezés és Godot-képellenőrzés után válhat
az assetkit új forrásává. A script nem cserél automatikusan játékbeli modelleket.

Hivatalos dokumentáció, ellenőrizve 2026-10-01:
- https://docs.meshy.ai/en/api/authentication
- https://docs.meshy.ai/en/api/retexture
- https://docs.meshy.ai/en/webapp/guides/3d-model/ai-texturing
