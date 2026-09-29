"""Procedural sculpted/rigged villain for Godot 4 Mobile.

Headless use:
 blender -b --factory-startup --python tools/blender/rigged_villain.py -- \
     --output assets/models --source build/blender

Creates editable villain.blend, villain.glb (+ villain_knight.glb alias),
2048px color/ORM atlas PNGs, front/side/back turntable previews, and JSON report.
Three shared glTF materials, UV unwrapped geometry, humanoid skinned armature,
separate bone-attached sword, Idle and Run NLA animations. Original artwork only.
"""
import argparse
import json
import math
import shutil
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector


def args():
    tail = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", default="assets/models")
    ap.add_argument("--source", default="build/blender")
    return ap.parse_args(tail)


def empty(name, parent=None):
    o = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(o)
    if parent:
        o.parent = parent
    return o


def create_atlas(folder):
    """Bake predictable wear/color variation as two portable 2048 PNGs."""
    folder.mkdir(parents=True, exist_ok=True)
    size = 2048
    rng = np.random.default_rng(28)
    color = np.ones((size, size, 4), dtype=np.float32)
    orm = np.ones((size, size, 4), dtype=np.float32)
    palettes = [
        ((0.105, 0.123, 0.154), 0.37, 0.78),  # dark graphite alloy
        ((0.34, 0.022, 0.060), 0.80, 0.02),   # burgundy textile
        ((0.60, 0.385, 0.125), 0.35, 0.72),   # restrained aged gold
    ]
    for i, (base, rough, metallic) in enumerate(palettes):
        x0 = (size * i) // 3
        x1 = (size * (i + 1)) // 3
        variance = rng.normal(0, 0.025 if i != 1 else 0.045,
                              (size, x1 - x0)).astype(np.float32)
        # Subtle vertical scratches on armor; weave-like variation on cape.
        xx = np.arange(x1-x0, dtype=np.float32)[None, :]
        yy = np.arange(size, dtype=np.float32)[:, None]
        detail = (np.sin(xx * (0.65 if i == 1 else 0.37))
                  * np.cos(yy * (0.12 if i == 1 else 0.027))) * 0.013
        for ch, base_ch in enumerate(base):
            color[:, x0:x1, ch] = np.clip(
                base_ch + variance * (0.35 if i == 0 else 0.60) + detail, 0, 1)
        orm[:, x0:x1, 0] = 1.0
        orm[:, x0:x1, 1] = np.clip(rough + variance * 0.50, 0.05, 0.99)
        orm[:, x0:x1, 2] = metallic
    for name, arr in (("villain_basecolor.png", color),
                      ("villain_orm.png", orm)):
        image = bpy.data.images.new(name, size, size, alpha=True, float_buffer=False)
        image.pixels.foreach_set(arr.ravel())
        image.filepath_raw = str((folder / name).resolve())
        image.file_format = "PNG"
        image.save()
        image.pack()
    return (bpy.data.images["villain_basecolor.png"],
            bpy.data.images["villain_orm.png"])


def shared_materials(base, orm):
    materials = []
    colors = ((0.13, 0.15, 0.19, 1.0), (0.35, 0.035, 0.075, 1.0), (0.66, 0.45, 0.16, 1.0))
    for index, name in enumerate(("01_GraphiteArmor", "02_BurgundyFabric", "03_AgedGold")):
        mat = bpy.data.materials.new(name)
        mat.diffuse_color = colors[index]
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        col = mat.node_tree.nodes.new("ShaderNodeTexImage")
        col.image = base
        col.label = "Shared 2048 base color atlas"
        rough = mat.node_tree.nodes.new("ShaderNodeTexImage")
        rough.image = orm
        rough.label = "Shared occlusion / roughness / metalness atlas"
        sep = mat.node_tree.nodes.new("ShaderNodeSeparateRGB")
        links = mat.node_tree.links
        links.new(col.outputs["Color"], bsdf.inputs["Base Color"])
        links.new(rough.outputs["Color"], sep.inputs["Image"])
        links.new(sep.outputs["G"], bsdf.inputs["Roughness"])
        links.new(sep.outputs["B"], bsdf.inputs["Metallic"])
        materials.append(mat)
    return materials


