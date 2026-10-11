"""Export the two free demon trials with original, provisional review motions.

Run in Blender with --background --factory-startup --python this_file --
--night-source DIR --chain-source DIR. Download records live beside the GLBs.
No source-file scripts are enabled. No outside animation service is used.
"""
import argparse
import math
import json
import struct
from pathlib import Path
import sys

import bpy
from mathutils import Quaternion, Vector

parser = argparse.ArgumentParser()
parser.add_argument('--night-source', required=True)
parser.add_argument('--chain-source', required=True)
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
out = Path(__file__).resolve().parents[1] / 'assets/enemies/demon_trials'
out.mkdir(parents=True, exist_ok=True)


def normalize_texture_names(path):
    """Rename glTF image metadata only; preserve embedded pixels and binary buffer."""
    data = path.read_bytes()
    length = struct.unpack_from('<I', data, 12)[0]
    document = json.loads(data[20:20 + length])
    for image in document.get('images', []):
        image['name'] = 'normal' if 'normal' in image.get('name', '').lower() else 'albedo'
    payload = json.dumps(document, separators=(',', ':')).encode('utf-8')
    payload += b' ' * (-len(payload) % 4)
    tail = data[20 + length:]
    path.write_bytes(struct.pack('<III', 0x46546c67, 2, 20 + len(payload) + len(tail))
                     + struct.pack('<II', len(payload), 0x4e4f534a) + payload + tail)


