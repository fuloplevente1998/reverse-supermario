"""Keep the large courtyard scene in small, standard glTF buffer files.

Preserves geometry, materials and hierarchy without lossy mesh compression.
Run after Blender export. Godot loads courtyard_environment.gltf directly.
"""
import json, struct
from pathlib import Path

def split(path):
    path=Path(path);data=path.read_bytes()
    length=struct.unpack_from('<I',data,12)[0]
    doc=json.loads(data[20:20+length]);start=20+length
    bin_length=struct.unpack_from('<I',data,start)[0]
    payload=data[start+8:start+8+bin_length]
    chunks=[bytearray()];limit=4*1024*1024
    for view in doc['bufferViews']:
        old_offset=view.get('byteOffset',0);size=view['byteLength']
        if size>limit:raise ValueError('Single view exceeds chunk budget')
        padding=(-len(chunks[-1]))%4
        if len(chunks[-1])+padding+size>limit:chunks.append(bytearray());padding=0
        chunks[-1].extend(b'\0'*padding)
        view['buffer']=len(chunks)-1;view['byteOffset']=len(chunks[-1])
        chunks[-1].extend(payload[old_offset:old_offset+size])
    doc['buffers']=[]
    for i,chunk in enumerate(chunks):
        target=path.with_name(path.stem+'_part%d.bin'%i);target.write_bytes(chunk)
        doc['buffers'].append({'uri':target.name,'byteLength':len(chunk)})
    target=path.with_suffix('.gltf');target.write_text(json.dumps(doc,separators=(',',':')))
    path.unlink()
    return target.stat().st_size+sum(len(x) for x in chunks)

if __name__=='__main__':
    root=Path(__file__).resolve().parents[2]
    print('COURTYARD_SPLIT_BYTES',split(root/'assets/models/courtyard_environment.glb'))
