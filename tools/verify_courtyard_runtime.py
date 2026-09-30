"""Exit successfully only when the checked-in runtime matches source and optimizer."""
import hashlib,json,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
try:
    report=json.loads((root/'art/source/world/runtime_optimization.json').read_text())
    digest=lambda path:hashlib.sha256((root/path).read_bytes()).hexdigest()
    assert report['optimizer_version']==2
    assert report['source_sha256']==digest('art/source/world/courtyard_environment.blend')
    assert report['optimizer_sha256']==digest('tools/blender/optimize_courtyard.py')
    assert all(digest(path)==sha for path,sha in report['runtime_files'].items())
except (OSError,KeyError,AssertionError,ValueError):sys.exit(1)
print('COURTYARD_RUNTIME_VERIFIED')
