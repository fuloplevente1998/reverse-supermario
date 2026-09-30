"""Extend the previous GitHub courtyard kit with actual reusable 3D scenery.

Blender --background --python tools/blender/generate_world.py
Editable sources retain separate parts; static GLBs consolidate mesh draw groups.
"""
import math, random, sys, json, functools
from pathlib import Path
import bpy
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).parent))
import generate_art as a
import generate_stage1_kit as kit
from split_courtyard_gltf import split

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/models'; SRC=ROOT/'art/source/world'
OUT.mkdir(parents=True,exist_ok=True);SRC.mkdir(parents=True,exist_ok=True)
(SRC/'.gdignore').touch()
stats={}

def mesh(name,verts,faces,mat,parent):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj)
    obj.parent=parent;data.materials.append(mat)
    return obj

def beam(name,start,end,width,mat,parent):
    start,end=Vector(start),Vector(end)
    obj=a.cube(name,(start+end)/2,(width,width,(end-start).length),mat,parent,.012)
    obj.rotation_euler=(end-start).to_track_quat('Z','Y').to_euler();return obj

@functools.lru_cache(maxsize=1)
def palette():
    return [a.material('Honey limestone',(.45,.38,.29),roughness=.92),
            a.material('Warm plaster',(.69,.61,.45),roughness=.94),
            a.material('Dark oak',(.20,.105,.055),roughness=.85),
            a.material('Weathered slate',(.12,.20,.27),roughness=.85),
            a.material('Window recess',(.055,.071,.073),roughness=.9),
            a.material('Leaf midtone',(.10,.23,.075),roughness=1),
            a.material('Leaf sunlight',(.20,.32,.095),roughness=1)]

def house(parent,at=(0,0,0),name='TimberHouse'):
    stone,plaster,wood,slate,dark,leaf,light=palette();x,y,z=at
    root=a.empty(name,at,parent)
    a.cube('Foundation',(0,0,.3),(4.6,5.4,.6),stone,root,.08)
    a.cube('PlasterWalls',(0,0,2.2),(4.2,5,3.8),plaster,root,.065)
    for sx in (-2.12,2.12):
        for sy in (-2.52,0,2.52):
            a.cube('TimberPost',(sx,sy,2.2),(.17,.17,3.9),wood,root,.015)
    for h in (.65,2.5,4.0):
        a.cube('FacadeBeam',(0,-2.54,h),(4.42,.15,.17),wood,root,.015)
        for sx in (-2.14,2.14):a.cube('SideBeam',(sx,0,h),(.15,5.2,.17),wood,root,.015)
    mesh('GabledAttic',[(-2.1,-2.5,4.1),(2.1,-2.5,4.1),(0,-2.5,5.9),(-2.1,2.5,4.1),(2.1,2.5,4.1),(0,2.5,5.9)],[(0,1,2),(3,5,4),(0,3,4,1),(1,4,5,2),(2,5,3,0)],plaster,root)
    for side in (-1,1):
        panel=a.cube('RoofSlope',(side*1.18,0,5.0),(3.1,5.8,.15),slate,root,.025)
        panel.rotation_euler[1]=side*math.radians(39)
        # The roof silhouette and tile rows are real geometry, not a painted plane.
        for row in range(5):
            rx=side*(.12+row*.49);rz=5.92-abs(rx)*.81
            for col in range(9):
                tile=a.cube('SlateRoofTile',(rx,(col-4)*.62,rz),(.64,.59,.045),slate,root,.018)
                tile.rotation_euler[1]=side*math.radians(39)
    a.cube('RidgeCap',(0,0,5.98),(.22,5.95,.16),stone,root,.045)
    a.cube('Chimney',(.9,1.25,5.65),(.55,.65,1.65),stone,root,.045)
    for side in (-1,1):
        beam('DiagonalFacade',(side*2.02,-2.63,.75),(side*.9,-2.63,2.42),.13,wood,root)
        a.cube('WindowRecess',(side*1.15,-2.575,3.15),(.68,.1,.86),dark,root,.04)
        a.cube('WindowSill',(side*1.15,-2.66,2.7),(.89,.22,.13),stone,root,.015)
        a.cube('WindowMullion',(side*1.15,-2.65,3.15),(.07,.05,.86),wood,root,.008)
        a.cube('WindowCrossbar',(side*1.15,-2.65,3.15),(.68,.05,.06),wood,root,.008)
    a.cube('DoorRecess',(0,-2.56,1.45),(1.13,.09,1.9),dark,root,.045)
    for i in range(6):a.cube('DoorPlank',((i-2.5)*.16,-2.64,1.43),(.15,.09,1.76),wood,root,.01)
    for h in (.9,1.8):a.cube('DoorStrap',(0,-2.71,h),(.98,.045,.075),dark,root,.008)
    a.cube('DoorStep',(0,-2.85,.2),(1.52,.9,.3),stone,root,.045)
    return root