def make_mesh(name, vertices, faces, mat, root):
    data = bpy.data.meshes.new(name + "_Mesh")
    data.from_pydata(vertices, [], faces)
    data.update()
    o = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(o)
    o.parent = root
    o.data.materials.append(mat)
    for polygon in o.data.polygons:
        polygon.use_smooth = True
    return o


def loft(name, rings, material, root, sides=14):
    """Art-directed elliptical sections: not scaled primitive body blocks."""
    vertices, faces = [], []
    for z, rx, ry, cx, cy in rings:
        for i in range(sides):
            angle = 2 * math.pi * i / sides
            vertices.append((cx + rx*math.cos(angle),
                             cy + ry*math.sin(angle), z))
    faces.append(tuple(reversed(range(sides))))
    for ring_index in range(len(rings)-1):
        for j in range(sides):
            p = ring_index*sides+j
            q = ring_index*sides+(j+1)%sides
            faces.append((p, q, q+sides, p+sides))
    start = (len(rings)-1)*sides
    faces.append(tuple(start+i for i in range(sides)))
    return make_mesh(name, vertices, faces, material, root)


def curved_horn(name, side, material, root):
    verts, faces, n = [], [], 10
    rings = [(1.79, 0.265, -0.01, .135),
             (1.88, 0.31, 0.06, .120),
             (1.96, 0.32, 0.16, .099),
             (2.03, 0.32, 0.28, .071),
             (2.045, 0.32, 0.37, .035),
             (2.04, 0.31, 0.42, .005)]
    for z, x, y, radius in rings:
        for j in range(n):
            angle = 2*math.pi*j/n
            verts.append((side*x+radius*math.cos(angle),
                          y+radius*math.sin(angle), z))
    faces.append(tuple(reversed(range(n))))
    for i in range(len(rings)-1):
        for j in range(n):
            k=i*n+j
            q=i*n+(j+1)%n
            faces.append((k,q,q+n,k+n))
    faces.append(tuple((len(rings)-1)*n+j for j in range(n)))
    return make_mesh(name,verts,faces,material,root)


def poly_sphere(name, center, scale, mat, root, seg=14, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings)
    o = bpy.context.object
    o.name = name
    o.location = center
    o.scale = scale
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    o.parent = root
    o.data.materials.append(mat)
    for polygon in o.data.polygons:
        polygon.use_smooth = True
    return o


def block(name, center, size, mat, root, bevel=0.02):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o=bpy.context.object
    o.name=name
    o.location=center
    o.dimensions=size
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    o.parent=root
    o.data.materials.append(mat)
    if bevel:
        mod=o.modifiers.new("Soft molded edges","BEVEL")
        mod.width=min(bevel, min(size)*0.20)
        mod.segments=2
        bpy.context.view_layer.objects.active=o
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return o


def uv_and_skin(o, segment, armature, bones):
    """Unwrap and map every material to one third of the shared 2048 atlas."""
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active=o
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=0.025)
    bpy.ops.object.mode_set(mode="OBJECT")
    uv=o.data.uv_layers.active
    x0=segment/3.0+0.018
    span=1.0/3.0-0.036
    for loop in uv.data:
        loop.uv[0]=x0+loop.uv[0]*span
        loop.uv[1]=0.016+loop.uv[1]*0.968
    for bone, weight in bones.items():
        vg=o.vertex_groups.new(name=bone)
        vg.add(list(range(len(o.data.vertices))), weight, "REPLACE")
    arm_mod=o.modifiers.new("Humanoid skin", "ARMATURE")
    arm_mod.object=armature
    return o


def skin_cape(o, armature, segment=1):
    uv_and_skin(o,segment,armature,{"cape.upper":1.0})
    rows=14
    cols=17
    for v in o.data.vertices:
        # Weight cape hem to lower secondary bones for natural swaying.
        level=min(1.0,max(0.0,(1.44-v.co.z)/1.06))
        upper=max(0.0,1.0-2.0*level)
        lower=max(0.0,2.0*level-1.0)
        middle=max(0.0,1.0-abs(2.0*level-1.0))
        for b,w in (("cape.upper",upper),("cape.mid",middle),
                    ("cape.tip",lower)):
            vg=o.vertex_groups.get(b)
            if vg is None:
                vg=o.vertex_groups.new(name=b)
            vg.add([v.index],max(0.001,w),"REPLACE")
    return o


