"""Run with portable Blender --background --factory-startup --python this_file --
--mpfb-source /path/to/mpfb2/src --assets /path/to/unpacked/cc0/assets.
Development-only MakeHuman/MPFB assembly; the game loads the exported GLB.
"""
import argparse
import json
import struct
import re
from pathlib import Path
import sys

import bpy
from mathutils import Vector

parser = argparse.ArgumentParser()
parser.add_argument('--mpfb-source', required=True)
parser.add_argument('--assets', required=True)
parser.add_argument('--height', type=float, default=2.06, help='Final runtime height in metres; matches the current cast.')
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
sys.path.insert(0, args.mpfb_source)
# Source-checkout registration in an isolated Blender tool profile. This supplies
# the extension's data directory while leaving the upstream MPFB source unchanged.
original_extension_path = bpy.utils.extension_path_user
bpy.utils.extension_path_user = lambda *a, **kw: '/tmp/sev1_mh_profile/mpfb'
import mpfb
bpy.context.preferences.addons.new().module = 'mpfb'
mpfb.register()
bpy.utils.extension_path_user = original_extension_path
from mpfb.services.humanservice import HumanService
from mpfb.services.targetservice import TargetService
from mpfb.services.exportservice import ExportService
from mpfb.services.objectservice import ObjectService
from mpfb.services.rigservice import RigService

root = Path(__file__).resolve().parents[1]
out = root / 'assets/characters/makehuman_trial'
assets = Path(args.assets)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
macro = TargetService.get_default_macro_info_dict()
macro.update(gender=1.0, age=.45, weight=.52, muscle=.42, height=.5)
macro['race'] = {'african': .55, 'asian': .15, 'caucasian': .30}
human = HumanService.create_human(macro_detail_dict=macro)
human.name = 'RecruiterBody'
skin = assets / 'skins/middleage_african_male/middleage_african_male.mhmat'
HumanService.set_character_skin(str(skin), human, skin_type='GAMEENGINE')
authoring_rig = HumanService.add_builtin_rig(human, 'game_engine')
selected = [
    ('eyes/low-poly/low-poly.mhclo', 'Eyes'),
    ('eyebrows/eyebrow001/eyebrow001.mhclo', 'Eyebrows'),
    ('hair/short02/short02.mhclo', 'Hair'),
    ('clothes/toigo_male_suit_tie_and_jacket/toigo_male_suit_tie_and_jacket.mhclo', 'Clothes'),
    ('clothes/shoes01/shoes01.mhclo', 'Clothes'),
]
for filename, kind in selected:
    path = assets / filename
    if not path.is_file():
        raise RuntimeError('Missing CC0 input: ' + str(path))
    print('ASSEMBLE', filename, flush=True)
    HumanService.add_mhclo_asset(str(path), human, asset_type=kind, material_type='GAMEENGINE', subdiv_levels=0)
# Both motion rigs need the same T-pose reference before retargeting. MPFB
# applies it to the skin/outfit as well as the bones, preserving their bind.
ObjectService.activate_blender_object(authoring_rig)
bpy.ops.object.mode_set(mode='POSE')
pose_path = Path(args.mpfb_source) / 'mpfb/data/poses/game_engine_fk/t-pose.json'
RigService.set_pose_from_dict(authoring_rig, json.loads(pose_path.read_text()))
bpy.ops.object.mode_set(mode='OBJECT')
RigService.apply_pose_as_rest_pose(authoring_rig)
HumanService.serialize_to_json_file(human, str(out / 'recruiter_preset.json'), save_clothes=True)
export_root = ExportService.create_character_copy(human, name_suffix='_export')
export_body = ObjectService.find_object_of_type_amongst_nearest_relatives(export_root, 'Basemesh')
ExportService.bake_modifiers_remove_helpers(export_body, bake_masks=True, bake_subdiv=True, remove_helpers=True)
objects = [export_root] + ObjectService.get_list_of_children(export_root)
rig = next(obj for obj in objects if obj.type == 'ARMATURE')
# Canonical body names keep the coworker head-turn and reset behavior intact.
bone_names = {'Root': 'Body', 'pelvis': 'Hips', 'spine_01': 'Abdomen', 'spine_02': 'Torso',
              'spine_03': 'Chest', 'neck_01': 'Neck', 'head': 'Head'}
