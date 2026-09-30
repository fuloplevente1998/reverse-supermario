"""Check actual evaluated cape deformation, not just existence of animation keys."""
import bpy, json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(root/'art/source/knight_study.blend'))
rig=bpy.data.objects['KnightRig'];cape=bpy.data.objects['Folded burgundy cape']
def vertices():
    deps=bpy.context.evaluated_depsgraph_get();deps.update()
    ev=cape.evaluated_get(deps)
    return [(ev.matrix_world @ v.co).copy() for v in ev.data.vertices]
rig.animation_data.action=None
for b in rig.pose.bones:b.rotation_euler=(0,0,0);b.location=(0,0,0)
bpy.context.view_layer.update();rest=vertices()
rig.animation_data.action=bpy.data.actions['run'];bpy.context.scene.frame_set(7)
bpy.context.view_layer.update();moving=vertices()
delta=max((a-b).length for a,b in zip(rest,moving))
assert delta>.03, 'Cape mesh must actually deform'
assert len(rig.data.bones)==17
report={'cape_max_displacement_m':round(delta,4),'cape_vertices':len(rest),'bones':17,'status':'passed'}
(root/'art/source/cape_verification.json').write_text(json.dumps(report,indent=2))
print('CAPE_DEFORMATION_OK',json.dumps(report))