def cape_mesh(mat, root):
    """Contoured, thickness-bearing 17x14 draped cloth, hem turned outward."""
    verts,faces=[],[]
    columns,rows=17,14
    for r in range(rows):
        t=r/(rows-1)
        z=1.44-1.06*t
        w=0.48+0.23*t
        for c in range(columns):
            u=c/(columns-1)*2-1
            x=u*w
            y=0.22+0.17*t*t+0.065*math.cos(u*math.pi*3)*(0.3+t)
            verts.append((x,y,z+0.045*math.cos(3*math.pi*u)*(t*t)))
    for r in range(rows-1):
        for c in range(columns-1):
            a=r*columns+c
            faces.append((a,a+1,a+1+columns,a+columns))
    cape=make_mesh("CapeDrapedCloth",verts,faces,mat,root)
    solid=cape.modifiers.new("Real cloth thickness","SOLIDIFY")
    solid.thickness=0.028
    bpy.context.view_layer.objects.active=cape
    bpy.ops.object.modifier_apply(modifier=solid.name)
    return cape


def skeleton(root):
    arm_data=bpy.data.armatures.new("VillainHumanoid")
    arm=bpy.data.objects.new("HumanoidArmature",arm_data)
    bpy.context.collection.objects.link(arm)
    arm.parent=root
    arm.show_in_front=True
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.object.mode_set(mode="EDIT")
    layout={
        "root":((0,0,0.06),(0,0,0.34),None),
        "hips":((0,0,0.89),(0,0,1.02),"root"),
        "spine":((0,0,1.04),(0,0,1.42),"hips"),
        "chest":((0,0,1.42),(0,0,1.55),"spine"),
        "neck":((0,0,1.54),(0,0,1.65),"chest"),
        "head":((0,0,1.65),(0,0,1.89),"neck"),
        "upper_arm.L":((-0.45,0,1.43),(-0.65,0,1.18),"chest"),
        "forearm.L":((-0.65,0,1.18),(-0.76,-0.02,0.98),"upper_arm.L"),
        "hand.L":((-0.76,-0.02,0.98),(-0.80,-0.05,0.89),"forearm.L"),
        "upper_arm.R":((0.45,0,1.43),(0.65,0,1.18),"chest"),
        "forearm.R":((0.65,0,1.18),(0.76,-0.02,0.98),"upper_arm.R"),
        "hand.R":((0.76,-0.02,0.98),(0.80,-0.05,0.89),"forearm.R"),
        "thigh.L":((-0.20,0,0.87),(-0.22,0,0.51),"hips"),
        "shin.L":((-0.22,0,0.51),(-0.22,0,0.16),"thigh.L"),
        "foot.L":((-0.22,0,0.16),(-0.22,-0.19,0.09),"shin.L"),
        "thigh.R":((0.20,0,0.87),(0.22,0,0.51),"hips"),
        "shin.R":((0.22,0,0.51),(0.22,0,0.16),"thigh.R"),
        "foot.R":((0.22,0,0.16),(0.22,-0.19,0.09),"shin.R"),
        "cape.upper":((0,0.23,1.42),(0,0.29,1.16),"chest"),
        "cape.mid":((0,0.29,1.16),(0,0.37,0.76),"cape.upper"),
        "cape.tip":((0,0.37,0.76),(0,0.45,0.38),"cape.mid"),
    }
    for name,(head,tail,parent) in layout.items():
        b=arm_data.edit_bones.new(name)
        b.head=head
        b.tail=tail
    for name,(head,tail,parent) in layout.items():
        if parent:
            arm_data.edit_bones[name].parent=arm_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in arm.pose.bones:
        pb.rotation_mode="XYZ"
    return arm


