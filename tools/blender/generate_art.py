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



def lion_statue(root, side, pale, shadow, trim):
    """Recognizable stylized seated heraldic lion, low-poly and original."""
    x = side * 5.45
    y = -1.65
    plinth = cube("LionPlinth", (x, y, 0.41), (1.65, 1.68, 0.82), pale, root, 0.045)
    cube("PlinthCarving", (x, y - 0.83, 0.47), (1.47, 0.075, 0.12), trim, root, 0.018)
    sphere("LionHaunches", (x, y + 0.16, 1.30), (0.58, 0.73, 0.51), pale, root, 14, 8)
    sphere("LionChest", (x, y - 0.28, 1.78), (0.52, 0.44, 0.73), pale, root, 14, 8)
    sphere("LionMane", (x, y - 0.56, 2.23), (0.56, 0.38, 0.61), shadow, root, 14, 8)
    sphere("LionFace", (x, y - 0.83, 2.27), (0.37, 0.30, 0.40), pale, root, 14, 8)
    sphere("LionMuzzle", (x, y - 1.06, 2.08), (0.25, 0.23, 0.18), pale, root, 12, 6)
    sphere("LionNose", (x, y - 1.255, 2.17), (0.10, 0.07, 0.075), shadow, root, 10, 6)
    for d in (-1, 1):
        sphere("LionEar", (x + d*0.36, y - 0.74, 2.55), (0.16, 0.17, 0.21), pale, root, 10, 6)
        sphere("LionEye", (x + d*0.15, y - 1.085, 2.31), (0.045, 0.04, 0.045), shadow, root, 8, 4)
        cube("LionPaw", (x + d*0.33, y - 0.82, 1.08), (0.39, 0.51, 0.42), pale, root, 0.09)
        for claw in (-0.10, 0.0, 0.10):
            sphere("LionClaw", (x + d*0.33 + claw, y - 1.09, 0.91),
                   (0.075, 0.12, 0.065), trim, root, 8, 4)
    for i in range(8):
        angle = 2.0*math.pi*i/8
        cone_obj = cone("LionManeLock", (x + math.cos(angle)*0.44, y - 0.50,
                        2.25 + math.sin(angle)*0.45), 0.13, 0.30, pale, root, 8)
        cone_obj.rotation_euler[1] = 0.30*math.cos(angle)
    tail = sphere("LionTail", (x + side*0.57, y+0.55, 1.58),
                  (0.14, 0.19, 0.49), shadow, root, 10, 6)
    tail.rotation_euler[1] = side*0.6


def stone_albedo(name, base, folder, seed):
    """Create a low-memory tileable warm limestone texture (original artwork)."""
    import numpy as np
    folder.mkdir(parents=True, exist_ok=True)
    n = 512
    random = np.random.default_rng(seed)
    small = random.random((32, 32)).astype(np.float32)
    coarse = np.repeat(np.repeat(small, 16, axis=0), 16, axis=1)
    grain = random.normal(0, 0.025, (n, n)).astype(np.float32)
    coarse = (coarse + np.roll(coarse, 3, axis=0) +
              np.roll(coarse, 3, axis=1) + np.roll(coarse, -3, axis=0) +
              np.roll(coarse, -3, axis=1)) / 5.0
    texture = (coarse - 0.5) * 0.17 + grain
    yy, xx = np.indices((n, n), dtype=np.float32)
    veining = np.sin(xx * 0.039 + yy * 0.012 + 0.26 *
                     np.sin(yy * 0.024 + seed)) * 0.015
    rgba = np.ones((n, n, 4), dtype=np.float32)
    for c, value in enumerate(base):
        rgba[:, :, c] = np.clip(value + texture + veining, 0.10, 0.81)
    image = bpy.data.images.new(name, n, n, alpha=True)
    image.pixels.foreach_set(rgba.ravel())
    image.filepath_raw = str((folder / (name + ".png")).resolve())
    image.file_format = "PNG"
    image.save()
    image.pack()
    return image


