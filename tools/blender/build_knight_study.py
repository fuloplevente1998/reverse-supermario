"""Reproducible mockup-guided hard-surface study. Run with Blender --background --python.
This is a first modeling pass, not a finished textured game character.
"""
import bpy, math, json, bmesh
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art/source'
MODELS = ROOT / 'assets/models'
OUT.mkdir(parents=True, exist_ok=True)
MODELS.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

def material(name, color, metal=0, rough=.6):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Metallic'].default_value=metal; p.inputs['Roughness'].default_value=rough
    n=m.node_tree.nodes; links=m.node_tree.links
    tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=95 if metal else 180
    tex.inputs['Detail'].default_value=2
    ramp=n.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].color=(*(c*.72 for c in color),1)
    ramp.color_ramp.elements[1].color=(*color,1)
    links.new(tex.outputs['Fac'],ramp.inputs[0]);links.new(ramp.outputs['Color'],p.inputs['Base Color'])
    bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.15
    bump.inputs['Distance'].default_value=.007 if metal else .002
    links.new(tex.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs[0],p.inputs['Normal'])
    return m

steel=material('Charcoal forged steel',(.075,.09,.115),.72,.48)
gold=material('Muted antique brass',(.48,.29,.10),.7,.44)
dark=material('Dark flexible joints',(.024,.027,.035),.1,.85)
red=material('Burgundy cloth',(.23,.016,.038),0,.94)
eye=material('Amber eyes',(.95,.28,.018),.1,.4)
blue=material('Royal blue shield',(.018,.075,.22),.1,.68)
objects=[]; groups={}

def finish(o,name,mat,bone='chest',bevel=0):
    o.name=name; o.data.materials.append(mat)
    bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=bm.faces);bm.to_mesh(o.data);bm.free()
    if bevel:
        mod=o.modifiers.new('Small forged edge','BEVEL');mod.width=bevel;mod.segments=2
        bpy.context.view_layer.objects.active=o
        bpy.ops.object.modifier_apply(modifier=mod.name)
        for p in o.data.polygons:p.use_smooth=True
        normal=o.modifiers.new('Weighted armor normals','WEIGHTED_NORMAL');normal.keep_sharp=True
        bpy.ops.object.modifier_apply(modifier=normal.name)
    objects.append(o);groups[o.name]=bone
    return o

def mesh(name,verts,faces,mat,bone='chest',bevel=0):
    m=bpy.data.meshes.new(name);m.from_pydata(verts,[],faces);m.update()
    o=bpy.data.objects.new(name,m);bpy.context.collection.objects.link(o)
    return finish(o,name,mat,bone,bevel)

def box(name,loc,size,mat,bone='chest',bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,mat,bone,bevel)

def ellipsoid(name,loc,size,mat,bone='chest'):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,location=loc)
    o=bpy.context.object;o.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return finish(o,name,mat,bone)

def plate(name,outline,depth,mat,bone='chest',bevel=.012):
    # Outline is in 3D; thickness extends backward along Y. Front faces -Y.
    n=len(outline);v=list(outline)+[(x,y+depth,z) for x,y,z in outline]
    f=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    f += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,v,f,mat,bone,bevel)

def rimmed(name,outline,mat,bone='chest',depth=.06):
    c=Vector(tuple(sum(v[k] for v in outline)/len(outline) for k in range(3)))
    inner=[]
    for v in outline:
        p=c+(Vector(v)-c)*.89;inner.append(tuple(p))
    # A real perimeter ring avoids overlapping solid plates and gold patches.
    n=len(outline)
    border=mesh(name+' brass rim',list(outline)+inner,
        [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],gold,bone)
    solid=border.modifiers.new('Rim thickness','SOLIDIFY');solid.thickness=.012
    bpy.context.view_layer.objects.active=border;bpy.ops.object.modifier_apply(modifier=solid.name)
    inner=[(x,y-.008,z) for x,y,z in inner]
    return plate(name,inner,depth,mat,bone)