for suffix, side in [('l', 'L'), ('r', 'R')]:
    for source, target in [('clavicle','Shoulder'), ('upperarm','UpperArm'), ('lowerarm','LowerArm'),
                           ('hand','Hand'), ('thigh','UpperLeg'), ('calf','LowerLeg'), ('foot','Foot'), ('ball','Toe')]:
        bone_names[source + '_' + suffix] = target + '.' + side
for source, target in bone_names.items():
    rig.data.bones[source].name = target
    for obj in objects:
        if obj.type == 'MESH' and source in obj.vertex_groups:
            obj.vertex_groups[source].name = target
# Place the motion root at the pelvis, matching the source rig’s rotation pivot.
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
root_bone = rig.data.edit_bones['Body']
shift = rig.data.edit_bones['Hips'].head - root_bone.head
root_bone.head += shift
root_bone.tail += shift
bpy.ops.object.mode_set(mode='OBJECT')
# MPFB masks remove body surfaces beneath the outfit before export. Retain only
# the fitted character hierarchy, with no helper cubes, lights or cameras.
bpy.ops.object.select_all(action='DESELECT')
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = export_root
# Match the existing cast height after the .62 runtime scale. Apply the scale to
# the data so animation retargeting sees the final skeleton proportions.
points = [obj.matrix_world @ Vector(corner) for obj in objects if obj.type == 'MESH' for corner in obj.bound_box]
height = max(v.z for v in points) - min(v.z for v in points)
factor = (args.height / .62) / height
export_root.scale *= factor
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
for obj in objects:
    if obj.type == 'MESH':
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
for material in bpy.data.materials:
    if not material.use_nodes:
        continue
    principled = next((node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED'), None)
    if principled:
        principled.inputs['Roughness'].default_value = .8
        principled.inputs['Specular IOR Level'].default_value = .2
        principled.inputs['Metallic'].default_value = 0
        if 'eyebrow' in material.name.lower():
            principled.inputs['Base Color'].default_value = (.05, .035, .02, 1)
# Keep the material graphs portable: MPFB GAMEENGINE uses Principled BSDF.
# Bound texture resolution avoids carrying authoring-sized maps into this trial.
for image in bpy.data.images:
    if image.type == 'IMAGE' and max(image.size) > 2048:
        ratio = 2048 / max(image.size)
        image.scale(round(image.size[0] * ratio), round(image.size[1] * ratio))
rig.name = 'CharacterArmature'
bpy.ops.export_scene.gltf(filepath=str(out / 'recruiter.glb'), export_format='GLB',
                          use_selection=True, export_animations=False, export_morph=False)
# MPFB wires texture alpha for every material; Blender consequently exports all
# surfaces as BLEND. Skin, eyes and clothing must write depth; only hair/brows
# need cutout alpha. Normalize the portable glTF material flags explicitly.
glb_path = out / 'recruiter.glb'
glb = glb_path.read_bytes()
json_length = struct.unpack_from('<I', glb, 12)[0]
document = json.loads(glb[20:20 + json_length])
for image in document.get('images', []):
    image['name'] = re.sub(r'[^a-z0-9]+', '_', Path(image.get('name', 'texture')).stem.lower()).strip('_')
for material in document['materials']:
    cutout = any(word in material['name'].lower() for word in ['short02', 'eyebrow'])
    material['alphaMode'] = 'MASK' if cutout else 'OPAQUE'
    if cutout:
        material['alphaCutoff'] = .4
    material['doubleSided'] = cutout
encoded = json.dumps(document, separators=(',', ':')).encode()
encoded += b' ' * (-len(encoded) % 4)
remaining = glb[20 + json_length:]
glb_path.write_bytes(struct.pack('<III', 0x46546c67, 2, 20 + len(encoded) + len(remaining))
                     + struct.pack('<II', len(encoded), 0x4e4f534a) + encoded + remaining)
print('EXPORTED', out / 'recruiter.glb', 'input height', height, 'scale', factor, flush=True)
print('MESHES', [(obj.name, len(obj.data.polygons)) for obj in objects if obj.type == 'MESH'], flush=True)
