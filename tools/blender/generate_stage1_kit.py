"""Stage-one production kit: mobile-oriented, reusable original Blender models.

Reproducible, GUI-free build:
  blender -b --factory-startup --python tools/blender/generate_stage1_kit.py -- \
    --output assets/models --source build/blender

Exports individual .blend/.glb source pairs; no external copyrighted meshes.
Each asset is authored at its floor/center pivot for direct Godot placement.
"""
import math
import random
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import generate_art as art


def painted(name, color, metal=0.0, rough=0.72):
    return art.material(name, color, metal=metal, roughness=rough)


def setup():
    art.clear_scene()
    mortar = painted("Dark masonry joints", (.19, .19, .18), rough=.96)
    limestone = painted("Sculpted warm limestone", (.43, .38, .32), rough=.91)
    light = painted("Weathered stone edge", (.62, .54, .42), rough=.87)
    gold = painted("Aged gilt", (.56, .35, .14), metal=.64, rough=.42)
    wood = painted("Walnut oak", (.24, .125, .063), rough=.84)
    metal = painted("Forged dark steel", (.13, .155, .17), metal=.8, rough=.48)
    red = painted("Burgundy heraldic cloth", (.39, .035, .072), rough=.87)
    return mortar,limestone,light,gold,wood,metal,red


def battered_barrier(output, source):
    """Ten-metre jump wall (matches stage-one physics dimensions)."""
    mortar,stone,light,gold,wood,metal,red=setup()
    root=art.empty("FortressBarricade")
    # A one metre tall self-contained decorative shell with central origin.
    art.cube("StoneCore", (0,0,0), (9.96,.90,.88),mortar,root,.06)
    rng=random.Random(1337)
    for row in range(2):
        for col in range(10):
            x=(col-4.5)*.98+(0.21 if row else -.21)
            z=-.20 if row==0 else .23
            width=rng.uniform(.88,1.08)
            block=art.cube("HandhewnLimestone", (x,rng.uniform(-.012,.012),z),
                (width,.98,.42), stone if (col+row)%3 else light,root,
                rng.uniform(.025,.065))
            block.rotation_euler[1]=rng.uniform(-.016,.016)
    # Broad top slabs, brass corner ornaments and readable age/wear details.
    for i in range(10):
        x=(i-4.5)*.99
        cap=art.cube("OverhangingCapstone", (x,0,.505),
                     (.97,1.17,.17),light if i%4 else stone,root,.055)
        cap.rotation_euler[1]=rng.uniform(-.025,.025)
    for x in (-4.65,4.65):
        art.cube("BronzeCornerBracket",(x,-.51,.19),(.19,.065,.51),gold,root,.025)
        art.cube("VerticalIronReinforcement",(x,.51,.12),(.11,.055,.57),metal,root,.019)
    for i in (-3,-1,1,3):
        # Bronze sigil on the attack-facing side.
        art.cube("WornGoldInlay",(i*.97,-.52,.05),(.05,.047,.35),gold,root,.01)
    art.save_asset("stage1_barricade",output,source)


def oak_barrel(output, source):
    mortar,stone,light,gold,wood,metal,red=setup()
    root=art.empty("OakBarrel")
    # Contoured twenty-stave silhouette instead of one cylinder.
    for i in range(20):
        angle=2*math.pi*i/20
        obj=art.cube("CurvedOakStave",
            (math.cos(angle)*.43,math.sin(angle)*.43,.55),
            (.19,.075,1.04),wood,root,.028)
        obj.rotation_euler[2]=angle-math.pi/2
    for z,r in ((.20,.45),(.86,.49)):
        art.cylinder("IronCooperBand",(0,0,z),r,.09,metal,root,20)
    art.cylinder("BarrelLid",(0,0,1.08),.40,.07,wood,root,20)
    for angle in (0,math.pi/2,math.pi,3*math.pi/2):
        art.cube("RivetedBandStud",(.48*math.cos(angle),.48*math.sin(angle),.86),
                 (.075,.075,.08),gold,root,.009)
    art.save_asset("stage1_barrel",output,source)


