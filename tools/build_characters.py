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
# Milestone 12 identity: the on-call engineer's hoodie, headphones and loud soles.
mat('Hoodie', '.16, .17, .19', 0, .95)
mat('Sole', '1, .45, .18', 0, .6)
mat('Sticky', '.98, .86, .3', 0, .9)
mat('Stain', '.3, .17, .08', 0, .9)
mat('Alarm', '1, .2, .12', .1, .4, True)
mat('Cable', '.05, .05, .06', .3, .5)
box('Torso', '.53, .56, .28', 'Shirt')
box('Pelvis', '.42, .18, .27', 'Trousers')
box('Belt', '.43, .045, .285', 'Shoe')
def torus(name, inner, outer, material):
    resources.append(f'[sub_resource type="TorusMesh" id="{name}"]\ninner_radius = {inner}\nouter_radius = {outer}\nrings = 24\nring_segments = 10\nmaterial = SubResource("{material}")\n')

def cylinder(name, radius, height, material):
    resources.append(f'[sub_resource type="CylinderMesh" id="{name}"]\ntop_radius = {radius}\nbottom_radius = {radius}\nheight = {height}\nradial_segments = 16\nmaterial = SubResource("{material}")\n')

def limb(name, top, bottom, material):
    resources.append(f'[sub_resource type="CylinderMesh" id="{name}"]\ntop_radius = {top}\nbottom_radius = {bottom}\nheight = 1.0\nradial_segments = 8\nmaterial = SubResource("{material}")\n')
limb('UpperLeg', .105, .086, 'Trousers')
limb('Shin', .083, .067, 'Trousers')
limb('Sleeve', .108, .088, 'Hoodie')
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
# The Legacy Monolith: a keyboard grown into a slab of a broadsword, taller than the man
# who carries it. Pommel at the pivot; the blade runs down -Z to an angled chisel tip.
mat('Iron', '.12, .12, .13', .8, .55)
mat('Steel', '.42, .44, .46', .9, .3)
mat('Leather', '.09, .055, .035', 0, .9)
box('MonolithBlade', '.44, .09, 1.72', 'Iron')
box('MonolithTip', '.32, .09, .32', 'Iron')
resources.append('[sub_resource type="StandardMaterial3D" id="EdgeGlow"]\nalbedo_color = Color(.4, .43, .45, 1)\nmetallic = .9\nroughness = .3\nemission_enabled = true\nemission = Color(.08, .62, .66, 1)\nemission_energy_multiplier = .25\n')
box('MonolithEdge', '.035, .1, 1.72', 'EdgeGlow')
box('MonolithGuard', '.56, .12, .1', 'Iron')
box('MonolithGrip', '.075, .075, .46', 'Leather')
box('MonolithPommel', '.11, .11, .1', 'Steel')
box('MonolithKey', '.075, .03, .07', 'Ivory')
node('WeaponPivot', pos='.38, .91, -.02', extra='rotation = Vector3(-.5, 0, 0)')
node('Pommel', 'WeaponPivot', '0, 0, .02', 'MonolithPommel')
node('Grip', 'WeaponPivot', '0, 0, -.25', 'MonolithGrip')
node('Guard', 'WeaponPivot', '0, 0, -.5', 'MonolithGuard')
node('EscalationBlade', 'WeaponPivot', '0, 0, -1.4', 'MonolithBlade')
node('Tip', 'WeaponPivot/EscalationBlade', '.04, 0, -.86', 'MonolithTip', 'rotation = Vector3(0, .62, 0)')
for row in range(14):
    for col in range(2):
        node(f'Key{row}_{col}', 'WeaponPivot/EscalationBlade', f'{(col-.5)*.1}, .06, {(row-6.5)*.1 + .05}', 'MonolithKey')
for side in [-1,1]:
    node(f'Edge{side}', 'WeaponPivot', f'{side*.22}, 0, -1.4', 'MonolithEdge')