def animate(arm):
    bpy.context.scene.render.fps=30
    arm.animation_data_create()
    config=[
        ("Idle",49,[
            (1,{"hips":(0,0,0),"chest":(0,0,-0.013),
                "cape.upper":(-0.02,0,0),"cape.tip":(-0.10,0,0)}),
            (25,{"hips":(-0.012,0,0),"chest":(0.012,0,0.013),
                 "head":(-0.02,0,0),"cape.upper":(0.035,0,0),
                 "cape.mid":(-0.06,0,0),"cape.tip":(0.11,0,0)}),
            (49,{"hips":(0,0,0),"chest":(0,0,-0.013),
                 "cape.upper":(-0.02,0,0),"cape.tip":(-0.10,0,0)})
        ]),
        ("Run",25,[
            (1,{"thigh.L":(-0.48,0,0),"thigh.R":(0.48,0,0),
                "shin.R":(-0.40,0,0),"upper_arm.L":(0.29,0,0),
                "upper_arm.R":(-0.27,0,0),"chest":(0.07,0,0),
                "cape.mid":(-0.20,0,0),"cape.tip":(-0.38,0,0)}),
            (7,{"thigh.L":(0,0,0),"thigh.R":(0,0,0),
                "shin.L":(-0.33,0,0),"shin.R":(-0.33,0,0),
                "chest":(0.09,0,0),"cape.mid":(-0.09,0,0),
                "cape.tip":(-0.22,0,0)}),
            (13,{"thigh.L":(0.48,0,0),"thigh.R":(-0.48,0,0),
                "shin.L":(-0.40,0,0),"upper_arm.L":(-0.29,0,0),
                "upper_arm.R":(0.27,0,0),"chest":(0.07,0,0),
                "cape.mid":(-0.20,0,0),"cape.tip":(-0.38,0,0)}),
            (19,{"thigh.L":(0,0,0),"thigh.R":(0,0,0),
                "shin.L":(-0.33,0,0),"shin.R":(-0.33,0,0),
                "chest":(0.09,0,0),"cape.mid":(-0.09,0,0),
                "cape.tip":(-0.22,0,0)}),
            (25,{"thigh.L":(-0.48,0,0),"thigh.R":(0.48,0,0),
                "shin.R":(-0.40,0,0),"upper_arm.L":(0.29,0,0),
                "upper_arm.R":(-0.27,0,0),"chest":(0.07,0,0),
                "cape.mid":(-0.20,0,0),"cape.tip":(-0.38,0,0)})
        ])
    ]
    for name,end,frames in config:
        action=bpy.data.actions.new(name)
        arm.animation_data.action=action
        for frame,pose in frames:
            for pb in arm.pose.bones:
                pb.rotation_euler=pose.get(pb.name,(0,0,0))
                pb.keyframe_insert(data_path="rotation_euler",frame=frame,
                                   group=pb.name)
        arm.animation_data.action=None
        track=arm.animation_data.nla_tracks.new()
        track.name=name
        strip=track.strips.new(name,1,action)
        strip.action_frame_end=end
        strip.repeat=1
    bpy.context.scene.frame_set(1)


