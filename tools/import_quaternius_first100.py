"""Prepare selected CC0 Standard glTF meshes with shared mobile textures.
Usage: python3 tools/import_quaternius_first100.py --village ZIP --props ZIP
Only the listed files are included. Geometry is fitted to unit bounds; UVs and
mesh detail are retained. Shared textures are resized, never embedded per mesh.
"""
import argparse, hashlib, json, struct, zipfile
from io import BytesIO
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/vendor/quaternius'
SELECTION = {
 'village': {
  'stone': 'Prop_Brick1', 'stone_alt': 'Prop_Brick2',
  'paving': 'Floor_Brick', 'wall': 'Wall_UnevenBrick_Straight',
  'window': 'Wall_UnevenBrick_Window_Wide_Round',
  'arch': 'Wall_UnevenBrick_Door_Round', 'door': 'Door_1_Round',
  'ivy': 'Prop_Vine1', 'ivy_alt': 'Prop_Vine4',
  'fence': 'Prop_WoodenFence_Single', 'stairs': 'Stairs_Exterior_Straight',
 },
 'props': {
  'crate': 'Crate_Wooden', 'barrel': 'Barrel', 'banner': 'Banner_1',
  'bench': 'Bench', 'cart': 'Stall_Cart_Empty', 'lantern': 'Lantern_Wall',
 }
}

def prepare(pack, path):
 z=zipfile.ZipFile(path)
 license_name=next(n for n in z.namelist() if n.endswith('License_Standard.txt'))
 license_data=z.read(license_name)
 if b'CC0 1.0 Universal' not in license_data: raise ValueError('Expected pack-specific CC0 license')
 (OUT/f'{pack}_LICENSE.txt').write_bytes(license_data)
 base=next(n.rsplit('/',1)[0]+'/' for n in z.namelist() if n.endswith('/'+next(iter(SELECTION[pack].values()))+'.gltf'))
 textures=set(); records=[]
 for target,name in SELECTION[pack].items():
  d=json.loads(z.read(base+name+'.gltf'))
  assert len(d['nodes'])==1 and 'mesh' in d['nodes'][0],name
  positions={p['attributes']['POSITION'] for m in d['meshes'] for p in m['primitives']}
  lows=[min(d['accessors'][a]['min'][k] for a in positions) for k in range(3)]
  highs=[max(d['accessors'][a]['max'][k] for a in positions) for k in range(3)]
  size=[highs[k]-lows[k] for k in range(3)]
  centered=target in ('stone','stone_alt','paving')
  buffers=[bytearray(z.read(base+b['uri'])) for b in d['buffers']]
  for a in positions:
   acc=d['accessors'][a]; view=d['bufferViews'][acc['bufferView']]
   assert acc['componentType']==5126 and acc['type']=='VEC3'
   start=view.get('byteOffset',0)+acc.get('byteOffset',0); stride=view.get('byteStride',12)
   buf=buffers[view['buffer']]
   for i in range(acc['count']):
    old=struct.unpack_from('<3f',buf,start+i*stride)
    new=[(old[k]-lows[k])/size[k]-(.5 if k!=1 or centered else 0) for k in range(3)]
    struct.pack_into('<3f',buf,start+i*stride,*new)
   acc['min']=[-.5, -.5 if centered else 0, -.5];acc['max']=[.5,.5 if centered else 1,.5]
  # Scaling is baked into vertex positions. Recalculate normals for anisotropic fitting.
  normal_ids={p['attributes']['NORMAL'] for m in d['meshes'] for p in m['primitives'] if 'NORMAL' in p['attributes']}
  for a in normal_ids:
   acc=d['accessors'][a];view=d['bufferViews'][acc['bufferView']];start=view.get('byteOffset',0)+acc.get('byteOffset',0);stride=view.get('byteStride',12);buf=buffers[view['buffer']]
   for i in range(acc['count']):
    old=struct.unpack_from('<3f',buf,start+i*stride);new=[old[k]*size[k] for k in range(3)];length=sum(v*v for v in new)**.5
    struct.pack_into('<3f',buf,start+i*stride,*[v/max(length,1e-9) for v in new])
  for node in d['nodes']:
   for key in ['translation','rotation','scale','matrix']: node.pop(key,None)
  for i,b in enumerate(d['buffers']):
   b['uri']=f'{target}_{i}.bin';(OUT/b['uri']).write_bytes(buffers[i])
  for im in d.get('images',[]):
   old=im['uri'];textures.add(old);im['uri']=f'{pack}_{old}'
  for mat in d.get('materials',[]):
   # Warm ivory limestone, neutral wood and metal. Rough surfaces stay readable.
   if pack=='village' and target not in ('ivy','ivy_alt','fence','door'):
    mat.setdefault('pbrMetallicRoughness',{})['baseColorFactor']=[.78,.68,.50,1.0]
   if target in ('ivy','ivy_alt'):
    mat['pbrMetallicRoughness']['baseColorFactor']=[.025,.12,.006,1.0]
  (OUT/f'{target}.gltf').write_text(json.dumps(d,separators=(',',':'))+'\n')
  records.append({'id':target,'original':base+name+'.gltf','original_size':size,'normalized_origin':'center' if centered else 'bottom_center'})
 for filename in sorted(textures):
  im=Image.open(BytesIO(z.read(base+filename)))
  limit=1024 if 'BaseColor' in filename or 'Leaf' in filename else 512
  if im.mode not in ('RGB','RGBA','L'): im=im.convert('RGB')
  im.thumbnail((limit,limit),Image.Resampling.LANCZOS)
  im.save(OUT/f'{pack}_{filename}',optimize=True)
 return {'source_sha256':hashlib.sha256(Path(path).read_bytes()).hexdigest(),'license':f'{pack}_LICENSE.txt','models':records,'texture_limit':{'color':1024,'normal_roughness':512}}

if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--village',required=True);parser.add_argument('--props',required=True);args=parser.parse_args()
 OUT.mkdir(parents=True,exist_ok=True)
 manifest={key:prepare(key,getattr(args,key)) for key in SELECTION}
 manifest['sources']={'village':'https://quaternius.itch.io/medieval-village-megakit','props':'https://quaternius.itch.io/fantasy-props-megakit'}
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print('QUATERNIUS_IMPORT_OK',sum(p.stat().st_size for p in OUT.iterdir()),'bytes')
