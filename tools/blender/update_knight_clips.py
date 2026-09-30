"""Update clips on the packed, baked knight without rebuilding the geometry."""
import bpy, math, ast
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/knight_study.blend'))
rig=bpy.data.objects['KnightRig'];scene=bpy.context.scene;scene.render.fps=30
rig.animation_data_clear()
for action in list(bpy.data.actions):bpy.data.actions.remove(action)
rig.animation_data_create()
tree=ast.parse((ROOT/'tools/blender/prepare_game_assets.py').read_text())
names=['clip','idle','run','attack','block','jump']
code=ast.Module(body=[node for node in tree.body if isinstance(node,ast.FunctionDef) and node.name in names],type_ignores=[])
exec(compile(code,'shared_knight_clips','exec'))
for name,frames,pose in [('idle',61,idle),('run',25,run),('attack',12,attack),('block',16,block),('jump',22,jump)]:clip(name,frames,pose)
for bone in rig.pose.bones:bone.rotation_euler=(0,0,0);bone.location=(0,0,0)
scene.frame_set(1)
bpy.ops.object.select_all(action='DESELECT')
runtime=bpy.data.objects['KnightRuntime'];runtime.hide_set(False)
runtime.select_set(True);rig.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/knight_study.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_yup=True,export_force_sampling=True)
runtime.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/source/knight_study.blend'),compress=True)
print('KNIGHT_GUARD_AND_SLASH_UPDATED',flush=True)