def create_asset(source):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.context.scene.unit_settings.system="METRIC"
    bpy.context.scene.unit_settings.scale_length=1.0
    tex=source/"textures"
    base,orm=create_atlas(tex)
    armor,cloth,gold=shared_materials(base,orm)
    root=empty("VillainRig")
    rig=skeleton(root)
    all_models=[]
    def piece(o, idx, bone):
        all_models.append(uv_and_skin(o,idx,rig,{bone:1.0}))
        return o
    # Section-sculpted volume and overlapping beveled armor—not boxes.
    piece(loft("Chest",[(0.93,.28,.23,0,0),(1.02,.37,.25,0,0),
                         (1.24,.48,.30,0,0),(1.45,.54,.29,0,0),
                         (1.55,.42,.24,0,0),(1.58,.31,.19,0,0)],
                         armor,root,18),0,"chest")
    piece(loft("RaisedBreastplate",[(1.08,.30,.29,0,-.03),
                                    (1.24,.47,.35,0,-.02),
                                    (1.43,.50,.36,0,-.015),
                                    (1.52,.34,.30,0,-.01)],
                                    armor,root,18),0,"chest")
    for z,w in ((1.11,.30),(1.29,.43),(1.42,.44)):
        piece(block("RibbedChestTrim",(0,-.326,z),(w*1.5,.045,.048),
                    gold,root,.018),2,"chest")
    piece(loft("BeltBase",[(.82,.32,.245,0,0),(.91,.35,.25,0,0),
                            (1.00,.33,.24,0,0)],cloth,root),1,"hips")
    piece(loft("WaistGuard",[(.83,.37,.26,0,0),(.91,.35,.275,0,0),
                              (.95,.36,.27,0,0)],armor,root),0,"hips")
    piece(block("SkullBeltEmblem",(0,-.31,.88),(.23,.07,.20),gold,
                root,.04),2,"hips")
    # Helmet, articulated jaws, sculpted brow and expressive eye sockets.
    piece(loft("Helmet",[(1.55,.24,.23,0,0),(1.61,.34,.29,0,0),
                          (1.73,.39,.34,0,0),(1.85,.36,.33,0,0),
                          (1.93,.25,.24,0,.025),(1.97,.08,.10,0,.02)],
                          armor,root,18),0,"head")
    piece(loft("HelmFaceplate",[(1.55,.16,.06,0,-.30),
                                (1.66,.26,.09,0,-.305),
                                (1.75,.27,.075,0,-.32),
                                (1.83,.25,.06,0,-.31)],
                                gold,root,18),2,"head")
    for side in (-1,1):
        piece(curved_horn("SweptHorn.L" if side<0 else "SweptHorn.R",
                          side,armor,root),0,"head")
        piece(poly_sphere("HeavyBrow",(side*.14,-.36,1.81),
                          (.22,.075,.065),armor,root),0,"head")
        piece(poly_sphere("AmberEye",(side*.14,-.405,1.75),
                          (.104,.035,.038),gold,root,12,6),2,"head")
        # Broad segmented shoulder silhouette, tapered gauntlets.
        bname="L" if side<0 else "R"
        arm_bone="upper_arm."+bname
        forearm="forearm."+bname
        hand="hand."+bname
        piece(poly_sphere("LayeredPauldron."+bname,
                          (side*.53,0,1.44),(.36,.33,.23),
                          armor,root,16,10),0,arm_bone)
        piece(poly_sphere("GoldPauldronCap."+bname,
                          (side*.55,-.04,1.53),(.27,.25,.065),
                          gold,root),2,arm_bone)
        piece(loft("UpperArmArmor."+bname,
                   [(1.14,.13,.16,side*.65,-.02),
                    (1.23,.19,.20,side*.62,-.015),
                    (1.33,.21,.20,side*.58,0),
                    (1.42,.20,.20,side*.55,0)],
                   armor,root),0,arm_bone)
        piece(loft("TaperedGauntlet."+bname,
                   [(.91,.14,.15,side*.77,-.035),
                    (.99,.17,.19,side*.74,-.015),
                    (1.09,.22,.21,side*.70,0),
                    (1.18,.19,.18,side*.67,0)],
                   armor,root),0,forearm)
        piece(poly_sphere("ArmoredFist."+bname,
                          (side*.79,-.06,.92),(.16,.14,.17),
                          armor,root),0,hand)
        thigh="thigh."+bname
        shin="shin."+bname
        foot="foot."+bname
        piece(loft("ThighCuisses."+bname,
                   [(.47,.165,.19,side*.21,.02),
                    (.60,.20,.23,side*.21,.015),
                    (.76,.22,.23,side*.20,0),
                    (.88,.225,.23,side*.20,0)],
                   armor,root),0,thigh)
        piece(poly_sphere("KneePlate."+bname,
                          (side*.22,-.20,.50),(.22,.13,.16),
                          gold,root),2,shin)
        piece(loft("TaperedGreave."+bname,
                   [(.12,.15,.16,side*.22,0),
                    (.23,.19,.21,side*.22,.005),
                    (.37,.17,.19,side*.22,0),
                    (.48,.21,.22,side*.22,0)],
                   armor,root),0,shin)
        piece(poly_sphere("Boot."+bname,
                          (side*.22,-.105,.11),(.20,.32,.12),
                          armor,root,14,8),0,foot)
        piece(block("BootToeGold."+bname,(side*.22,-.30,.105),
                    (.30,.06,.055),gold,root,.015),2,foot)
    cape=cape_mesh(cloth,root)
    all_models.append(skin_cape(cape,rig))
    piece(block("GoldCapeClasp",(0,.23,1.48),(.33,.09,.10),
                gold,root,.04),2,"chest")
    # Shared matte-metal sword, separate mesh under a hand-bone attachment.
    sword=empty("WeaponPivot")
    sword.parent=rig
    sword.parent_type="BONE"
    sword.parent_bone="hand.R"
    sword.location=(0.0,-0.05,0.0)
    # Sword local Y: hand grip to short, wide leaf-shaped blade.
    blade=make_mesh("WarlordBroadblade",
        [(-.115,-.19,0),(.115,-.19,0),(-.165,-.55,0),
         (.165,-.55,0),(-.135,-.98,0),(.135,-.98,0),
         (-.065,-1.10,0),(.065,-1.10,0),(0,-1.20,0),
         (0,-.19,.055),(0,-.55,.065),(0,-.98,.055)],
        [(0,1,3,2),(2,3,5,4),(4,5,7,6),(6,7,8),
         (0,2,10,9),(2,4,11,10),(4,6,8,11),
         (9,10,3,1),(10,11,5,3),(11,8,7,5)],
        armor,sword)
    guard=block("HandForgedCrossguard",(0,-.15,0),(.59,.12,.11),
                gold,sword,.018)
    grip=block("SwordLeatherGrip",(0,.11,0),(.12,.45,.11),
               cloth,sword,.018)
    pommel=poly_sphere("SwordGoldPommel",(0,.38,0),
                       (.10,.10,.10),gold,sword)
    # These sword objects aren't skinned; the parent follows right-hand bone.
    for obj,idx in ((blade,0),(guard,2),(grip,1),(pommel,2)):
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(island_margin=0.02)
        bpy.ops.object.mode_set(mode="OBJECT")
        for loop in obj.data.uv_layers.active.data:
            loop.uv[0]=idx/3+0.018+loop.uv[0]*(1/3-0.036)
            loop.uv[1]=.016+loop.uv[1]*.968
        all_models.append(obj)
    for name in ("LegLeft","LegRight"):
        marker=empty(name,root)
        marker.location=(-.20 if name=="LegLeft" else .20,0,.85)
    # Preserve runtime node contract without duplicating real skeletal motion.
    animate(rig)
    triangles=sum(sum(max(0,len(p.vertices)-2) for p in o.data.polygons)
                  for o in all_models)
    if triangles > 20000:
        raise RuntimeError("Mobile budget exceeded: %d triangles" % triangles)
    for ob in all_models:
        if ob.type!="MESH" or not ob.data.uv_layers:
            raise RuntimeError("UV missing: "+ob.name)
        for vertex in ob.data.vertices:
            if ob.modifiers.get("Humanoid skin"):
                count=sum(1 for g in vertex.groups if g.weight>.001)
                if count>4:
                    raise RuntimeError("Too many bone weights on "+ob.name)
    return root,rig,all_models,triangles


