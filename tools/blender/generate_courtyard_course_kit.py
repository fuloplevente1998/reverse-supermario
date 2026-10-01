"""Reusable, authored GLB scenery for the full Stage 1 courtyard.

blender -b --python tools/blender/generate_courtyard_course_kit.py
Units are metres. Meshes are joined per asset; material slots are shared.
The source .blend files remain editable alongside the deterministic generator.
"""
import math, random, sys
from pathlib import Path
import bpy
sys.path.insert(0, str(Path(__file__).parent))
import generate_art as art
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/models'
SOURCE = ROOT / 'art/source/world/courtyard_course'
SOURCE.mkdir(parents=True, exist_ok=True)

def palette():
    art.clear_scene()
    # Hex/reference palette values are sRGB; glTF stores linear base colours.
    def linear(c):
        return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4
    return {k: art.material(k, tuple(linear(v) for v in c), roughness=.88) for k,c in {
        'Pale limestone':(.72,.60,.42), 'Light worn edges':(.87,.75,.54),
        'Deep mortar':(.29,.25,.19), 'Cypress dark':(.08,.20,.08),
        'Leaf green':(.21,.36,.11), 'Leaf sunlit':(.36,.46,.17),
        'Ivory blossom':(.98,.91,.65), 'Golden flower':(.76,.42,.09),
        'Heraldic red':(.51,.045,.085), 'Gilt border':(.72,.44,.13),
        'Pool turquoise':(.15,.40,.39)}.items()}

def finish(name):
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes: o.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=name
    # All meshes use the origin as their placement pivot.
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    slots={}
    indices={}
    for i,mat in enumerate(obj.data.materials):
        if mat.name not in slots: slots[mat.name]=mat
        indices[i]=list(slots).index(mat.name)
    poly_indices=[indices[p.material_index] for p in obj.data.polygons]
    obj.data.materials.clear()
    for mat in slots.values(): obj.data.materials.append(mat)
    for p,i in zip(obj.data.polygons,poly_indices): p.material_index=i
    art.save_asset(name,OUT,SOURCE)

p=palette()
art.cube('Hand-cut beveled stone',(0,0,0),(1,1,1),p['Pale limestone'],bevel_size=.045)
finish('courtyard_course_stone')

p=palette()
# A 12 m wall module with recessed arch windows and individually laid masonry.
art.cube('Mortar core',(0,.1,2.05),(12,.44,4.1),p['Deep mortar'],bevel_size=.01)
rng=random.Random(11002)
for row in range(7):
    for col in range(9):
        x=-5.55+col*1.38+(.32 if row%2 else 0)
        if x>5.8: continue
        art.cube('Ashlar course',(x,-.16, .30+row*.56),(1.32,.28,.50),p['Light worn edges'] if (row+col)%7==0 else p['Pale limestone'],bevel_size=.045)
for x in [-4.5,0,4.5]:
    art.cube('Window recess',(x,-.32,2.3),(.72,.04,1.45),p['Deep mortar'],bevel_size=.08)
    for side in [-1,1]:
        art.cube('Window jamb',(x+side*.49,-.37,2.3),(.19,.15,1.70),p['Light worn edges'],bevel_size=.035)
    for i in range(7):
        angle=i*math.pi/6
        block=art.cube('Arched window stone',(x+math.cos(angle)*.48,-.38,3.0+math.sin(angle)*.43),(.23,.18,.24),p['Light worn edges'],bevel_size=.025)
        block.rotation_euler[1]=angle
for x in [-5.5,-3.5,-1.5,.5,2.5,4.5]:
    art.cube('Battlement',(x,-.04,4.35),(.94,.68,.65),p['Light worn edges'],bevel_size=.05)
art.cube('Wall coping',(0,-.10,4.03),(12.15,.77,.23),p['Light worn edges'],bevel_size=.05)
finish('courtyard_course_wall')

p=palette()
art.cylinder('Tower masonry',(0,0,2.65),1.55,5.3,p['Pale limestone'],vertices=16)
for z in [.22,2.0,4.8,5.25]:
    art.cylinder('Tower carved band',(0,0,z),1.65,.20,p['Light worn edges'],vertices=16)