def oak(parent,at=(0,0,0),seed=0):
    rng=random.Random(seed);stone,plaster,wood,slate,dark,leaf,light=palette()
    root=a.empty('OakTree',at,parent)
    # Tapered branching trunk and asymmetric clusters create a volume from every view.
    beam('OakTrunk',(0,0,0),(.12,.08,3.1),.39,wood,root)
    for i in range(6):
        ang=i*math.tau/6;end=(math.cos(ang)*1.25,math.sin(ang)*1.15,3.1+rng.uniform(-.35,.6))
        beam('OakBranch',(.08,.04,1.75),end,.16,wood,root)
        a.sphere('OakLeafCluster',end,(1.15,1.1,1.0),leaf if i%2 else light,root,12,8)
    a.sphere('OakCanopy',(.1,0,4.0),(1.25,1.15,1.2),leaf,root,12,8)
    for i in range(5):
        ang=i*math.tau/5
        beam('RootFlare',(0,0,.28),(math.cos(ang)*.65,math.sin(ang)*.65,.08),.15,wood,root)
    return root

def wall(parent,x,y,length=8,height=3.2):
    stone,plaster,wood,slate,dark,leaf,light=palette()
    a.cube('WallMortarCore',(x,y,height/2),(length,.70,height),dark,parent,.02)
    for row in range(5):
        for col in range(8):
            bx=x-length/2+(col+.5)*length/8
            a.cube('WallLimestoneBlock',(bx,y,(row+.5)*height/5),
                   (length/8-.035,.85,height/5-.035),stone if (row+col)%4 else plaster,parent,.035)
    a.cube('WallCoping',(x,y,height+.07),(length+.08,1.0,.19),plaster,parent,.035)
    for col in range(6):a.cube('Crenellation',(x+(col-2.5)*length/6,y,height+.45),(.68,.85,.7),stone,parent,.03)

def extend_yard():
    root=bpy.data.objects.get('CourtyardEnvironment')
    if not root:return
    # Continue the previous textured road; remove its block-shaped barrel stand-ins.
    for o in list(bpy.context.scene.objects):
        if o.name.startswith(('BarrelStave','BarrelIronHoop','CypressTrunk','CypressCrown')):bpy.data.objects.remove(o,do_unlink=True)
    # Full-length walls and a small village frame the traversable central court.
    for side in (-1,1):
        for i,z in enumerate(range(-9,43,8)):
            tree=oak(root,(side*14.0,-z,0),i+10)
            tree.scale=(.83,.83,1.0)
        for z in (-7,9,25):
            building=house(root,(side*18.5,-z,0))
            building.rotation_euler[2]=side*math.pi/2
        for z in range(-11,45,8):
            section=a.empty('CurtainWallSection',(side*23.8,-z,0),root)
            wall(section,0,0);section.rotation_euler[2]=math.pi/2
    # A real low-poly ground apron and rocky slopes replace the floating island edge.
    grass=a.material('Landscape moss',(.16,.235,.09),roughness=1)
    a.cube('LandscapeApron',(0,-15,-.37),(62,91,.6),grass,root,0)
    for side in (-1,1):
        for z in (-8,18,42):
            hill=a.sphere('DistantHill',(side*34,-z,-1),(12,15,7),grass,root,16,8)
    # Broader stone road all the way to the side boundaries.
    under=bpy.data.objects.get('PavementUnderlay');under.scale.x=20/19.2