def preview(source,root,rig):
    scene=bpy.context.scene
    camera_data=bpy.data.cameras.new("CharacterTurntableCamera")
    camera=bpy.data.objects.new("CharacterTurntableCamera",camera_data)
    bpy.context.collection.objects.link(camera)
    scene.camera=camera
    # Headless GitHub runners do not provide libEGL for Workbench/EEVEE.
    # Cycles CPU renders the real atlas-backed PBR appearance without a GPU.
    scene.render.engine="CYCLES"
    scene.cycles.device="CPU"
    scene.cycles.samples=12
    scene.cycles.use_denoising=True
    scene.world.use_nodes=True
    bg=scene.world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value=(0.68,0.73,0.82,1.0)
    bg.inputs["Strength"].default_value=0.70
    lights=(("SoftboxKey",(3,-4,5),620,4.0),
            ("WarmFill",(-4,-2,3),350,4.5),
            ("CapeRim",(1,4,4),830,3.5))
    target=Vector((0,0,1.05))
    for name,loc,energy,size in lights:
        data=bpy.data.lights.new(name,"AREA")
        data.energy=energy
        data.shape="DISK"
        data.size=size
        lamp=bpy.data.objects.new(name,data)
        bpy.context.collection.objects.link(lamp)
        lamp.location=loc
        lamp.rotation_euler=(target-lamp.location).to_track_quat("-Z","Y").to_euler()
    scene.render.resolution_x=768
    scene.render.resolution_y=768
    scene.render.resolution_percentage=100
    scene.render.image_settings.file_format="PNG"
    scene.render.film_transparent=False
    scene.camera.data.type="ORTHO"
    camera.data.ortho_scale=2.75
    look_at=Vector((0,0,1.02))
    for name,xyz in (("front",(0,-5,1.45)),
                     ("side",(5,0,1.45)),("back",(0,5,1.45))):
        camera.location=xyz
        camera.rotation_euler=(look_at-camera.location).to_track_quat("-Z","Y").to_euler()
        scene.render.filepath=str(source/("villain_"+name+".png"))
        bpy.ops.render.render(write_still=True)
    scene.camera=None
    return camera


