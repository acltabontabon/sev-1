"""Convert the locally downloaded Fab idle archive for the isolated vault trial.

Blender --background --factory-startup --python tools/build_reaper_trial.py --
--source DIR. Source scripts are disabled. See assets/enemies/reaper_trial/README.md.
"""
import argparse
from pathlib import Path
import sys
import bpy
from mathutils import Vector

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
out = Path(__file__).resolve().parents[1] / 'assets/enemies/reaper_trial/abyssal_reaper.glb'
bpy.ops.wm.open_mainfile(filepath=str(args.source / 'Idle.blend'), use_scripts=False)
mesh = next(o for o in bpy.data.objects if o.type == 'MESH')
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
# The source connects RGB normal pixels directly to a normal socket. Use the
# tangent-space normal node required by glTF, preserving the supplied pixels.
material = mesh.data.materials[0]
nodes = material.node_tree.nodes
links = material.node_tree.links
shader = nodes.get('Principled BSDF')
for node in nodes:
    if node.type != 'TEX_IMAGE' or not node.image:
        continue
    filename = Path(node.image.filepath).name
    node.image.filepath = str(args.source / '1' / filename)
    node.image.reload()
    node.image.name = filename
    if filename != 'BaseColor.png':
        node.image.colorspace_settings.name = 'Non-Color'
    if filename == 'Normal.png':
        for link in list(shader.inputs['Normal'].links):
            links.remove(link)
        normal = nodes.new('ShaderNodeNormalMap')
        links.new(node.outputs['Color'], normal.inputs['Color'])
        links.new(normal.outputs['Normal'], shader.inputs['Normal'])
shader.inputs['Roughness'].default_value = .7
# Normalize both mesh and armature through a shared parent, keeping animation intact.
bpy.context.scene.frame_set(0)
bpy.context.view_layer.update()
points = [mesh.matrix_world @ Vector(p) for p in mesh.bound_box]
low = min(p.z for p in points)
height = max(p.z for p in points) - low
holder = bpy.data.objects.new('ReaperScale', None)
bpy.context.collection.objects.link(holder)
rig.parent = holder
factor = 3.52 / height
holder.scale = (factor,) * 3
holder.location.z = -low * factor + .12
rig.animation_data.action.name = 'Idle'
bpy.ops.object.select_all(action='DESELECT')
for o in [holder, rig, mesh]: o.select_set(True)
bpy.context.view_layer.objects.active = rig
out.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(out), export_format='GLB', use_selection=True,
                         export_animations=True, export_animation_mode='ACTIVE_ACTIONS',
                         export_force_sampling=True, export_cameras=False, export_lights=False)
print('EXPORTED', out, 'source height', height)
# ACTIVE_ACTIONS names the merged clip "Animation"; preserve a clear runtime role.
import json
import struct
binary = out.read_bytes()
length = struct.unpack_from('<I', binary, 12)[0]
document = json.loads(binary[20:20 + length])
assert len(document.get('animations', [])) == 1
document['animations'][0]['name'] = 'Idle'
payload = json.dumps(document, separators=(',', ':')).encode()
payload += b' ' * (-len(payload) % 4)
tail = binary[20 + length:]
out.write_bytes(struct.pack('<III', 0x46546c67, 2, 20 + len(payload) + len(tail))
                + struct.pack('<II', len(payload), 0x4e4f534a) + payload + tail)