def build(kind, folder, filename, mesh_name, rig_name, arms, spine, thighs):
    bpy.ops.wm.open_mainfile(filepath=str(folder / filename), use_scripts=False)
    mesh = bpy.data.objects[mesh_name]
    rig = bpy.data.objects[rig_name]
    rig.animation_data_clear()
    for bone in rig.pose.bones:
        for constraint in list(bone.constraints):
            bone.constraints.remove(constraint)
        bone.matrix_basis.identity()
    # The 2010 Rigify file uses constraints from control bones to deformation
    # bones. Preserve their rest matrices but make that relationship hierarchical
    # so the exported rig works without Blender drivers or Rigify.
    if kind == 'night_demon':
        bpy.context.view_layer.objects.active = rig
        bpy.ops.object.mode_set(mode='EDIT')
        for bone in rig.data.edit_bones:
            if not bone.name.startswith('DEF-'):
                continue
            target = 'ORG-' + bone.name[4:]
            while target not in rig.data.edit_bones and '.' in target:
                target = target.rsplit('.', 1)[0]
            if target in rig.data.edit_bones:
                bone.use_connect = False
                bone.parent = rig.data.edit_bones[target]
        bpy.ops.object.mode_set(mode='OBJECT')
    # Keep weighted bones, motion targets and their ancestors; omit unused
    # authoring controls from the runtime skeleton and animation tracks.
    required = {mesh.vertex_groups[g.group].name for v in mesh.data.vertices for g in v.groups if g.weight > 0}
    required.update(arms + [spine] + thighs)
    for name in list(required):
        bone = rig.data.bones.get(name)
        while bone is not None:
            required.add(bone.name)
            bone = bone.parent
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode='EDIT')
    for bone in list(rig.data.edit_bones):
        if bone.name not in required:
            rig.data.edit_bones.remove(bone)
    bpy.ops.object.mode_set(mode='OBJECT')
    for modifier in list(mesh.modifiers):
        if modifier.type != 'ARMATURE' or modifier.object != rig:
            mesh.modifiers.remove(modifier)
    material = bpy.data.materials.new(kind + '_skin')
    material.use_nodes = True
    nodes = material.node_tree.nodes
    shader = nodes.get('Principled BSDF')
    shader.inputs['Roughness'].default_value = .78
    tex = nodes.new('ShaderNodeTexImage')
    tex.image = bpy.data.images.load(str(folder / ('colorMap.png' if kind == 'night_demon' else 'diffuse.png')), check_existing=False)
    tex.image.name = 'albedo'
    material.node_tree.links.new(tex.outputs['Color'], shader.inputs['Base Color'])
    if kind == 'night_demon':
        normal_tex = nodes.new('ShaderNodeTexImage')
        normal_tex.image = bpy.data.images.load(str(folder / 'normalMap.png'), check_existing=False)
        normal_tex.image.name = 'normal'
        normal_tex.image.colorspace_settings.name = 'Non-Color'
        normal = nodes.new('ShaderNodeNormalMap')
        material.node_tree.links.new(normal_tex.outputs['Color'], normal.inputs['Color'])
        material.node_tree.links.new(normal.outputs['Normal'], shader.inputs['Normal'])
    mesh.data.materials.clear()
    mesh.data.materials.append(material)
    for polygon in mesh.data.polygons:
        polygon.material_index = 0
        polygon.use_smooth = True
    # Normalize the raw authoring units to 2.1m. Keep skeleton and skin together.
    points = [mesh.matrix_world @ Vector(v) for v in mesh.bound_box]
    height = max(v.z for v in points) - min(v.z for v in points)
    root = bpy.data.objects.new(kind, None)
    bpy.context.collection.objects.link(root)
    rig_world, mesh_world = rig.matrix_world.copy(), mesh.matrix_world.copy()
    rig.parent = root
    rig.matrix_world = rig_world
    mesh.parent = rig
    mesh.matrix_world = mesh_world
    root.scale = (2.1 / height,) * 3
    root.location.z = -min(v.z for v in points) * 2.1 / height
    bpy.context.scene.render.fps = 30

    def rotate(name, axis, radians):
        bone = rig.pose.bones[name]
        local_axis = bone.bone.matrix_local.to_quaternion().inverted() @ Vector(axis)
        bone.rotation_mode = 'QUATERNION'
        bone.rotation_quaternion = Quaternion(local_axis, radians)

    for role, length in [('Idle', 60), ('Walk', 30), ('Run', 24), ('Attack', 30), ('HitReact', 18), ('Death', 45)]:
        action = bpy.data.actions.new(role)
        rig.animation_data_create()
        rig.animation_data.action = action
        for frame in range(1, length + 1):
            t = (frame - 1) / (length - 1)
            wave = math.sin(t * math.tau)
            for bone in rig.pose.bones:
                bone.matrix_basis.identity()
            for side, name in enumerate(arms):
                angle = math.radians(65) * (1 if side == 0 else -1)
                if role in ('Walk', 'Run'):
                    angle += wave * .18 * (1 if side == 0 else -1)
                if role == 'Attack' and side == 1:
                    angle *= 1 - .9 * math.sin(math.pi * t)
                rotate(name, (0, 1, 0), angle)
                if role == 'Attack' and side == 1:
                    bone = rig.pose.bones[name]
                    axis = bone.bone.matrix_local.to_quaternion().inverted() @ Vector((0, 0, 1))
                    bone.rotation_quaternion = Quaternion(axis, 1.35 * math.sin(math.pi * t)) @ bone.rotation_quaternion
            pitch = .04 * wave if role == 'Idle' else 0.0
            if role == 'Attack':
                pitch = -.28 * math.sin(math.pi * t)
            elif role == 'HitReact':
                pitch = .35 * math.sin(math.pi * t)
            elif role == 'Death':
                pitch = 1.35 * t
            rotate(spine, (1, 0, 0), pitch)
            if role in ('Walk', 'Run'):
                for side, name in enumerate(thighs):
                    rotate(name, (1, 0, 0), wave * (.3 if role == 'Walk' else .5) * (1 if side == 0 else -1))
            for bone in rig.pose.bones:
                bone.keyframe_insert('rotation_quaternion', frame=frame, group=bone.name)
        track = rig.animation_data.nla_tracks.new()
        track.name = role
        track.strips.new(role, 1, action)
    rig.animation_data.action = None
    bpy.context.scene.frame_set(1)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in (root, rig, mesh):
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=str(out / (kind + '.glb')), export_format='GLB', use_selection=True,
                              export_animations=True, export_animation_mode='NLA_TRACKS',
                              export_force_sampling=True, export_def_bones=False)
    normalize_texture_names(out / (kind + '.glb'))
    print('EXPORTED', kind, 'vertices', len(mesh.data.vertices), 'height', 2.1)


build('night_demon', Path(args.night_source), 'demon-RIG.blend', 'Low Poly', 'rig',
      ['ORG-upper_arm.L', 'ORG-upper_arm.R'], 'ORG-spine', ['ORG-thigh.L', 'ORG-thigh.R'])
build('chained_demon', Path(args.chain_source), 'ChainedDemon.blend', 'ChainedDemon', 'Rig',
      ['Arm.L', 'Arm.R'], 'Spine1', ['Thigh.L', 'Thigh.R'])