box('PanelMesh', '.17, .58, .31', 'Hoodie')
box('BackMesh', '.55, .58, .05', 'Hoodie')
box('HoodMesh', '.44, .17, .2', 'Hoodie')
torus('BandMesh', .15, .185, 'Shoe')
cylinder('CupMesh', .085, .07, 'Shoe')
torus('CupRing', .062, .08, 'Accent')
box('TuftMesh', '.09, .1, .07', 'Hair')
box('StickyMesh', '.17, .17, .012', 'Sticky')
box('StainMesh', '.075, .055, .006', 'Stain')
box('SoleMesh', '.19, .045, .34', 'Sole')
box('EscMesh', '.08, .07, .075', 'Alarm')
box('CableMesh', '.04, .04, .14', 'Cable')
for side in [-1, 1]:
    node(f'HoodiePanel{side}', 'Torso', f'{side*.2}, 0, 0', 'PanelMesh')
    node(f'Cup{side}', 'Torso', f'{side*.2}, .33, -.02', 'CupMesh', 'rotation = Vector3(0, 0, 1.5708)')
    node(f'CupGlow{side}', f'Torso/Cup{side}', '0, 0, 0', 'CupRing')
node('HoodieBack', 'Torso', '0, 0, .15', 'BackMesh')
node('Hood', 'Torso', '0, .31, .15', 'HoodMesh', 'rotation = Vector3(-.35, 0, 0)')
node('Headphones', 'Torso', '0, .33, -.01', 'BandMesh', 'rotation = Vector3(.25, 0, 0)')
node('CoffeeStain', 'Torso', '.07, -.12, -.143', 'StainMesh')
# The note someone stuck on his back during standup. Nobody told him.
node('StickyNote', 'Torso', '-.05, .06, .178', 'StickyMesh', 'rotation = Vector3(0, 0, .12)')
nodes.append('[node name="StickyText" type="Label3D" parent="Torso/StickyNote"]\nposition = Vector3(0, 0, .008)\ntext = "ON CALL\\n(FOREVER)"\nfont_size = 24\npixel_size = .0016\nmodulate = Color(.15, .12, .08, 1)\noutline_size = 0\n')
for index, (x, z, rx, rz) in enumerate([(-.07, -.02, .3, -.5), (.05, .03, -.2, .4), (.0, .08, .5, .1), (.09, -.06, .1, .7)]):
    node(f'Tuft{index}', 'Head', f'{x}, .2, {z}', 'TuftMesh', f'rotation = Vector3({rx}, {index*.7}, {rz})')
for side in ['Left', 'Right']:
    node('Sole', side + 'Foot', '0, -.06, -.01', 'SoleMesh')
node('EscKey', 'WeaponPivot/EscalationBlade', '0, .06, -.78', 'EscMesh')
# The keyboard's cable, wrapped round the grip like a lanyard.
for index in range(4):
    node(f'Cable{index}', 'WeaponPivot/Grip', f'{.02*(index%2)}, {.05}, {.15-.1*index}', 'CableMesh', f'rotation = Vector3(0, {.6*index}, 1.5708)')
header = '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://game/player/character_presentation.gd" id="1"]\n\n'
text = header+'\n'.join(resources)+'\n[node name="Character" type="Node3D"]\nscript = ExtResource("1")\n\n'+'\n'.join(nodes)
(ROOT/'game/player/engineer_visual.tscn').write_text(re.sub(r'(?<![\w\d])(-?)\.(\d)', r'\g<1>0.\2', text))

# The rigged engineer carries the same keyboard: emit the WeaponPivot subtree on its own.
weapon_nodes = [n.replace('parent="WeaponPivot/', 'parent="').replace('parent="WeaponPivot"', 'parent="."') for n in nodes if 'parent="WeaponPivot' in n]
used = set(re.findall(r'SubResource\("(\w+)"\)', ''.join(weapon_nodes)))
for block in resources:
    if re.search(r'id="(\w+)"', block).group(1) in used:
        used |= set(re.findall(r'SubResource\("(\w+)"\)', block))
