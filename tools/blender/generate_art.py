"""Generate original mobile-ready villain and fortress gate in headless Blender.

Usage:
    blender -b --python tools/blender/generate_art.py -- --output assets/models

Exports .glb files for Godot and editable .blend sources. No Nintendo assets.
The GLB node names LegLeft, LegRight, WeaponPivot and Chest are part of the
Godot integration contract; preserve them while refining the Blender models.
"""
import argparse
import math
import sys
from pathlib import Path

import bpy


def options():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="assets/models")
    parser.add_argument("--source", default="build/blender")
    return parser.parse_args(argv)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def material(name, rgb, metal=0.0, roughness=0.55, glow=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1.0)
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*rgb, 1.0)
    principled.inputs["Metallic"].default_value = metal
    principled.inputs["Roughness"].default_value = roughness
    if glow:
        emission = principled.inputs.get("Emission Color") or principled.inputs.get("Emission")
        strength = principled.inputs.get("Emission Strength")
        if emission:
            emission.default_value = (*rgb, 1.0)
        if strength:
            strength.default_value = glow
    return mat


def empty(name, at=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.empty_display_size = 0.08
    if parent:
        obj.parent = parent
    obj.location = at
    return obj


def bevel(obj, amount=0.025, segments=2):
    if amount <= 0:
        return obj
    modifier = obj.modifiers.new("Soft light-catching edges", "BEVEL")
    modifier.width = amount
    modifier.segments = segments
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj


def cube(name, at, dims, mat, parent=None, bevel_size=0.03):
    bpy.ops.mesh.primitive_cube_add(size=1)
    obj = bpy.context.object
    obj.name = name
    if parent:
        obj.parent = parent
    obj.location = at
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bevel(obj, min(bevel_size, min(dims) * 0.22))
    return obj


def sphere(name, at, scale, mat, parent=None, segments=16, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings)
    obj = bpy.context.object
    obj.name = name
    if parent:
        obj.parent = parent
    obj.location = at
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj


def cone(name, at, radius, depth, mat, parent=None, vertices=10):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=0, depth=depth)
    obj = bpy.context.object
    obj.name = name
    if parent:
        obj.parent = parent
    obj.location = at
    obj.data.materials.append(mat)
    return obj


def cylinder(name, at, radius, depth, mat, parent=None, vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth)
    obj = bpy.context.object
    obj.name = name
    if parent:
        obj.parent = parent
    obj.location = at
    obj.data.materials.append(mat)
    bevel(obj, 0.025)
    return obj


def save_asset(name, output, source):
    bpy.ops.wm.save_as_mainfile(filepath=str(source / (name + ".blend")))
    bpy.ops.export_scene.gltf(
        filepath=str(output / (name + ".glb")),
        export_format="GLB",
        export_apply=True,
        use_selection=False,
    )
    size = (output / (name + ".glb")).stat().st_size
    if size < 1024:
        raise RuntimeError("Exported GLB is suspiciously small: " + name)
    print("GENERATED", name, size, "bytes", flush=True)