def irregular_stone(name, x, y, half_x, half_y, mat, parent, rng):
    """Chamfered octagonal paver with individually sculpted, uneven outline.

    Narrow dark gaps expose the continuous warm mortar instead of green floor.
    """
    inset = rng.uniform(0.08, 0.20)
    profile = [(-half_x+inset,-half_y), (half_x-inset,-half_y),
               (half_x,-half_y+inset), (half_x,half_y-inset),
               (half_x-inset,half_y), (-half_x+inset,half_y),
               (-half_x,half_y-inset),(-half_x,-half_y+inset)]
    offsets = [(dx+rng.uniform(-0.04, 0.04),
                dy+rng.uniform(-0.04, 0.04)) for dx,dy in profile]
    top = [(x+dx,y+dy,rng.uniform(0.025,0.043)) for dx,dy in offsets]
    bottom = [(vx,vy,-0.05) for vx,vy,_ in top]
    vertices = top + bottom
    faces = [tuple(range(8)),tuple(reversed(range(8,16)))]
    for i in range(8):
        j = (i+1)%8
        faces.append((i,i+8,j+8,j))
    data = bpy.data.meshes.new(name+"Mesh")
    data.from_pydata(vertices,[],faces)
    data.update()
    obj = bpy.data.objects.new(name,data)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.data.materials.append(mat)
    uv = data.uv_layers.new(name="PavestoneUV")
    for polygon in data.polygons:
        for loop_index in polygon.loop_indices:
            vertex = data.vertices[data.loops[loop_index].vertex_index].co
            # Full texture used independently on each individual stone.
            uv.data[loop_index].uv = (
                0.02 + 0.96 * (vertex.x-x+half_x)/(half_x*2),
                0.02 + 0.96 * (vertex.y-y+half_y)/(half_y*2))
    return obj


