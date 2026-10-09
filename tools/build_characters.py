#!/usr/bin/env python3
"""Author original native character geometry. No downloads or external dependencies."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
resources, nodes = [], []

def mat(name, color, metal=0, rough=.8, glow=False):
    resources.append(f'[sub_resource type="StandardMaterial3D" id="{name}"]\nalbedo_color = Color({color}, 1)\nmetallic = {metal}\nroughness = {rough}\n' + (f'emission_enabled = true\nemission = Color({color}, 1)\nemission_energy_multiplier = 0.7\n' if glow else ''))

def box(name, size, material):
    resources.append(f'[sub_resource type="BoxMesh" id="{name}"]\nsize = Vector3({size})\nmaterial = SubResource("{material}")\n')

def sphere(name, radius, height, material):
    resources.append(f'[sub_resource type="SphereMesh" id="{name}"]\nradius = {radius}\nheight = {height}\nradial_segments = 12\nrings = 6\nmaterial = SubResource("{material}")\n')

def node(name, parent='.', pos='0, 0, 0', mesh=None, extra=''):
    kind = 'MeshInstance3D' if mesh else 'Node3D'
    nodes.append(f'[node name="{name}" type="{kind}" parent="{parent}"]\nposition = Vector3({pos})\n' + (f'mesh = SubResource("{mesh}")\n' if mesh else '') + extra + '\n')

mat('Shirt', '.43, .53, .56')
mat('Cuff', '.63, .69, .67')
mat('Trousers', '.055, .075, .09')
mat('Shoe', '.028, .032, .037', .05, .6)
mat('Skin', '.52, .32, .22', 0, .85)
mat('Hair', '.035, .027, .025')
mat('Tie', '.16, .065, .055')
mat('Ivory', '.72, .74, .67')
mat('Metal', '.16, .20, .22', .65, .4)
mat('Accent', '.08, .62, .66', .2, .4, True)
box('Torso', '.53, .56, .28', 'Shirt')
box('Pelvis', '.42, .18, .27', 'Trousers')
box('Belt', '.43, .045, .285', 'Shoe')
def limb(name, top, bottom, material):
    resources.append(f'[sub_resource type="CylinderMesh" id="{name}"]\ntop_radius = {top}\nbottom_radius = {bottom}\nheight = 1.0\nradial_segments = 8\nmaterial = SubResource("{material}")\n')
limb('UpperLeg', .105, .086, 'Trousers')
limb('Shin', .083, .067, 'Trousers')
limb('Sleeve', .105, .085, 'Shirt')
limb('Forearm', .074, .057, 'Skin')
box('CuffMesh', '.195, .075, .21', 'Cuff')
box('Foot', '.18, .13, .32', 'Shoe')
sphere('HeadMesh', .18, .43, 'Skin')
sphere('HairMesh', .184, .25, 'Hair')
box('HairLock', '.13, .09, .13', 'Hair')
box('Nose', '.075, .09, .075', 'Skin')
box('Glasses', '.135, .062, .025', 'Shoe')
box('Lens', '.098, .028, .029', 'Metal')
box('Bridge', '.04, .018, .025', 'Shoe')
box('TieMesh', '.065, .31, .025', 'Tie')
box('Collar', '.13, .10, .04', 'Cuff')
box('Badge', '.105, .135, .025', 'Ivory')
box('BadgeStripe', '.08, .025, .03', 'Accent')
box('Lanyard', '.018, .20, .015', 'Shoe')
box('Grip', '.10, .10, .38', 'Shoe')
box('Keyboard', '.42, .10, 1.08', 'Metal')
box('Key', '.08, .065, .075', 'Ivory')
box('Rim', '.035, .045, 1.10', 'Accent')
box('Spacebar', '.27, .06, .065', 'Ivory')
box('Hand', '.14, .17, .12', 'Skin')
node('Torso', pos='0, 1.17, 0', mesh='Torso', extra='rotation = Vector3(.06, 0, 0)')
node('Pelvis', pos='0, .83, 0', mesh='Pelvis')
node('Belt', pos='0, .91, 0', mesh='Belt')
node('Head', pos='0, 1.68, -.035', mesh='HeadMesh', extra='rotation = Vector3(.07, 0, -.04)')
node('Hair', 'Head', '0, .115, .015', 'HairMesh')
node('Lock', 'Head', '-.09, .2, -.035', 'HairLock', 'rotation = Vector3(0, .2, -.25)')
node('Nose', 'Head', '0, -.025, -.175', 'Nose')
for side in [-1, 1]:
    node(f'Glasses{side}', 'Head', f'{side*.086}, .032, -.163', 'Glasses')
    node(f'Lens{side}', 'Head', f'{side*.086}, .032, -.166', 'Lens')
    node(f'Collar{side}', 'Torso', f'{side*.09}, .24, -.151', 'Collar', f'rotation = Vector3(0, 0, {side*.45})')
node('Bridge', 'Head', '0, .035, -.176', 'Bridge')
node('Tie', 'Torso', '.015, .025, -.157', 'TieMesh', 'rotation = Vector3(.08, 0, -.12)')
node('Lanyard', 'Torso', '-.145, .07, -.157', 'Lanyard')
node('Badge', 'Torso', '-.145, -.07, -.174', 'Badge')
node('BadgeStripe', 'Torso/Badge', '0, .028, -.005', 'BadgeStripe')
for side in ['Left', 'Right']:
    x = -.16 if side == 'Left' else .16
    for part, mesh in [('Leg','UpperLeg'), ('Shin','Shin'), ('Arm','Sleeve'), ('Forearm','Forearm')]:
        node(side+part)
        node('Mesh', side+part, '0, -.5, 0', mesh)
    node(side+'Foot', pos=f'{x}, .10, -.06', mesh='Foot')
    node(side+'Hand', mesh='Hand')
    node(side+'Cuff', mesh='CuffMesh')
node('WeaponPivot', pos='.38, .91, -.02', extra='rotation = Vector3(-.5, 0, 0)')
node('Grip', 'WeaponPivot', '0, 0, -.22', 'Grip')
node('EscalationBlade', 'WeaponPivot', '0, 0, -.93', 'Keyboard')
for row in range(10):
    for col in range(4):
        node(f'Key{row}_{col}', 'WeaponPivot/EscalationBlade', f'{(col-1.5)*.094}, .067, {(row-4.5)*.09}', 'Key')
node('Spacebar', 'WeaponPivot/EscalationBlade', '0, .067, .48', 'Spacebar')
for side in [-1,1]:
    node(f'Edge{side}', 'WeaponPivot/EscalationBlade', f'{side*.206}, .03, 0', 'Rim')
header = '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://game/player/character_presentation.gd" id="1"]\n\n'
text = header+'\n'.join(resources)+'\n[node name="Character" type="Node3D"]\nscript = ExtResource("1")\n\n'+'\n'.join(nodes)
(ROOT/'game/player/engineer_visual.tscn').write_text(re.sub(r'(?<![\w\d])(-?)\.(\d)', r'\g<1>0.\2', text))

# Corrupted record: separated ledger slabs, offset head, asymmetric reaching arms.
resources.clear()
nodes.clear()
mat('Record', '.105, .12, .14', .5, .6)
mat('Paper', '.32, .35, .33', .1, .8)
mat('Status', '.95, .22, .055', .2, .5, True)
box('Spine', '.22, 1.35, .24', 'Record')
box('Slab', '.76, .23, .46', 'Paper')
box('Head', '.39, .32, .32', 'Record')
box('Row', '.48, .025, .025', 'Status')
box('Fragment', '.16, .30, .08', 'Record')
box('Leg', '.18, .63, .21', 'Record')
node('Head', pos='.17, 1.91, -.07', mesh='Head', extra='rotation = Vector3(.10, .10, -.12)')
for i in range(4):
    x=(-1 if i%2 else 1)*.07
    node('Slab'+str(i), pos=f'{x}, {.85+i*.245}, 0', mesh='Slab', extra=f'rotation = Vector3(0, {x}, {x*.4})')
    node('Row', 'Slab'+str(i), '0, .025, -.239', 'Row')
for side in [-1,1]:
    node('Leg'+str(side), pos=f'{side*.22}, .34, .04', mesh='Leg', extra=f'rotation = Vector3(0, 0, {side*.06})')
    node('Fragment'+str(side), pos=f'{side*.53}, 1.28, .04', mesh='Fragment', extra=f'rotation = Vector3(0, {side*.2}, {side*.22})')
text='[gd_scene format=3]\n\n'+'\n'.join(resources)+'\n[node name="RecordDetails" type="Node3D"]\n\n'+'\n'.join(nodes)
(ROOT/'game/enemies/record_visual.tscn').write_text(re.sub(r'(?<![\w\d])(-?)\.(\d)', r'\g<1>0.\2', text))