def gate_masonry():
    root=bpy.data.objects.get('FortressGate')
    if not root or root.get('masonry_pass'):return
    root['masonry_pass']=True
    stone,plaster,*unused=palette()
    # Individual wedge blocks catch shadows on the round tower silhouette.
    for side in (-1,1):
        for row in range(9):
            for col in range(16):
                angle=(col+.5*(row%2))*math.tau/16
                lo=angle+.012;hi=angle+math.tau/16-.012
                verts=[]
                for z in (row*.87+.025,(row+1)*.87-.025):
                    for radius,a0 in [(1.57,lo),(1.68,lo),(1.68,hi),(1.57,hi)]:
                        verts.append((side*7.4+radius*math.cos(a0),1.25+radius*math.sin(a0),z))
                o=mesh('TowerMasonryBlock',verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],stone if (row+col)%5 else plaster,root)
                a.bevel(o,.012,1)

def tighten_saved_paving():
    root=bpy.data.objects.get('CourtyardEnvironment')
    if root.get('tight_paving_pass'):return
    root['tight_paving_pass']=True
    for obj in bpy.context.scene.objects:
        if not obj.name.startswith('PavementBatch'):continue
        vertices=obj.data.vertices
        for start in range(0,len(vertices),16):
            tile=list(vertices[start:start+16])
            cx=sum(v.co.x for v in tile)/16;cy=sum(v.co.y for v in tile)/16
            for v in tile:
                v.co.x=cx+(v.co.x-cx)*1.16;v.co.y=cy+(v.co.y-cy)*1.11