def courtyard_environment(output, source):
    """Stage-one scenic set. Visual only: never alters tested collision geometry.

    Blender Y is reversed Godot Z during glTF conversion. Scenic structures
    stand outside the stage's existing outer boundaries, not on the playable lane.
    """
    import random
    clear_scene()
    rng = random.Random(1008)
    stone = material("Courtyard limestone", (0.38, 0.355, 0.32), roughness=0.94)
    warm = material("Courtyard honey stone", (0.48, 0.40, 0.33), roughness=0.90)
    roof = material("Courtyard slate roofs", (0.27, 0.32, 0.40), roughness=0.83)
    wood = material("Courtyard charred wood", (0.24, 0.13, 0.075), roughness=0.89)
    grass = material("Courtyard summer grass", (0.22, 0.34, 0.19), roughness=1.0)
    leaves = material("Cypress leaves", (0.14, 0.24, 0.15), roughness=1.0)
    banner = material("Red royal banners", (0.47, 0.038, 0.064), roughness=0.88)
    fire = material("Amber flame", (1.0, 0.36, 0.04), glow=2.2)
    blue = material("Fountain water", (0.29, 0.68, 0.72), roughness=0.15)
    # Four shared albedo textures are exported with the GLB and used by all
    # stones. Natural grain and chamfered outlines replace floating white tiles.
    palettes = [(0.32, 0.29, 0.25), (0.38, 0.33, 0.28),
                (0.28, 0.28, 0.28), (0.44, 0.37, 0.30)]
    paving = []
    for i, rgb in enumerate(palettes):
        mat = material("Weathered limestone %d" % i, rgb, roughness=0.91)
        tex = stone_albedo("pavestone_%d" % i, rgb, source/"textures", 100+i)
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        image_node = mat.node_tree.nodes.new("ShaderNodeTexImage")
        image_node.image = tex
        mat.node_tree.links.new(image_node.outputs["Color"], bsdf.inputs["Base Color"])
        paving.append(mat)
    root = empty("CourtyardEnvironment")

    # A single continuous mortar bed means the seams cannot expose bright
    # green floor; existing collision remains unchanged under decorative mesh.
    mortar = material("Dark warm masonry joints", (0.17, 0.16, 0.145), roughness=0.99)
    # Put the joint bed 15 mm above the stage floor; the old 3 mm offset
    # z-fought against the floor and exposed glaring white seams.
    cube("PavementUnderlay", (0,-15.1,-0.030), (19.2,60.2,0.09),
         mortar,root,0.0)
    # Material-batched irregular limestone pavers; 270 stones cover the playable width, four draw groups.
    for row in range(30):
        z = -13.0 + row*1.92
        for col in range(9):
            x = (col-4)*2.08 + (0.20 if row%2 else -0.20)
            w = rng.uniform(0.98,1.02)
            h = rng.uniform(0.92,0.94)
            mat = paving[rng.randrange(len(paving))]
            irregular_stone("PavementTile",x,-z,w,h,mat,root,rng)

    # Decorative side strips exist beyond the invisible play-boundary walls.
    for side in (-1,1):
        x = side*12.5
        cube("GardenStrip", (side*13.6, -15, -0.22), (7.0, 69.0, 0.43), grass, root, 0.0)
        for z in range(-9,43,8):
            y=-float(z)
            cylinder("CypressTrunk",(side*13.7, y, 1.65),0.25,3.3,wood,root)
            # Contoured, overlapping tree crowns instead of rigid triangles.
            for h,sc in [(2.95,(0.94,0.95,1.35)),(3.88,(0.83,0.80,1.36)),
                         (4.80,(0.57,0.59,1.12))]:
                sphere("CypressCrown",(side*13.7,y,h),sc,leaves,root,12,8)
            cube("PerimeterStone", (side*10.9, y, 0.48), (0.92, 4.2, 0.95), stone,root,0.06)
            for n in (-1.5,-0.5,0.5,1.5):
                cube("ParapetTooth", (side*10.9, y+n, 1.12),
                    (1.06,0.55,0.37),warm,root,0.035)
        for z in (0,24,37):
            y = -float(z)
            cube("BarrelStave", (side*11.75,y,0.55),(0.78,0.78,1.1),wood,root,0.10)
            for h in (0.18,0.85):
                cube("BarrelIronHoop",(side*11.75,y-0.40,h),(0.91,0.06,0.10),roof,root,0.02)
        for z in (8,32):
            y=-float(z)
            cylinder("Braziers", (side*10.6,y,0.84),0.38,1.65,roof,root)
            sphere("FireBowl",(side*10.6,y,1.78),(0.56,0.5,0.24),wood,root)
            cone("TorchFlame",(side*10.6,y,2.19),0.27,0.72,fire,root)
            cube("RedStandards",(side*11.2,y-1.9,3.12),
                (0.06,0.05,5.2),wood,root,0.0)
            cube("Flag",(side*10.6,y-1.9,4.6),
                (1.12,0.08,1.25),banner,root,0.012)

    # Fountain to the right of the action, completely outside the combat corridor.
    fx,fy=15.6,-12.0
    cylinder("FountainBase",(fx,fy,0.22),2.2,0.43,stone,root,24)
    cylinder("FountainBasin",(fx,fy,0.66),1.88,0.42,warm,root,24)
    cylinder("FountainWater",(fx,fy,0.89),1.66,0.065,blue,root,24)
    cylinder("FountainColumn",(fx,fy,1.5),0.29,1.5,stone,root)
    cylinder("FountainDish",(fx,fy,2.21),0.98,0.24,warm,root,24)
    cylinder("UpperWater",(fx,fy,2.35),0.77,0.06,blue,root,24)
    sphere("FountainFinial",(fx,fy,2.66),(0.35,0.35,0.42),warm,root)
    # Batch stone tiles by material: only four paved-road meshes reach Godot.
    for batch_index, mat in enumerate(paving):
        tiles = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"
                 and obj.name.startswith("PavementTile")
                 and obj.material_slots and obj.material_slots[0].material == mat]
        if not tiles:
            continue
        bpy.ops.object.select_all(action="DESELECT")
        for tile in tiles:
            tile.select_set(True)
        bpy.context.view_layer.objects.active = tiles[0]
        bpy.ops.object.join()
        tiles[0].name = "PavementBatch%d" % batch_index
    save_asset("courtyard_environment",output,source)