def tube(name,centers,radii,mat,bone='head',segments=10):
    verts=[]
    for i,c in enumerate(centers):
        tangent=Vector(centers[min(i+1,len(centers)-1)])-Vector(centers[max(0,i-1)])
        tangent.normalize();u=tangent.cross(Vector((0,1,0))).normalized();v=tangent.cross(u)
        for j in range(segments):
            a=j*2*math.pi/segments;verts.append(tuple(Vector(c)+radii[i]*(math.cos(a)*u+math.sin(a)*v)))
    faces=[]
    for i in range(len(centers)-1):
        for j in range(segments):
            a=i*segments+j;b=i*segments+(j+1)%segments;faces.append((a,b,b+segments,a+segments))
    faces += [tuple(range(segments-1,-1,-1)),tuple(range((len(centers)-1)*segments,len(verts)))]
    return mesh(name,verts,faces,mat,bone)

# Broad silhouette, flatter breastplate, visibly separate armor layers.
ellipsoid('Under armor torso',(0,0,1.22),(.38,.23,.42),dark)
ellipsoid('Pelvis',(0,0,.83),(.31,.21,.2),dark,'pelvis')
rimmed('Breastplate',[(-.34,-.21,1.50),(0,-.32,1.57),(.34,-.21,1.50),(.29,-.31,1.20),(0,-.36,1.10),(-.29,-.31,1.20)],steel)
for j in range(3):
    z=1.15-j*.10;w=.30-j*.018
    rimmed('Abdominal lamella '+str(j),[(-w,-.25,z),(0,-.34,z-.03),(w,-.25,z),(w*.94,-.25,z-.095),(0,-.33,z-.13),(-w*.94,-.25,z-.095)],steel)
box('Leather belt',(0,0,.88),(.67,.48,.10),dark,'pelvis')
rimmed('Belt buckle',[(-.08,-.275,.94),(.08,-.275,.94),(.10,-.275,.84),(0,-.28,.81),(-.10,-.275,.84)],gold,'pelvis')
for s,suffix in [(-1,'L'),(1,'R')]:
    arm='upper_arm.'+suffix;fore='forearm.'+suffix;hand='hand.'+suffix
    thigh='thigh.'+suffix;shin='shin.'+suffix
    ellipsoid('Shoulder joint '+suffix,(s*.43,0,1.42),(.22,.21,.20),dark,arm)
    outline=[(s*.29,-.14,1.55),(s*.49,-.22,1.66),(s*.70,-.13,1.52),(s*.72,-.19,1.35),(s*.39,-.27,1.30)]
    rimmed('Angular pauldron '+suffix,outline,steel,arm,.25)
    for j in range(2):
        z=1.34-j*.075
        rimmed('Shoulder lames '+suffix+str(j),[(s*.39,-.21,z),(s*.72,-.13,z+.02),(s*.70,-.16,z-.07),(s*.42,-.24,z-.085)],steel,arm,.22)
    ellipsoid('Upper arm joint '+suffix,(s*.55,0,1.20),(.14,.14,.20),dark,arm)
    ellipsoid('Elbow '+suffix,(s*.62,-.015,1.08),(.15,.15,.12),steel,fore)
    rimmed('Vambrace '+suffix,[(s*.50,-.16,1.09),(s*.69,-.18,1.15),(s*.80,-.15,.89),(s*.59,-.20,.83)],steel,fore,.22)
    ellipsoid('Glove '+suffix,(s*.71,-.015,.78),(.12,.13,.13),dark,hand)
    box('Knuckle guard '+suffix,(s*.71,-.13,.80),(.23,.07,.11),steel,hand,.014)
    for j in range(3):box('Finger '+suffix+str(j),(s*.64+s*j*.052,-.09,.73),(.045,.09,.09),steel,hand,.011)
    ellipsoid('Thigh underlayer '+suffix,(s*.20,0,.66),(.16,.16,.25),dark,thigh)
    rimmed('Tasset '+suffix,[(s*.06,-.22,.85),(s*.31,-.18,.87),(s*.37,-.24,.63),(s*.16,-.27,.57),(s*.06,-.26,.65)],steel,thigh)
    rimmed('Knee cop '+suffix,[(s*.09,-.17,.53),(s*.22,-.27,.60),(s*.34,-.17,.52),(s*.29,-.27,.42),(s*.15,-.27,.42)],steel,shin,.17)
    ellipsoid('Shin underlayer '+suffix,(s*.22,0,.28),(.115,.12,.23),dark,shin)
    rimmed('Greave '+suffix,[(s*.11,-.14,.43),(s*.30,-.14,.43),(s*.34,-.13,.13),(s*.22,-.20,.09),(s*.09,-.13,.13)],steel,shin,.18)
    box('Armored boot '+suffix,(s*.22,-.09,.085),(.29,.43,.16),steel,shin,.045)
    for j in range(3):box('Sabatons '+suffix+str(j),(s*.22,-.13-j*.063,.155-j*.018),(.28,.07,.047),gold if j==2 else steel,shin,.01)

