"""Small deterministic tiling albedo maps for the existing terrain material system."""
from pathlib import Path
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[1]/'assets/terrain'
root.mkdir(parents=True,exist_ok=True)
random=np.random.default_rng(916)
grain=random.normal(0,1,(512,512))
coarse=np.repeat(np.repeat(random.normal(0,1,(32,32)),16,axis=0),16,axis=1)
for shift in range(1,9):coarse=(coarse+np.roll(coarse,1,0)+np.roll(coarse,1,1))/3
for name,base,variation in [('grass',(91,112,63),8),('earth',(104,86,66),7),('snow',(185,199,203),4)]:
    colors=np.clip(np.array(base)+((grain*.3+coarse)*variation)[:,:,None],0,255).astype(np.uint8)
    Image.fromarray(colors).save(root/('terrain_'+name+'.png'))