def gate(output, source):
    clear_scene()
    shadow = material("Deep gate recess", (0.13, 0.15, 0.18), roughness=0.91)
    stone = material("Aged stone", (0.37, 0.43, 0.48), 0, 0.84)
    light = material("Stone edges", (0.53, 0.58, 0.6), 0, 0.8)
    gold = material("Gate gilt", (0.60, 0.39, 0.16), 0.64, 0.39)
    crimson = material("Siege banners", (0.49, 0.025, 0.08), 0, 0.82)
    flame = material("Torch flame", (1.0, 0.42, 0.055), 0, 0.4, glow=2.0)
    # One original UV-textured limestone atlas softens the old flat castle.
    castle_texture = stone_albedo("castle_limestone",(0.35,0.34,0.31),
                                   source/"textures",188)
    castle_node = stone.node_tree.nodes.new("ShaderNodeTexImage")
    castle_node.image = castle_texture
    stone.node_tree.links.new(castle_node.outputs["Color"],
                             stone.node_tree.nodes.get("Principled BSDF").inputs["Base Color"])
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
    # Large towers, heraldic lions and banners bring the first-stage gate
    # much closer to the target key art while retaining the open exit.
    for side in (-1,1):
        x=side*7.4
        cylinder("FlankingTower",(x,1.25,4.0),1.58,8.0,stone,root,20)
        cylinder("TowerCornice",(x,1.25,8.15),1.83,0.35,light,root,20)
        cylinder("RoofBase",(x,1.25,8.42),1.63,0.28,gold,root,20)
        cone("SlateTurretRoof",(x,1.25,9.54),1.82,2.24,
             material("Slate tower roofs",(0.26,0.32,0.41),roughness=0.82),
             root,20)
        cone("Spire",(x,1.25,10.91),0.16,0.74,gold,root)
        for level in (2.2,4.3,6.3):
            cube("ArrowLoop",(x, -0.355, level),(.22,.065,.9),shadow,root,0.018)
        cube("TowerBanner",(x, -0.41,5.42),(.75,.055,2.45),crimson,root,0.02)
        cube("TowerBannerTrim",(x,-0.46,4.24),(.80,.055,.16),gold,root,0.01)
        lion_statue(root,side,light,stone,gold)
    for x in (-1.85, 1.85):
        for z in (1.25,2.38,3.45):
            cube("GateStoneBand",(x,-0.64,z),(.92,.04,.07),light,root,0.0)
    for side in (-1,1):
        cube("OuterCurtainWall",(side*9.2,1.75,2.55),(2.25,1.32,5.1),stone,root,.06)
        cube("WallCoping",(side*9.2,1.75,5.18),(2.44,1.47,.38),light,root,.045)
        for offset in (-0.62,0.62):
            cube("WallMerlon",(side*9.2+offset,1.75,5.58),(.64,1.30,.57),light,root,.045)
    save_asset("fortress_gate", output, source)


if __name__ == "__main__":
    args = options()
    output = Path(args.output).resolve()
    source = Path(args.source).resolve()
    output.mkdir(parents=True, exist_ok=True)
    source.mkdir(parents=True, exist_ok=True)
    # Keep the editable .blend archives for GitHub artifacts, not Godot imports.
    (source / ".gdignore").touch()
    villain(output, source)
    gate(output, source)
    courtyard_environment(output, source)
    print("ART GENERATION COMPLETE", flush=True)