def oak_crate(output, source):
    mortar,stone,light,gold,wood,metal,red=setup()
    root=art.empty("SiegeSupplyCrate")
    art.cube("ChestCore",(0,0,.48),(.94,.94,.95),wood,root,.028)
    for z in (.08,.47,.85):
        for side in (-1,1):
            art.cube("FrontBackPlank",(0,side*.5,z),
                     (1.02,.06,.25),wood,root,.018)
            art.cube("SidePlank",(side*.5,0,z),(.06,.94,.25),wood,root,.018)
    for side in (-1,1):
        for x in (-.44,.44):
            art.cube("CornerBand",(x,side*.52,.52),(.10,.07,.89),metal,root,.015)
        plank=art.cube("DiagonalBrace",(0,side*.55,.50),(.09,.10,1.20),
                       gold,root,.017)
        plank.rotation_euler[1]=math.radians(41)
    for side in (-1,1):
        for y in (-.44,.44):
            art.cube("CrateIronCorner",(side*.52,y,.48),(.07,.12,.95),metal,root,.011)
    art.save_asset("stage1_crate",output,source)


def war_banner(output,source):
    mortar,stone,light,gold,wood,metal,red=setup()
    root=art.empty("WarBanner")
    art.cylinder("BlackIronStandard",(0,0,1.98),.046,3.93,metal,root,10)
    art.cube("HorizontalGiltBar",(0,-.05,3.55),(1.23,.095,.12),gold,root,.023)
    art.sphere("BannerFinial",(0,0,4.06),(.115,.115,.18),gold,root,12,8)
    # Irregular hanging textile, readable in both camera angles.
    verts,faces=[],[]
    cols,rows=9,13
    for r in range(rows):
        t=r/(rows-1)
        z=3.43-t*2.16
        for c in range(cols):
            u=2*c/(cols-1)-1
            x=.57*u
            y=-.12+.055*math.sin(u*math.pi*1.5)*(t*.6+.4)
            verts.append((x,y,z + (.19*abs(u) if r==rows-1 else 0)))
    for r in range(rows-1):
        for c in range(cols-1):
            i=r*cols+c
            faces.append((i,i+1,i+1+cols,i+cols))
    banner=art.make_mesh if hasattr(art,"make_mesh") else None
    data=art.bpy.data.meshes.new("WovenBannerMesh")
    data.from_pydata(verts,[],faces)
    data.update()
    obj=art.bpy.data.objects.new("BurgundyCloth",data)
    art.bpy.context.collection.objects.link(obj)
    obj.parent=root
    obj.data.materials.append(red)
    solid=obj.modifiers.new("Cloth thickness","SOLIDIFY")
    solid.thickness=.023
    art.bpy.context.view_layer.objects.active=obj
    art.bpy.ops.object.modifier_apply(modifier=solid.name)
    # Separate unmistakable gold emblem on front of cloth.
    art.cube("HeraldicVertical",(0,-.19,2.44),(.09,.025,.79),gold,root,.011)
    for side in (-1,1):
        stroke=art.cube("HeraldicWing",(side*.16,-.19,2.56),
                        (.08,.026,.52),gold,root,.01)
        stroke.rotation_euler[1]=side*math.radians(35)
    art.save_asset("stage1_banner",output,source)


if __name__=="__main__":
    import argparse
    tail=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
    p=argparse.ArgumentParser()
    p.add_argument("--output",default="assets/models")
    p.add_argument("--source",default="build/blender")
    opt=p.parse_args(tail)
    out=Path(opt.output).resolve()
    src=Path(opt.source).resolve()
    out.mkdir(parents=True,exist_ok=True)
    src.mkdir(parents=True,exist_ok=True)
    (src/".gdignore").touch()
    battered_barrier(out,src)
    oak_barrel(out,src)
    oak_crate(out,src)
    war_banner(out,src)
    print("PASS: four stage-one Blender asset pairs generated",flush=True)
