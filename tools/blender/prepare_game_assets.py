"""Bake the editable study, consolidate runtime meshes and add animation clips."""
import bpy, math, json
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/source'; MODELS=ROOT/'assets/models'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'knight_study.blend'))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1
scene.render.bake.margin=5
rig=bpy.data.objects['KnightRig']
source=[o for o in scene.objects if o.type=='MESH' and o.parent==rig]
sword=[o for o in scene.objects if o.name.startswith('Sword')]
shield=[o for o in scene.objects if o.name.startswith(('Kite shield','Shield'))]

# Three deforming cape bones, with a fixed shoulder attachment and blended hem.
bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
cape_joints=[('cape_upper',(0,.23,1.52),(0,.30,1.10),'chest'),
             ('cape_middle',(0,.30,1.10),(0,.38,.70),'cape_upper'),
             ('cape_lower',(0,.38,.70),(0,.43,.28),'cape_middle')]
for name,head,tail,parent in cape_joints:
    b=rig.data.edit_bones.new(name);b.head=head;b.tail=tail;b.parent=rig.data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
cape_objects=[o for o in source if o.name.startswith(('Folded burgundy cape','Cape gold edge','Cape crest'))]
for o in cape_objects:
    o.vertex_groups.clear()
    vg={n:o.vertex_groups.new(name=n) for n in ['chest','cape_upper','cape_middle','cape_lower']}
    for v in o.data.vertices:
        z=(o.matrix_world @ v.co).z
        if z>=1.42:
            chest=min(1,(z-1.42)/.10);weights={'chest':chest,'cape_upper':1-chest}
        elif z>=1.10:
            u=min(1,(1.42-z)/.32);weights={'cape_upper':1-u,'cape_middle':u}
        elif z>=.70:
            u=(1.10-z)/.40;weights={'cape_middle':1-u,'cape_lower':u}
        else:weights={'cape_lower':1.0}
        for name,w in weights.items():
            if w>0:vg[name].add([v.index],w,'REPLACE')

def combine_bake(name,parts,res):
    copies=[]
    for o in parts:
        c=o.copy();c.data=o.data.copy();bpy.context.collection.objects.link(c);copies.append(c)
    bpy.ops.object.select_all(action='DESELECT')
    for c in copies:c.select_set(True)
    bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join()
    obj=bpy.context.object;obj.name=name
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.007)
    bpy.ops.object.mode_set(mode='OBJECT')
    mats=list(set(obj.data.materials));maps={}
    for kind in ['color','normal','roughness','metallic']:
        img=bpy.data.images.new(name+'_'+kind,width=res,height=res,alpha=False)
        if kind!='color':img.colorspace_settings.name='Non-Color'
        targets=[];outputs=[]
        for m in mats:
            n=m.node_tree.nodes;links=m.node_tree.links
            target=n.new('ShaderNodeTexImage');target.image=img;n.active=target;targets.append((m,target))
            if kind in ['roughness','metallic']:
                p=n.get('Principled BSDF');out=next(x for x in n if x.type=='OUTPUT_MATERIAL')
                emit=n.new('ShaderNodeEmission');value=p.inputs[kind.capitalize()].default_value
                socket=p.inputs[kind.capitalize()]
                if socket.is_linked:links.new(socket.links[0].from_socket,emit.inputs['Color'])
                else:emit.inputs['Color'].default_value=(value,value,value,1)
                old=out.inputs['Surface'].links[0].from_socket
                links.new(emit.outputs[0],out.inputs['Surface']);outputs.append((m,out,old,emit))
        if kind=='color':bpy.ops.object.bake(type='DIFFUSE',pass_filter={'COLOR'})
        elif kind=='normal':bpy.ops.object.bake(type='NORMAL')
        else:bpy.ops.object.bake(type='EMIT')
        img.filepath_raw=str(OUT/(name+'_'+kind+'.png'));img.file_format='PNG';img.save();img.pack();maps[kind]=img
        for m,out,old,emit in outputs:m.node_tree.links.new(old,out.inputs['Surface']);m.node_tree.nodes.remove(emit)
        for m,target in targets:m.node_tree.nodes.remove(target)
    atlas=bpy.data.materials.new(name+' baked PBR');atlas.use_nodes=True
    p=atlas.node_tree.nodes.get('Principled BSDF');n=atlas.node_tree.nodes;links=atlas.node_tree.links
    for kind,socket in [('color','Base Color'),('roughness','Roughness'),('metallic','Metallic')]:
        t=n.new('ShaderNodeTexImage');t.image=maps[kind];links.new(t.outputs['Color'],p.inputs[socket])
    t=n.new('ShaderNodeTexImage');t.image=maps['normal'];normal=n.new('ShaderNodeNormalMap')
    links.new(t.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs[0],p.inputs['Normal'])
    obj.data.materials.clear();obj.data.materials.append(atlas)
    for poly in obj.data.polygons:poly.material_index=0
    return obj

runtime=combine_bake('KnightRuntime',source,1024)
runtime_sword=combine_bake('SwordRuntime',sword,512)
runtime_shield=combine_bake('ShieldRuntime',shield,512)
# Runtime weapons need local hand attachment coordinates.
runtime_sword.location.x-=1.35;runtime_shield.location.x+=1.25