def villain(output, source):
    clear_scene()
    dark = material("Obsidian black armor", (0.043, 0.047, 0.075), 0.85, 0.31)
    steel = material("Cold forged edge", (0.32, 0.39, 0.48), 0.86, 0.23)
    gold = material("Worn gold inlay", (0.67, 0.43, 0.14), 0.72, 0.32)
    red = material("Imperial crimson", (0.38, 0.028, 0.06), 0.16, 0.7)
    eyes = material("Infernal eyes", (1.0, 0.23, 0.035), 0, 0.4, glow=2.4)
    root = empty("VillainRig")

    cube("Chest", (0, 0.0, 0.20), (0.83, 0.5, 0.77), dark, root, 0.095)
    cube("Breastplate", (0, -0.277, 0.23), (0.69, 0.085, 0.64), steel, root, 0.07)
    cube("GoldCenterRib", (0, -0.334, 0.24), (0.045, 0.023, 0.52), gold, root, 0.01)
    for side in (-1, 1):
        plate = cube("ChevronPlate", (side * 0.17, -0.337, 0.3), (0.30, 0.035, 0.052), gold, root, 0.01)
        plate.rotation_euler[1] = side * 0.4
        sphere("Pauldrons", (side * 0.49, 0, 0.47), (0.31, 0.29, 0.21), steel, root)
        cone("ShoulderSpike", (side * 0.59, 0, 0.76), 0.12, 0.45, gold, root)
        cube("UpperArm", (side * 0.54, 0.0, 0.11), (0.22, 0.27, 0.48), dark, root, 0.06)
        cube("Gauntlet", (side * 0.55, -0.06, -0.15), (0.28, 0.33, 0.28), steel, root, 0.045)
        cube("HelmetSideWing", (side * 0.34, 0.0, 0.95), (0.08, 0.48, 0.23), dark, root)
        horn = cone("CrownHorn", (side * 0.24, 0, 1.37), 0.115, 0.47, steel, root)
        horn.rotation_euler[1] = side * 0.28
        cube("BurningEye", (side * 0.15, -0.36, 0.99), (0.19, 0.035, 0.052), eyes, root, 0.01)

    cube("Waist", (0, 0, -0.21), (0.7, 0.43, 0.22), dark, root)
    cube("Belt", (0, -0.02, -0.26), (0.79, 0.49, 0.095), gold, root, 0.01)
    cube("BeltSkull", (0, -0.29, -0.24), (0.22, 0.06, 0.18), steel, root)
    sphere("Helm", (0, 0.015, 0.99), (0.36, 0.37, 0.38), dark, root)
    cube("Visor", (0, -0.335, 1.05), (0.56, 0.085, 0.16), steel, root, 0.035)
    cube("FaceGuard", (0, -0.395, 0.83), (0.18, 0.08, 0.34), dark, root, 0.03)
    cube("Crest", (0, 0.04, 1.32), (0.09, 0.41, 0.13), gold, root, 0.025)

    for side, name in ((-1, "LegLeft"), (1, "LegRight")):
        pivot = empty(name, (side * 0.23, 0, -0.34), root)
        cube("Thigh" + name, (0, 0, -0.12), (0.30, 0.35, 0.39), dark, pivot, 0.06)
        cube("Greave" + name, (0, -0.045, -0.4), (0.32, 0.38, 0.31), steel, pivot, 0.06)
        cube("Boot" + name, (0, -0.11, -0.56), (0.36, 0.53, 0.16), dark, pivot, 0.045)
        cube("KneeGold" + name, (0, -0.23, -0.28), (0.25, 0.06, 0.09), gold, pivot, 0.018)

    weapon = empty("WeaponPivot", (0.63, -0.17, 0.18), root)
    cube("Blade", (0, -0.85, 0.03), (0.13, 1.45, 0.10), steel, weapon, 0.022)
    cone_tip = cone("BladeTip", (0, -1.6, 0.03), 0.085, 0.28, steel, weapon)
    cone_tip.rotation_euler[0] = math.pi * 0.5
    cube("Crossguard", (0, -0.12, 0.03), (0.72, 0.14, 0.11), gold, weapon, 0.018)
    cube("Grip", (0, 0.17, 0.03), (0.11, 0.52, 0.10), red, weapon, 0.015)
    sphere("Pommel", (0, 0.47, 0.03), (0.12, 0.12, 0.12), gold, weapon)
    cube("LeftShield", (-0.84, -0.17, 0.12), (0.59, 0.22, 0.76), dark, root, 0.08)
    cube("ShieldRim", (-0.84, -0.30, 0.12), (0.46, 0.04, 0.6), gold, root, 0.035)
    cube("ShieldMark", (-0.84, -0.336, 0.13), (0.09, 0.035, 0.41), red, root, 0.012)
    # The cape is a lightweight animated Godot shader; only the clasp lives in GLB.
    sphere("CapeClasp", (0, 0.25, 0.60), (0.22, 0.10, 0.09), gold, root)
    save_asset("villain_knight", output, source)


def gate(output, source):
    clear_scene()
    stone = material("Aged stone", (0.37, 0.43, 0.48), 0, 0.84)
    light = material("Stone edges", (0.53, 0.58, 0.6), 0, 0.8)
    gold = material("Gate gilt", (0.60, 0.39, 0.16), 0.64, 0.39)
    crimson = material("Siege banners", (0.49, 0.025, 0.08), 0, 0.82)
    flame = material("Torch flame", (1.0, 0.42, 0.055), 0, 0.4, glow=2.0)
    root = empty("FortressGate")
    for side in (-1, 1):
        x = side * 2.7
        cube("GatePillar", (x, 0, 2.25), (1.1, 1.2, 4.5), stone, root, 0.075)
        cube("GatePillarFoot", (x, 0, 0.30), (1.4, 1.45, 0.58), light, root)
        cube("GatePillarCap", (x, 0, 4.5), (1.38, 1.5, 0.4), light, root)
        for z in (1.15, 2.3, 3.45):
            cube("MortarAccent", (x, -0.63, z), (1.18, 0.06, 0.055), light, root, 0.0)
        cube("Banner", (side * 3.37, -0.25, 3.47), (0.51, 0.10, 1.65), crimson, root, 0.015)
        cube("BannerTrim", (side * 3.37, -0.34, 2.8), (0.53, 0.04, 0.11), gold, root)
        cylinder("Torch", (side * 3.42, -0.82, 2.0), 0.09, 0.52, gold, root)
        cone("TorchFlame", (side * 3.42, -0.82, 2.4), 0.13, 0.54, flame, root)
    # Raised arch: the entrance remains fully open to the existing Goal trigger.
    for n in range(9):
        angle = math.pi * n / 8
        x = 2.15 * math.cos(angle)
        z = 3.55 + 1.45 * math.sin(angle)
        stone_piece = cube("ArchVoussoir", (x, 0, z), (0.67, 1.26, 0.68), light if n % 2 else stone, root, 0.045)
        stone_piece.rotation_euler[1] = angle - math.pi * 0.5
    cube("Battlements", (0, 0, 5.48), (6.8, 1.52, 0.85), stone, root, 0.08)
    for x in (-2.65, -1.3, 0, 1.3, 2.65):
        cube("Merlon", (x, 0, 6.03), (0.75, 1.6, 0.9), light, root, 0.04)
    cube("GoldKeystone", (0, -0.68, 5.14), (0.38, 0.11, 0.51), gold, root, 0.04)
    save_asset("fortress_gate", output, source)


if __name__ == "__main__":
    args = options()
    output = Path(args.output).resolve()
    source = Path(args.source).resolve()
    output.mkdir(parents=True, exist_ok=True)
    source.mkdir(parents=True, exist_ok=True)
    villain(output, source)
    gate(output, source)
    print("ART GENERATION COMPLETE", flush=True)