weapon_resources = [b for b in resources if re.search(r'id="(\w+)"', b).group(1) in used]
text = '[gd_scene format=3]\n\n' + '\n'.join(weapon_resources) + '\n[node name="WeaponPivot" type="Node3D"]\n\n' + '\n'.join(weapon_nodes)
(ROOT/'game/player/keyboard_weapon.tscn').write_text(re.sub(r'(?<![\w\d])(-?)\.(\d)', r'\g<1>0.\2', text))

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
# Milestone 12: a transaction stuck mid-commit. A loading halo that never finishes,
# its own pages orbiting it, glowing fractures, and a receipt it cannot swallow.
mat('Pending', '.4, .95, 1', .1, .3, True)
mat('Receipt', '.86, .85, .8', 0, .9)
box('Dot', '.07, .07, .07', 'Pending')
box('Page', '.36, .012, .26', 'Paper')
box('Crack', '.5, .018, .02', 'Status')
box('ReceiptMesh', '.12, .5, .012', 'Receipt')
box('ReceiptLine', '.09, .012, .014', 'Status')
node('Throbber', pos='.17, 2.42, -.07')
for i in range(8):
    angle = i * 6.28318 / 8
    node(f'Dot{i}', 'Throbber', f'{.3*__import__("math").cos(angle):.3f}, 0, {.3*__import__("math").sin(angle):.3f}', 'Dot', f'scale = Vector3({.5+.07*i:.2f}, {.5+.07*i:.2f}, {.5+.07*i:.2f})')
node('Pages', pos='0, 1.55, 0')
for i in range(5):
    angle = i * 6.28318 / 5
    node(f'Page{i}', 'Pages', f'{.75*__import__("math").cos(angle):.3f}, {(i%2)*.25:.2f}, {.75*__import__("math").sin(angle):.3f}', 'Page', f'rotation = Vector3({.4+.1*i:.2f}, {angle:.3f}, {.3-.12*i:.2f})')
for i in range(4):
    node('Crack', 'Slab'+str(i), f'{(-1)**i*.08}, .12, -.235', 'Crack', f'rotation = Vector3(0, 0, {(-1)**i*.35})')
node('Receipt', 'Head', '-.04, -.36, -.17', 'ReceiptMesh', 'rotation = Vector3(.15, 0, .08)')
for i in range(4):
    node(f'ReceiptLine{i}', 'Head/Receipt', f'0, {.15-.09*i:.2f}, -.008', 'ReceiptLine')
text='[gd_scene format=3]\n\n'+'\n'.join(resources)+'\n[node name="RecordDetails" type="Node3D"]\n\n'+'\n'.join(nodes)
(ROOT/'game/enemies/record_visual.tscn').write_text(re.sub(r'(?<![\w\d])(-?)\.(\d)', r'\g<1>0.\2', text))

# Milestone 12 archetypes: each silhouette reads at combat distance before color does.
def save_visual(root, path):
    text='[gd_scene format=3]\n\n'+'\n'.join(resources)+f'\n[node name="{root}" type="Node3D"]\n\n'+'\n'.join(nodes)
    (ROOT/path).write_text(re.sub(r'(?<![\w\d])(-?)\.(\d)', r'\g<1>0.\2', text))

def label(name, parent, pos, text, size, color, extra=''):
    nodes.append(f'[node name="{name}" type="Label3D" parent="{parent}"]\nposition = Vector3({pos})\ntext = "{text}"\nfont_size = {size}\npixel_size = 0.004\nmodulate = Color({color}, 1)\noutline_size = 8\n' + extra + '\n')

# The Blocker: a wide hazard-striped bulk carrying its own excuse as a shield.
resources.clear(); nodes.clear()
mat('Bulk', '.09, .095, .1', .6, .45)
mat('Hazard', '.95, .62, .12', .2, .5, True)
mat('Stripe', '.025, .025, .03', .3, .6)
box('TorsoMesh', '1.0, 1.0, .62', 'Bulk')
box('HeadMesh', '.38, .3, .34', 'Bulk')
box('VisorMesh', '.3, .06, .02', 'Hazard')
box('LegMesh', '.3, .66, .32', 'Bulk')
box('ShieldMesh', '1.35, 1.55, .12', 'Bulk')
box('RimMesh', '1.43, .07, .14', 'Hazard')
box('SideMesh', '.07, 1.6, .14', 'Hazard')
box('StripeMesh', '.12, 1.5, .02', 'Stripe')
node('Torso', pos='0, 1.15, 0', mesh='TorsoMesh')
node('Head', pos='0, 1.84, .02', mesh='HeadMesh')
node('Visor', 'Head', '0, .02, -.18', 'VisorMesh')
for side in [-1, 1]:
    node(f'Leg{side}', pos=f'{side*.26}, .33, 0', mesh='LegMesh')
