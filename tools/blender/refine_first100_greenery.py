"""Refine our existing courtyard cypress for the first-100m asset sample."""
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/world/courtyard_course/courtyard_course_cypress.blend'))
for obj in bpy.context.scene.objects:
 if obj.type!='MESH':continue
 for polygon in obj.data.polygons:
  mat=obj.data.materials[polygon.material_index]
  if 'Leaf' in mat.name or 'Cypress' in mat.name:polygon.use_smooth=True
 for mat in obj.data.materials:
  if 'Leaf' in mat.name or 'Cypress' in mat.name:
   mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.020,.055,.010,1)
name='courtyard_first100_cypress'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/f'art/source/world/courtyard_course/{name}.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/f'assets/models/{name}.glb'),export_format='GLB',export_animations=False)