for i in range(10):
    a=i*math.tau/10
    o=art.cube('Crenellation',(math.cos(a)*1.45,math.sin(a)*1.45,5.62),(.65,.57,.64),p['Light worn edges'],bevel_size=.05)
    o.rotation_euler[2]=a
for z in [1.2,2.7,4.0]:
    art.cube('Arrow slit',(0,-1.56,z),(.18,.04,.65),p['Deep mortar'],bevel_size=.02)
art.cube('Red tower banner',(0,-1.60,2.95),(.95,.08,2.25),p['Heraldic red'],bevel_size=.02)
for x in [-.43,.43]: art.cube('Banner border',(x,-1.66,2.95),(.055,.02,2.2),p['Gilt border'],bevel_size=.005)
art.cube('Gold heraldic upright',(0,-1.67,3.0),(.09,.03,.60),p['Gilt border'],bevel_size=.01)
art.cube('Gold heraldic cross',(0,-1.67,3.1),(.48,.03,.10),p['Gilt border'],bevel_size=.01)
finish('courtyard_course_tower')

p=palette()
# Sculpted fountain rim, water basin, column and two carved bowls.
for radius,z,depth in [(1.6,.18,.36),(1.45,.42,.18),(1.64,.55,.16)]:
    art.cylinder('Carved basin', (0,0,z),radius,depth,p['Light worn edges'],vertices=20)
art.cylinder('Visible water',(0,0,.65),1.40,.025,p['Pool turquoise'],vertices=24)
art.cylinder('Central column',(0,0,1.1),.25,1.4,p['Pale limestone'],vertices=12)
for radius,z in [(.86,1.58),(.55,2.35)]:
    art.cylinder('Fountain bowl',(0,0,z),radius,.20,p['Light worn edges'],vertices=16)
    art.cylinder('Upper water',(0,0,z+.11),radius*.82,.025,p['Pool turquoise'],vertices=16)
art.cylinder('Finial',(0,0,2.15),.14,.9,p['Pale limestone'],vertices=12)
for i in range(12):
    a=i*math.tau/12
    art.cylinder('Basin carved bead',(math.cos(a)*1.56,math.sin(a)*1.56,.71),.07,.17,p['Pale limestone'],vertices=8)
finish('courtyard_course_fountain')

p=palette()
art.cylinder('Cypress trunk',(0,0,1.3),.12,2.6,p['Deep mortar'],vertices=8)
for i,(z,r,h) in enumerate([(1.45,.64,1.8),(2.4,.62,1.9),(3.4,.48,1.8),(4.25,.29,1.4)]):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=(0,0,z))
    obj=bpy.context.object;obj.name='Sculpted cypress foliage';obj.scale=(r,r,h/2)
    obj.data.materials.append(p['Cypress dark'] if i%2 else p['Leaf green'])
finish('courtyard_course_cypress')

p=palette()
rng=random.Random(4401)
# Front-facing ivy patch. In Blender it hangs in the X/Z plane, into negative Z.
for i in range(70):
    x=rng.uniform(-.95,.95);z=-rng.uniform(.08,1.5);y=rng.uniform(-.10,.03)
    size=rng.uniform(.11,.20)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(x,y,z))
    o=bpy.context.object;o.name='Ivy leaf cluster';o.scale=(size,.045,size*.82)
    o.rotation_euler[1]=rng.uniform(-.7,.7)
    o.data.materials.append(p['Leaf sunlit'] if i%5==0 else p['Leaf green'])
    if i%7==0:
        for a in range(5):
            angle=a*math.tau/5
            art.sphere('Five-petal ivory blossom',(x+math.cos(angle)*.06,y-.07,z+math.sin(angle)*.06),(.045,.025,.045),p['Ivory blossom'],segments=8,rings=4)
        art.sphere('Golden flower heart',(x,y-.085,z),(.028,.02,.028),p['Golden flower'],segments=8,rings=4)
finish('courtyard_course_ivy')
