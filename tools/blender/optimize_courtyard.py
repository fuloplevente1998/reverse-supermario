"""Build a light, spatially chunked runtime yard from the editable full-detail source.

The original .blend stays editable and is never overwritten. CI exports this
runtime before the Android build and publishes the buffers and measured counts.
"""
import bpy,json,math,sys,hashlib
from pathlib import Path
from mathutils import Matrix, Vector
sys.path.insert(0,str(Path(__file__).parent))
from split_courtyard_gltf import split
ROOT=Path(__file__).resolve().parents[2]
MODEL=ROOT/'assets/models/courtyard_environment.glb'
REPORT=ROOT/'art/source/world/runtime_optimization.json'
version=2
source_hash=hashlib.sha256((ROOT/'art/source/world/courtyard_environment.blend').read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/world/courtyard_environment.blend'))
before=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH')
groups={};removed=0
for obj in list(bpy.context.scene.objects):
    if obj.type!='MESH':continue
    parent=obj.parent;is_wall=False
    while parent:
        if parent.name.startswith('CurtainWallSection'):is_wall=True
        parent=parent.parent
    if is_wall or obj.name.startswith(('PerimeterStone','ParapetTooth','GardenStrip','LandscapeApron')):
        bpy.data.objects.remove(obj,do_unlink=True);removed+=1;continue
    matrix=obj.matrix_world.copy()
    center=matrix@obj.data.vertices[0].co
    # Each source part keeps its shape; shared groups cover 12-metre regions.
    if obj.name.startswith(('PavementBatch','PavementUnderlay')):key=obj.name
    else:
        centroid=matrix@obj.data.polygons[0].center
        key='SceneryRuntime_%d_%d'%(math.floor(centroid.x/12),math.floor(centroid.y/12))
    obj.parent=None;obj.data.transform(matrix);obj.matrix_world=Matrix.Identity(4)
    groups.setdefault(key,[]).append(obj)
runtime=[]
for key,objects in groups.items():
    bpy.ops.object.select_all(action='DESELECT')
    for obj in objects:obj.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    if len(objects)>1:bpy.ops.object.join()
    obj=bpy.context.object;obj.name=key
    if key.startswith('SceneryRuntime'):
        modifier=obj.modifiers.new('Mobile simplified bevels and foliage','DECIMATE')
        modifier.ratio=.32;modifier.use_collapse_triangulate=True
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        corners=[obj.matrix_world@vertex for vertex in [Vector(corner) for corner in obj.bound_box]]
        center=sum(corners,Vector())/8
        obj.data.transform(Matrix.Translation(-center));obj.location=center
    runtime.append(obj)
bpy.ops.object.select_all(action='DESELECT')
for obj in runtime:obj.select_set(True)
for stale in MODEL.parent.glob('courtyard_environment_part*.bin'):stale.unlink()
bpy.ops.export_scene.gltf(filepath=str(MODEL),export_format='GLB',use_selection=True,export_apply=True)
size=split(MODEL)
after=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in runtime)
report={'optimizer_version':version,'source_sha256':source_hash,'optimizer_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'source_triangles':before,'runtime_triangles':after,'runtime_meshes':len(runtime),'removed_edge_pieces':removed,'runtime_bytes':size,'triangle_reduction_percent':round((1-after/before)*100,1)}
files=[MODEL.with_suffix('.gltf')]+list(MODEL.parent.glob('courtyard_environment_part*.bin'))
report['runtime_files']={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
REPORT.write_text(json.dumps(report,indent=2));print('COURTYARD_OPTIMIZATION_OK',json.dumps(report),flush=True)