# Closed angular helmet with actual slit geometry over a dark inner shell.
ellipsoid('Helmet inner dark',(0,0,1.76),(.255,.22,.29),dark,'head')
rimmed('Helmet crown',[(-.26,-.15,1.83),(-.20,-.18,1.99),(0,-.24,2.10),(.20,-.18,1.99),(.26,-.15,1.83),(0,-.29,1.87)],steel,'head',.22)
for s in [-1,1]:
    rimmed('Visor cheek '+str(s),[(s*.025,-.29,1.83),(s*.23,-.20,1.81),(s*.22,-.23,1.61),(s*.07,-.29,1.55),(s*.025,-.31,1.64)],steel,'head',.14)
    plate('Angled eye '+str(s),[(s*.045,-.266,1.85),(s*.195,-.208,1.885),(s*.17,-.22,1.848),(s*.055,-.273,1.826)],.012,eye,'head',0)
    for j in range(2):box('Visor vent '+str(s)+str(j),(s*(.083+j*.067),-.310+j*.020,1.69),(.017,.018,.095),dark,'head',.004)
    centers=[(s*.22,0,1.96),(s*.34,0,1.98),(s*.40,0,2.09),(s*.38,0,2.21),(s*.31,0,2.30)]
    tube('Curved brass horn '+str(s),centers,[.092,.086,.065,.038,.002],gold)
plate('Central helmet ridge',[(0,-.25,2.105),(-.025,-.29,1.94),(0,-.33,1.87),(.025,-.29,1.94)],.025,gold,'head')

# Folded scarf, scalloped cape and geometric original emblem.
for j in range(3):
    tube('Scarf fold '+str(j),[(-.29,.05,1.59-j*.04),(-.25,-.22,1.58-j*.04),(0,-.30,1.55-j*.04),(.25,-.22,1.58-j*.04),(.29,.05,1.59-j*.04)],[.045]*5,red,'chest',12)
verts=[];faces=[];nx=12;nz=14
for iz in range(nz+1):
    t=iz/nz
    for ix in range(nx+1):
        u=ix/nx; x=(u-.5)*(.63+.36*t)
        z=1.56-1.27*t
        if iz==nz:z += .065*(ix%3==0)
        y=.20+.18*t+.038*math.sin(u*math.pi*8)*t
        verts.append((x,y,z))
for iz in range(nz):
    for ix in range(nx):
        a=iz*(nx+1)+ix;faces.append((a,a+1,a+nx+2,a+nx+1))
cape=mesh('Folded burgundy cape',verts,faces,red)
solid=cape.modifiers.new('Cloth thickness','SOLIDIFY');solid.thickness=.008
bpy.context.view_layer.objects.active=cape;bpy.ops.object.modifier_apply(modifier=solid.name)
for s in [-1,1]:tube('Cape gold edge '+str(s),[(s*(.315+.18*t),.20+.18*t,1.56-1.27*t) for t in [j/14 for j in range(15)]],[.009]*15,gold,'chest',6)
plate('Cape crest',[(0,.437,.94),(-.13,.43,1.03),(-.06,.44,.84),(0,.449,.64),(.06,.44,.84),(.13,.43,1.03)],.005,gold,'chest',0)
plate('Front tabard',[(-.115,-.28,.84),(.115,-.28,.84),(.12,-.29,.44),(0,-.31,.35),(-.12,-.29,.44)],.018,red,'pelvis')

# Simple rigid weighting for separate armor pieces. No cloth simulation claimed.
armdata=bpy.data.armatures.new('KnightRig');rig=bpy.data.objects.new('KnightRig',armdata)
bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bones=[('root',(0,0,0),(0,0,.3),None),('pelvis',(0,0,.78),(0,0,1.0),'root'),('chest',(0,0,1.0),(0,0,1.53),'pelvis'),('head',(0,0,1.53),(0,0,2.05),'chest')]
for s,suffix in [(-1,'L'),(1,'R')]:
    bones += [('upper_arm.'+suffix,(s*.40,0,1.45),(s*.62,0,1.08),'chest'),('forearm.'+suffix,(s*.62,0,1.08),(s*.71,0,.82),'upper_arm.'+suffix),('hand.'+suffix,(s*.71,0,.82),(s*.71,0,.69),'forearm.'+suffix),('thigh.'+suffix,(s*.20,0,.80),(s*.22,0,.48),'pelvis'),('shin.'+suffix,(s*.22,0,.48),(s*.22,0,.08),'thigh.'+suffix)]
