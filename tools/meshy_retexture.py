"""Prepare self-contained courtyard models; optionally call Meshy's Retexture API.

Preparation is offline. Only the explicit submit command consumes API credits.
MESHY_API_KEY is read from the process environment and never written to files.
"""
import argparse
import base64
import json
import mimetypes
import os
from pathlib import Path
import struct
import urllib.error
import urllib.parse
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
API = "https://api.meshy.ai/openapi/v1/retexture"


def pack_glb(path):
    """Embed existing buffers/images without changing geometry or atlas UVs."""
    source = json.loads(path.read_text())
    binary = bytearray()
    offsets = []

    def append(data):
        binary.extend(b"\0" * ((-len(binary)) % 4))
        offset = len(binary)
        binary.extend(data)
        return offset

    for buffer in source["buffers"]:
        uri = buffer["uri"]
        data = base64.b64decode(uri.split(",", 1)[1]) if uri.startswith("data:") else (path.parent / uri).read_bytes()
        offsets.append(append(data))
    for view in source.get("bufferViews", []):
        view["byteOffset"] = view.get("byteOffset", 0) + offsets[view.get("buffer", 0)]
        view["buffer"] = 0
    for image in source.get("images", []):
        if "uri" not in image:
            continue
        uri = image.pop("uri")
        if uri.startswith("data:"):
            header, encoded = uri.split(",", 1)
            data = base64.b64decode(encoded)
            mime = header.split(";", 1)[0][5:]
        else:
            data = (path.parent / uri).read_bytes()
            mime = mimetypes.guess_type(uri)[0]
        source.setdefault("bufferViews", []).append({"buffer": 0, "byteOffset": append(data), "byteLength": len(data)})
        image["bufferView"] = len(source["bufferViews"]) - 1
        image["mimeType"] = image.get("mimeType", mime)
    source["buffers"] = [{"byteLength": len(binary)}]
    text = json.dumps(source, separators=(",", ":")).encode()
    text += b" " * ((-len(text)) % 4)
    binary.extend(b"\0" * ((-len(binary)) % 4))
    size = 12 + 8 + len(text) + 8 + len(binary)
    return (struct.pack("<III", 0x46546C67, 2, size) + struct.pack("<II", len(text), 0x4E4F534A) + text
            + struct.pack("<II", len(binary), 0x004E4942) + binary)


def data_uri(data, mime):
    return "data:" + mime + ";base64," + base64.b64encode(data).decode()


def request_json(url, payload=None):
    key = os.environ.get("MESHY_API_KEY")
    if not key:
        raise ValueError("MESHY_API_KEY is required for API calls; offline prepare needs no key.")
    headers = {"Authorization": "Bearer " + key, "Content-Type": "application/json"}
    data = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(request, timeout=45) as response:
        return json.load(response)


def task_url(task_id):
    return API + "/" + urllib.parse.quote(task_id, safe="")


def prepare(args):
    out = args.out_dir
    out.mkdir(parents=True, exist_ok=True)
    reference = args.reference
    image = reference.read_bytes()
    mime = mimetypes.guess_type(reference.name)[0]
    if mime not in ("image/png", "image/jpeg"):
        raise ValueError("Reference must be PNG or JPEG.")
    model = pack_glb(ROOT / "assets/vendor/quaternius" / (args.asset + ".gltf"))
    (out / (args.asset + ".glb")).write_bytes(model)
    payload = {
        "model_url": data_uri(model, "application/octet-stream"),
        "image_style_url": data_uri(image, mime),
        "ai_model": "meshy-6", "enable_original_uv": True, "enable_pbr": True,
        "texture_resolution": "2k", "remove_lighting": True, "target_formats": ["glb"],
    }
    (out / (args.asset + "-request.json")).write_text(json.dumps(payload))
    print("MESHY_PREPARED", args.asset, len(model), "bytes; no API request submitted")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    p = commands.add_parser("prepare")
    p.add_argument("--asset", choices=["stone", "wall", "window", "paving", "crate", "barrel"], required=True)
    p.add_argument("--reference", type=Path, default=ROOT / "assets/materials/ai/courtyard_limestone_v1.png")
    p.add_argument("--out-dir", type=Path, required=True)
    p = commands.add_parser("submit")
    p.add_argument("--request", type=Path, required=True)
    p.add_argument("--task-file", type=Path, required=True)
    for command in ["status", "download"]:
        p = commands.add_parser(command)
        p.add_argument("--task-id", required=True)
        if command == "download": p.add_argument("--out-dir", type=Path, required=True)
    p = commands.add_parser("kit")
    p.add_argument("--zip", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == "prepare":
            prepare(args)
        elif args.command == "kit":
            args.zip.parent.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(args.zip, "w", zipfile.ZIP_DEFLATED) as archive:
                for asset in ["stone", "wall"]:
                    archive.writestr(asset + ".glb", pack_glb(ROOT / "assets/vendor/quaternius" / (asset + ".gltf")))
                archive.write(ROOT / "assets/materials/ai/courtyard_limestone_v1.png", "limestone-reference.png")
                archive.write(ROOT / "docs/MESHY_WORKFLOW.md", "README.md")
                archive.write(ROOT / "assets/vendor/quaternius/village_LICENSE.txt", "village_LICENSE.txt")
            print("MESHY_KIT_OK", args.zip)
        elif args.command == "submit":
            response = request_json(API, json.loads(args.request.read_text()))
            task_id = response["result"]
            args.task_file.parent.mkdir(parents=True, exist_ok=True)
            args.task_file.write_text(json.dumps({"task_id": task_id}, indent=2))
            print("MESHY_TASK_CREATED", task_id)
        else:
            task = request_json(task_url(args.task_id))
            print(json.dumps({k: task.get(k) for k in ["id", "status", "progress", "consumed_credits"]}))
            if args.command == "download":
                if task.get("status") != "SUCCEEDED":
                    raise ValueError("Task is not SUCCEEDED; no model downloaded.")
                urls = {"model.glb": task["model_urls"]["glb"]}
                for i, maps in enumerate(task.get("texture_urls", [])):
                    for name, url in maps.items():
                        if name in ["base_color", "metallic", "roughness", "normal", "emission"]:
                            urls[f"texture_{i}_{name}.png"] = url
                args.out_dir.mkdir(parents=True, exist_ok=True)
                for name, url in urls.items():
                    if urllib.parse.urlparse(url).scheme != "https": raise ValueError("Expected HTTPS asset URL.")
                    with urllib.request.urlopen(url, timeout=45) as response:
                        (args.out_dir / name).write_bytes(response.read())
                print("MESHY_DOWNLOADED", len(urls), "files; review before Godot import")
    except urllib.error.HTTPError as error:
        parser.exit(1, f"Meshy HTTP {error.code}; check account, credits and request settings.\n")
    except (ValueError, KeyError, OSError, urllib.error.URLError) as error:
        parser.exit(1, str(error) + "\n")


if __name__ == "__main__":
    main()