scene.render.fps=30
rig.animation_data_create()
def clip(name,frames,pose):
    action=bpy.data.actions.new(name);rig.animation_data.action=action
    for frame in range(1,frames+1):
        t=(frame-1)/(frames-1)
        for bone in rig.pose.bones:
            bone.rotation_mode='XYZ';bone.rotation_euler=(0,0,0);bone.location=(0,0,0)
        pose(t)
        for i,bone_name in enumerate(['cape_upper','cape_middle','cape_lower']):
            amp={'idle':.025,'run':.16,'attack':.12,'block':.04,'jump':.20}[name]
            loop=name in ['idle','run']
            wave=math.sin(t*math.tau-i*.35) if loop else math.sin(t*math.pi)
            rig.pose.bones[bone_name].rotation_euler.x=amp*(.5+wave)
            rig.pose.bones[bone_name].rotation_euler.z=amp*.25*math.sin(t*math.tau+i*.4) if loop else amp*.2*wave
        for bone in rig.pose.bones:
            bone.keyframe_insert(data_path='rotation_euler',frame=frame,group=bone.name)
            bone.keyframe_insert(data_path='location',frame=frame,group=bone.name)
    action.use_fake_user=True
    track=rig.animation_data.nla_tracks.new();track.name=name
    strip=track.strips.new(name,1,action);strip.name=name;track.mute=True
    rig.animation_data.action=None
    return action

def idle(t):
    wave=math.sin(t*math.tau)
    rig.pose.bones['chest'].rotation_euler.x=wave*.025
    rig.pose.bones['head'].rotation_euler.z=wave*.02
def run(t):
    w=math.sin(t*math.tau)
    rig.pose.bones['pelvis'].location.y=abs(w)*.035
    rig.pose.bones['chest'].rotation_euler.x=.12
    for s,suffix in [(-1,'L'),(1,'R')]:
        rig.pose.bones['thigh.'+suffix].rotation_euler.x=w*s*.55
        rig.pose.bones['shin.'+suffix].rotation_euler.x=max(0,-w*s)*.72
        rig.pose.bones['upper_arm.'+suffix].rotation_euler.x=-w*s*.40
        rig.pose.bones['forearm.'+suffix].rotation_euler.x=-.22
def attack(t):
    swing=math.sin(t*math.pi)
    rig.pose.bones['chest'].rotation_euler.z=-swing*.45
    rig.pose.bones['upper_arm.R'].rotation_euler.x=-swing*1.45
    rig.pose.bones['upper_arm.R'].rotation_euler.z=-swing*.35
    rig.pose.bones['forearm.R'].rotation_euler.x=-swing*.35
def block(t):
    strength=min(1,t*5)
    rig.pose.bones['upper_arm.L'].rotation_euler.x=-strength*.9
    rig.pose.bones['upper_arm.L'].rotation_euler.z=-strength*.45
    rig.pose.bones['forearm.L'].rotation_euler.x=-strength*.85
    rig.pose.bones['head'].rotation_euler.x=strength*.08
def jump(t):
    bend=math.sin(t*math.pi)
    rig.pose.bones['thigh.L'].rotation_euler.x=-bend*.5
    rig.pose.bones['thigh.R'].rotation_euler.x=-bend*.4
    rig.pose.bones['shin.L'].rotation_euler.x=bend*.8
    rig.pose.bones['shin.R'].rotation_euler.x=bend*.7
    rig.pose.bones['upper_arm.L'].rotation_euler.z=bend*.15
    rig.pose.bones['upper_arm.R'].rotation_euler.z=-bend*.15

for name,frames,pose in [('idle',61,idle),('run',25,run),('attack',12,attack),('block',16,block),('jump',22,jump)]:clip(name,frames,pose)
for bone in rig.pose.bones:bone.rotation_euler=(0,0,0);bone.location=(0,0,0)
scene.frame_set(1)

def export(path,items,anim=False):
    bpy.ops.object.select_all(action='DESELECT')
    for o in items:o.hide_set(False);o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=anim,export_animation_mode='ACTIONS',export_yup=True,export_force_sampling=True)
export(MODELS/'knight_study.glb',[runtime,rig],True)
export(MODELS/'broadsword_study.glb',[runtime_sword])
export(MODELS/'kite_shield_study.glb',[runtime_shield])
for o in [runtime,runtime_sword,runtime_shield]:o.hide_render=True;o.hide_set(True)
scene.cycles.samples=32
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'knight_study.blend'))
cam=scene.camera
for name,loc in [('front',(0,-7,2.25)),('three_quarter',(3,-6,2.9)),('back',(-3,6,2.7))]:
    cam.location=loc;cam.rotation_euler=(Vector((0,0,1.13))-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(OUT/('knight_'+name+'.png'));bpy.ops.render.render(write_still=True)
stats={'stage':'Third modeling pass: weighted cape, armor crests and procedural wear', 'character_triangles':sum(len(p.vertices)-2 for p in runtime.data.polygons),'runtime_meshes':1,'runtime_materials':1,'texture_atlas':1024,'bones':len(rig.data.bones),'cape_bones':3,'animations':['idle','run','attack','block','jump'],'limitations':['Rigid armor weighting','Cape has authored bone motion, not cloth physics','Procedural wear, not hand-painted texture work']}
(OUT/'model_stats.json').write_text(json.dumps(stats,indent=2))
print(json.dumps(stats))