node('Shield', pos='0, 1.05, -.52', mesh='ShieldMesh')
for y in [-.8, .8]:
    node(f'Rim{y}', 'Shield', f'0, {y}, 0', 'RimMesh')
for x in [-.7, .7]:
    node(f'Side{x}', 'Shield', f'{x}, 0, 0', 'SideMesh')
for i in range(5):
    node(f'Stripe{i}', 'Shield', f'{-.5+i*.25}, 0, -.07', 'StripeMesh', 'rotation = Vector3(0, 0, .5)')
label('ShieldText', 'Shield', '0, .12, -.09', 'BLOCKED', 72, '.95, .62, .12', 'rotation = Vector3(0, 3.14159, 0)\n')
label('ShieldSub', 'Shield', '0, -.3, -.09', 'AWAITING DEPENDENCY', 30, '1, .8, .5', 'rotation = Vector3(0, 3.14159, 0)\n')
save_visual('BlockerDetails', 'game/enemies/blocker_visual.tscn')

# The Meeting Invite: a hovering calendar card with nothing beneath it.
resources.clear(); nodes.clear()
mat('Card', '.78, .81, .86', 0, .7)
mat('Header', '.3, .55, 1', .1, .4, True)
mat('Ring', '.12, .13, .15', .7, .35)
mat('Rsvp', '1, .3, .2', .1, .4, True)
box('CardMesh', '1.3, .85, .06', 'Card')
box('HeaderMesh', '1.3, .2, .07', 'Header')
box('RingMesh', '.06, .16, .06', 'Ring')
box('RsvpMesh', '.42, .14, .02', 'Rsvp')
node('Card', pos='0, 1.7, 0', mesh='CardMesh')
node('Header', 'Card', '0, .33, 0', 'HeaderMesh')
for x in [-.4, 0, .4]:
    node(f'Ring{x}', 'Card', f'{x}, .45, 0', 'RingMesh')
node('Rsvp', 'Card', '.38, -.27, -.04', 'RsvpMesh')
label('Title', 'Card', '0, .05, -.04', 'MANDATORY', 44, '.12, .14, .2', 'rotation = Vector3(0, 3.14159, 0)\noutline_size = 0\n')
label('Detail', 'Card', '-.15, -.25, -.04', 'Attendance required', 22, '.25, .28, .35', 'rotation = Vector3(0, 3.14159, 0)\noutline_size = 0\n')
label('RsvpText', 'Card', '.38, -.27, -.052', 'ACCEPT', 18, '1, 1, 1', 'rotation = Vector3(0, 3.14159, 0)\noutline_size = 0\n')
save_visual('InviteDetails', 'game/enemies/meeting_invite_visual.tscn')

# Scope Creep: a leaning tower of sticky notes; growth reveals more of it.
resources.clear(); nodes.clear()
for name, color in [('Yellow', '.95, .85, .3'), ('Pink', '.95, .5, .7'), ('Green', '.55, .9, .45'), ('Blue', '.45, .75, .95')]:
    mat(name, color, 0, .85)
mat('Eye', '1, .95, .4', 0, .3, True)
mat('Leg', '.1, .1, .12', .3, .6)
box('NoteMesh', '.52, .05, .52', 'Yellow')
for name in ['Pink', 'Green', 'Blue']:
    box(f'Note{name}', '.52, .05, .52', name)
box('EyeMesh', '.08, .08, .02', 'Eye')
box('StickLeg', '.07, .45, .07', 'Leg')
for i in range(12):
    mesh = 'NoteMesh' if i % 4 == 0 else ['NotePink', 'NoteGreen', 'NoteBlue'][i % 3]
    node(f'Note{i}', pos=f'{(i%3-1)*.035}, {.5+i*.11}, {((i*7)%5-2)*.02}', mesh=mesh, extra=f'rotation = Vector3({((i*5)%7-3)*.04}, {i*.55}, {((i*3)%5-2)*.05})')
for side in [-1, 1]:
    node(f'Eye{side}', pos=f'{side*.1}, 1.0, -.27', mesh='EyeMesh')
    node(f'Leg{side}', pos=f'{side*.14}, .22, 0', mesh='StickLeg')
save_visual('CreepDetails', 'game/enemies/scope_creep_visual.tscn')