def roundtrip(path):
    # Import into the existing scene; names may gain .001 suffixes.
    before=set(bpy.data.objects.keys())
    bpy.ops.import_scene.gltf(filepath=str(path))
    new=[o for o in bpy.data.objects if o.name not in before]
    imported_arm=[o for o in new if o.type=="ARMATURE"]
    skinned=[o for o in new if o.type=="MESH" and
             any(mod.type=="ARMATURE" for mod in o.modifiers)]
    if not imported_arm or not skinned:
        raise RuntimeError("GLB round-trip lost armature or skin weights")
    for name in ("hips","head","hand.R","thigh.L","thigh.R","cape.tip"):
        if name not in imported_arm[0].data.bones:
            raise RuntimeError("GLB round-trip lost bone: "+name)
    if not any(o.name.startswith("WeaponPivot") for o in new):
        raise RuntimeError("GLB round-trip lost detachable sword pivot")
    print("PASS: GLB round-trip: %d skin meshes; %d bones" %
          (len(skinned),len(imported_arm[0].data.bones)),flush=True)


def main():
    settings=args()
    output=Path(settings.output).resolve()
    source=Path(settings.source).resolve()
    source.mkdir(parents=True,exist_ok=True)
    output.mkdir(parents=True,exist_ok=True)
    (source/".gdignore").touch()
    root,arm,models,triangles=create_asset(source)
    # Ensure external images survive without access to the original .blend file.
    preview(source,root,arm)
    scene=bpy.context.scene
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(source/"villain.blend"))
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.context.scene.objects:
        ancestor=o
        while ancestor is not None and ancestor!=root:
            ancestor=ancestor.parent
        if ancestor==root:
            o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(output/"villain.glb"),
                              export_format="GLB", use_selection=True,
                              export_nla_strips=True,
                              export_animations=True, export_apply=False)
    shutil.copyfile(output/"villain.glb",output/"villain_knight.glb")
    roundtrip(output/"villain.glb")
    report={
        "name":"Original horned fantasy warlord",
        "model":"villain.glb",
        "editable_source":"villain.blend",
        "triangles":triangles,
        "materials":3,
        "texture_size":[2048,2048],
        "textures":["villain_basecolor.png","villain_orm.png"],
        "animation_clips":["Idle","Run"],
        "other_animations":"attack, block, jump, damage and death remain gameplay poses until separately authored",
        "bones":len(arm.data.bones),
        "separate_weapon":True,
        "roundtrip":"PASS"
    }
    (source/"model_report.json").write_text(json.dumps(report,indent=2))
    print("RIGGED VILLAIN READY",json.dumps(report),flush=True)


if __name__=="__main__":
    main()
