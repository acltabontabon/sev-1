#!/usr/bin/env python3
"""Retrieve and checksum the official CC0 Operations light; embed unchanged glTF data."""
from pathlib import Path
import hashlib
import json
import struct
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/environment/operations'
URL = 'https://api.polyhaven.com/files/caged_hanging_light'


def fetch(url, path):
    subprocess.run(['curl', '-L', '--fail', '-s', '-A', 'Mozilla/5.0', url, '-o', str(path)], check=True)
    return path.read_bytes()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    records = []
    with tempfile.TemporaryDirectory(prefix='sev1_operations_') as temp:
        work = Path(temp)
        manifest = json.loads(fetch(URL, work / 'manifest.json'))['gltf']['1k']['gltf']
        for name, entry in {'light.gltf': manifest, **manifest['include']}.items():
            target = work / name
            target.parent.mkdir(parents=True, exist_ok=True)
            data = fetch(entry['url'], target)
            if hashlib.md5(data).hexdigest() != entry['md5']:
                raise ValueError(f'Checksum mismatch: {name}')
            records.append({'file': name, 'url': entry['url'], 'md5': entry['md5'], 'sha256': hashlib.sha256(data).hexdigest()})
        doc = json.loads((work / 'light.gltf').read_text())
        blob = bytearray((work / doc['buffers'][0]['uri']).read_bytes())
        for image in doc['images']:
            data = (work / image.pop('uri')).read_bytes()
            blob.extend(b'\0' * (-len(blob) % 4))
            image['bufferView'] = len(doc['bufferViews'])
            image['mimeType'] = 'image/jpeg'
            doc['bufferViews'].append({'buffer': 0, 'byteOffset': len(blob), 'byteLength': len(data)})
            blob.extend(data)
        doc['buffers'] = [{'byteLength': len(blob)}]
        encoded = json.dumps(doc, separators=(',', ':')).encode()
        encoded += b' ' * (-len(encoded) % 4)
        blob.extend(b'\0' * (-len(blob) % 4))
        result = struct.pack('<III', 0x46546C67, 2, 28 + len(encoded) + len(blob))
        result += struct.pack('<II', len(encoded), 0x4E4F534A) + encoded
        result += struct.pack('<II', len(blob), 0x004E4942) + blob
        (OUT / 'caged_hanging_light.glb').write_bytes(result)
        (OUT / 'provenance.json').write_text(json.dumps({'source': 'https://polyhaven.com/a/caged_hanging_light', 'author': 'Ulan Cabanilla', 'license': 'CC0-1.0', 'retrieved': '2026-10-11', 'resolution': '1K', 'conversion': 'Unchanged mesh buffers and JPEG maps embedded in GLB', 'files': records, 'glb_sha256': hashlib.sha256(result).hexdigest()}, indent=2) + '\n')
        print(f'Packed {len(result)} bytes; verified {len(records)} source files.')


if __name__ == '__main__':
    main()