for name,a,b,parent in bones:
    bone=armdata.edit_bones.new(name);bone.head=a;bone.tail=b
    if parent:bone.parent=armdata.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
for o in objects:
    vg=o.vertex_groups.new(name=groups[o.name]);vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
    mod=o.modifiers.new('Rigid armor binding','ARMATURE');mod.object=rig;o.parent=rig

character=list(objects)
def export(path,selection):
    bpy.ops.object.select_all(action='DESELECT')
    for o in selection:o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
export(MODELS/'knight_study.glb',character+[rig])

# Standalone weapons modeled in local origin; artist can parent to hand socket.
objects=[]
rimmed('Sword blade',[(-.11,0,.35),(.11,0,.35),(.16,0,1.05),(0,0,1.30),(-.16,0,1.05)],steel,'weapon',.07)
box('Sword crossguard',(0,.02,.30),(.47,.12,.09),gold,'weapon')
box('Sword grip',(0,.02,.15),(.095,.09,.24),red,'weapon',.016)
ellipsoid('Sword pommel',(0,.02,0),(.08,.065,.07),gold,'weapon')
sword=list(objects);export(MODELS/'broadsword_study.glb',sword)
for o in sword:o.location.x+=1.35
objects=[]
rimmed('Kite shield',[(-.29,0,.91),(.29,0,.91),(.32,0,.49),(0,-.04,0),(-.32,0,.49)],blue,'shield',.075)
plate('Shield crest',[(0,-.03,.79),(-.14,-.025,.59),(-.045,-.045,.61),(0,-.055,.26),(.045,-.045,.61),(.14,-.025,.59)],.012,gold,'shield')
box('Shield rear grip',(0,.13,.53),(.085,.08,.30),dark,'shield')
shield=list(objects);export(MODELS/'kite_shield_study.glb',shield)
for o in shield:o.location.x-=1.25

# Studio, saved as editable Blender scene. Camera renders real geometry.
floor=material('Studio floor',(.16,.18,.20),0,.85)
box('Studio floor',(0,0,-.065),(200,200,.1),floor,'studio',0)
world=bpy.data.worlds.new('Studio world');bpy.context.scene.world=world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.18,.20,.24,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.5
def light(name,loc,power,size):
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size
    o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.location=loc
    o.rotation_euler=(Vector((0,0,1.1))-o.location).to_track_quat('-Z','Y').to_euler()
light('Warm key',(-3,-4,5),650,4);light('Soft fill',(3,-2,3),450,3);light('Cape rim',(1,3,4),850,3)
camdata=bpy.data.cameras.new('Studio camera');cam=bpy.data.objects.new('Studio camera',camdata);bpy.context.collection.objects.link(cam)
scene=bpy.context.scene;scene.camera=cam;camdata.type='ORTHO';camdata.ortho_scale=3.9
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1100;scene.render.resolution_y=950;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
def camera(loc):
    cam.location=loc;cam.rotation_euler=(Vector((0,0,1.13))-cam.location).to_track_quat('-Z','Y').to_euler()
camera((3,-6,2.9))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'knight_study.blend'))
for name,loc in [('front',(0,-7,2.25)),('three_quarter',(3,-6,2.9)),('back',(-3,6,2.7))]:
    camera(loc);scene.render.filepath=str(OUT/('knight_'+name+'.png'));bpy.ops.render.render(write_still=True)
stats={'stage':'First hard-surface modeling pass; rigid binding; no animation clips or baked textures', 'character_meshes':len(character),'character_triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in character),'bones':len(bones),'reference':'image-gen-1(10).png; Várudvari összecsapás a kastélykapunál.png','exports':['knight_study.glb','broadsword_study.glb','kite_shield_study.glb']}
(OUT/'model_stats.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
print(json.dumps(stats))
