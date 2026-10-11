"""Convert Lucian Pavel's CC0 archive with Blender; no runtime dependency.

Blender -b --python tools/build_heavy_greatsword.py -- /path/to/Heavy\ Sword.zip
"""
from pathlib import Path
import hashlib
import json
import re
import struct
import sys
import tempfile
import zipfile

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
archive = Path(sys.argv[sys.argv.index('--') + 1])
expected = '38ca37c5b59e784d84b831baf879dfdb4cd319d9ad23cd1e3ac1b2f813c57753'
assert hashlib.sha256(archive.read_bytes()).hexdigest() == expected, 'Unexpected source archive'
out = ROOT / 'assets/characters/heavy_greatsword'
out.mkdir(parents=True, exist_ok=True)

with tempfile.TemporaryDirectory(prefix='sev1_sword_') as temporary:
    source = Path(temporary)
    with zipfile.ZipFile(archive) as package:
        package.extractall(source)
    bpy.ops.wm.open_mainfile(filepath=str(source / 'Heavy Sword.blend'))
    sword = bpy.data.objects['Heavy Sword']
    for obj in list(bpy.data.objects):
        if obj != sword:
            bpy.data.objects.remove(obj, do_unlink=True)
    # Keep the authored low-poly export mesh, not the offset baking copies.
    sword.name = 'HeavyGreatsword'
    # The old authoring file keeps this export mesh on a hidden legacy layer.
    for collection in list(sword.users_collection):
        collection.objects.unlink(sword)
    bpy.context.scene.collection.objects.link(sword)
    sword.hide_set(False)
    sword.hide_viewport = False
    sword.hide_render = False
    sword.hide_select = False
    coordinates = [sword.matrix_world @ vertex.co for vertex in sword.data.vertices]
    near = min(v.z for v in coordinates)
    far = max(v.z for v in coordinates)
    center_x = (min(v.x for v in coordinates) + max(v.x for v in coordinates)) * .5
    scale = 2.35 / (far - near)
    for vertex, position in zip(sword.data.vertices, coordinates):
        # Rotate without mirroring; Blender +Z becomes glTF/Godot +Y on export.
        vertex.co = Vector((-(position.x - center_x) * scale,
                            (position.z - near) * scale - .03, position.y * scale))
    sword.matrix_world.identity()
    material = bpy.data.materials.new('WornGreatsword')
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    shader = nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value = .62

    def texture(filename, color=False):
        image = bpy.data.images.load(str(source / 'Textures' / filename))
        image.name = {'Heavy Sword.png': 'albedo', 'Heavy Sword_MET.png': 'metallic',
                      'Heavy Sword_NRM.png': 'normal', 'Heavy Sword_AO.png': 'occlusion'}[filename]
        image.colorspace_settings.name = 'sRGB' if color else 'Non-Color'
        image.pack()
        node = nodes.new('ShaderNodeTexImage')
        node.image = image
        return node

    color = texture('Heavy Sword.png', True)
    metal = texture('Heavy Sword_MET.png')
    normal = texture('Heavy Sword_NRM.png')
    ao = texture('Heavy Sword_AO.png')
    links.new(color.outputs['Color'], shader.inputs['Base Color'])
    links.new(metal.outputs['Color'], shader.inputs['Metallic'])
    normal_map = nodes.new('ShaderNodeNormalMap')
    links.new(normal.outputs['Color'], normal_map.inputs['Color'])
    links.new(normal_map.outputs['Normal'], shader.inputs['Normal'])
    # glTF exporter convention for a separate occlusion map.
    group = bpy.data.node_groups.new('glTF Material Output', 'ShaderNodeTree')
    group.interface.new_socket(name='Occlusion', in_out='INPUT', socket_type='NodeSocketFloat')
    output = nodes.new('ShaderNodeGroup')
    output.node_tree = group
    links.new(ao.outputs['Color'], output.inputs['Occlusion'])
    sword.data.materials.clear()
    sword.data.materials.append(material)
    bpy.context.view_layer.objects.active = sword
    sword.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out / 'heavy_greatsword.glb'),
                              export_format='GLB', use_selection=True,
                              export_yup=True, export_animations=False)
    # Blender derives some image names from source filenames despite image.name.
    # Normalize metadata before Godot extracts embedded textures into source files.
    destination = out / 'heavy_greatsword.glb'
    data = destination.read_bytes()
    length = struct.unpack_from('<I', data, 12)[0]
    document = json.loads(data[20:20 + length])
    for image in document['images']:
        image['name'] = re.sub(r'[^a-z0-9]+', '_', image['name'].lower()).strip('_')
    metadata = json.dumps(document, separators=(',', ':')).encode()
    metadata += b' ' * (-len(metadata) % 4)
    binary = data[20 + length:]
    destination.write_bytes(struct.pack('<III', 0x46546c67, 2, 20 + len(metadata) + len(binary))
                            + struct.pack('<II', len(metadata), 0x4e4f534a) + metadata + binary)
    print('Exported Heavy Greatsword: 2338 source triangles, 2.35 m, embedded 2K maps')