def export_asset(name,output,source):
    if name=='courtyard_environment' and '--reexport' not in sys.argv:extend_yard()
    if name=='fortress_gate' and '--reexport' not in sys.argv:gate_masonry()
    # Equal colors must share actual material datablocks, otherwise repeated
    # buildings create a draw surface for every duplicated Blender material.
    canonical={}
    for o in bpy.context.scene.objects:
        if o.type!='MESH':continue
        for i,mat in enumerate(o.data.materials):
            p=mat.node_tree.nodes.get('Principled BSDF')
            images=tuple(n.image.name for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image)
            key=(tuple(mat.diffuse_color),p.inputs['Metallic'].default_value,p.inputs['Roughness'].default_value,p.inputs['Emission Strength'].default_value,images)
            canonical.setdefault(key,mat);o.data.materials[i]=canonical[key]
    # Sources contain individually editable components, textures packed.
    bpy.ops.wm.save_as_mainfile(filepath=str(source/(name+'.blend')),compress=True)
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    # Preserve four paving batches for shared limestone textures, merge static decoration.
    groups={}
    for o in meshes:
        key=o.name if o.name.startswith(('PavementBatch','PavementUnderlay')) else 'SceneryRuntime'
        groups.setdefault(key,[]).append(o)
    for key,parts in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in parts:o.select_set(True)
        bpy.context.view_layer.objects.active=parts[0]
        if len(parts)>1:bpy.ops.object.join()
        bpy.context.object.name=key
    bpy.ops.export_scene.gltf(filepath=str(output/(name+'.glb')),export_format='GLB',export_apply=True)
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    size=(output/(name+'.glb')).stat().st_size
    if name=='courtyard_environment':size=split(output/(name+'.glb'))
    stats[name]={'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objs),'meshes':len(objs),'bytes':size}
    print('WORLD_ASSET',name,stats[name],flush=True)

a.save_asset=export_asset
if '--refine-existing' in sys.argv:
    sys.argv.append('--reexport')
    for name,refine in [('courtyard_environment',tighten_saved_paving),('fortress_gate',gate_masonry)]:
        bpy.ops.wm.open_mainfile(filepath=str(SRC/(name+'.blend')))
        refine();export_asset(name,OUT,SRC)
    print('WORLD_REFINEMENT_OK',flush=True)
    sys.exit(0)
if '--reexport' in sys.argv:
    for name in ['fortress_gate','courtyard_environment','stage1_barricade','stage1_barrel','stage1_crate','stage1_banner','timber_house','oak_tree','castle_wall','cliff_rock','pine_tree','forge_house','mill_house']:
        bpy.ops.wm.open_mainfile(filepath=str(SRC/(name+'.blend')))
        export_asset(name,OUT,SRC)
    (SRC/'world_stats.json').write_text(json.dumps(stats,indent=2))
    print('WORLD_REEXPORT_OK',flush=True)
    sys.exit(0)
a.gate(OUT,SRC);a.courtyard_environment(OUT,SRC)
kit.battered_barrier(OUT,SRC);kit.oak_barrel(OUT,SRC);kit.oak_crate(OUT,SRC);kit.war_banner(OUT,SRC)

a.clear_scene();house(None);export_asset('timber_house',OUT,SRC)
a.clear_scene();oak(None);export_asset('oak_tree',OUT,SRC)
a.clear_scene();root=a.empty('CurtainWall');wall(root,0,0);export_asset('castle_wall',OUT,SRC)

a.clear_scene();root=a.empty('CliffRock');rng=random.Random(79)
rock=a.material('Granite',(.31,.34,.32),roughness=.96)
for i in range(4):
    o=a.sphere('FracturedBoulder',(rng.uniform(-.7,.7),rng.uniform(-.6,.6),.65+i*.21),(1.2,.95,.95),rock,root,8,5)
    o.rotation_euler=(rng.uniform(-.2,.2),rng.uniform(-.3,.3),rng.random()*3)
export_asset('cliff_rock',OUT,SRC)

a.clear_scene();root=a.empty('PineTree');stone,plaster,wood,slate,dark,leaf,light=palette()
a.cylinder('PineTrunk',(0,0,1.5),.18,3,wood,root)
for level in range(5):
    z=1.65+level*.55;r=1.45-level*.23
    for i in range(6):
        ang=(i+.5*(level%2))*math.tau/6
        branch=a.sphere('PineNeedleBranch',(math.cos(ang)*r*.43,math.sin(ang)*r*.43,z),(.66,.42,.35),leaf if i%2 else light,root,10,6)
        branch.rotation_euler[2]=ang
export_asset('pine_tree',OUT,SRC)

a.clear_scene();root=house(None,name='ForgeHouse');stone,plaster,wood,slate,dark,leaf,light=palette()
a.cube('ForgeChimney',(-1.5,.7,4.3),(1.1,1.1,7.3),stone,root,.07)
a.cube('ForgeHearth',(1,-2.75,.55),(1.15,.75,1.1),dark,root,.06)
fire=a.material('Forge coals',(.9,.14,.025),roughness=.7,glow=1)
a.cube('ForgeEmbers',(1,-3.16,.45),(.85,.07,.3),fire,root,.02)
export_asset('forge_house',OUT,SRC)

a.clear_scene();root=house(None,name='MillHouse');stone,plaster,wood,slate,dark,leaf,light=palette()
wheel=a.cylinder('MillWheel',(-2.65,0,2),1.65,.28,wood,root,24);wheel.rotation_euler[1]=math.pi/2
for i in range(16):
    ang=i*math.tau/16
    paddle=a.cube('WaterwheelPaddle',(-2.7,math.cos(ang)*1.55,2+math.sin(ang)*1.55),(.68,.19,.28),wood,root,.018)
    paddle.rotation_euler[0]=ang
for i in range(8):
    ang=i*math.tau/8
    beam('WheelSpoke',(-2.89,0,2),(-2.89,math.cos(ang)*1.5,2+math.sin(ang)*1.5),.12,stone,root)
export_asset('mill_house',OUT,SRC)
(SRC/'world_stats.json').write_text(json.dumps(stats,indent=2))
print('WORLD_GENERATION_OK',flush=True)
