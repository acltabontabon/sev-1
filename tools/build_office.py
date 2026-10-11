#!/usr/bin/env python3
"""Author deterministic, editable Godot scenes. No runtime generation or dependencies.
Layout and modular prop sources live here; regenerate then rebake navigation.
"""
from pathlib import Path
import math
import copy
from pantry_layout import build_pantry
from office_details import build_office_details

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'game/rooms/office'
OUT.mkdir(parents=True, exist_ok=True)

def vec(v): return 'Vector3(%s)' % ', '.join(f'{x:.5f}' for x in v)
def col(v): return 'Color(%s)' % ', '.join(str(x) for x in v)
def quote(s): return '"' + s.replace('"', '\\"').replace('\n', '\\n') + '"'

# Shared materials. Large surfaces use CC0 photographed PBR sets (assets/environment/
# textures, see its README) projected triplanar so primitive boxes need no UV work.
materials = {
 'carpet': ((.62,.66,.7,1), 1, 0), 'plaster': ((.5,.53,.54,1), 1, 0),
 'walnut': ((.85,.7,.6,1), 1, 0), 'metal': ((.45,.5,.55,1), 1, 1),
 'plastic': ((.022,.028,.033,1), .65, 0), 'fabric': ((.08,.11,.12,1), .98, 0),
 'stone': ((.55,.58,.6,1), 1, 0), 'paper': ((.93,.91,.85,1), .9, 0),
 'ceramic': ((.38,.40,.36,1), .25, 0), 'black': ((.012,.017,.025,1), .85, 0),
 'screen': ((.015,.055,.068,1), .42, 0), 'warm': ((1,.74,.43,1), .45, 0),
 'cool': ((.67,.81,.85,1), .5, 0), 'alert': ((.85,.10,.035,1), .5, 0),
 'city': ((.12,.18,.23,1), .9, 0), 'mint': ((.18,.46,.45,1), .5, 0), 'glass': ((.17,.29,.32,.12), .12, .15),
 'vault_floor': ((.36,.4,.44,1), 1, 1), 'ceiling_tile': ((.5,.52,.53,1), 1, 0),
 'shutter': ((.2,.19,.14,1), .5, .7), 'green': ((.25,.95,.55,1), .5, 0),
 'amber': ((1,.62,.2,1), .5, 0), 'purple': ((.55,.25,.95,1), .5, 0),
 'neon_pink': ((1,.22,.62,1), .4, 0), 'neon_cyan': ((.2,.88,1,1), .4, 0), 'neon_amber': ((1,.7,.25,1), .4, 0),
 'poster_red': ((.78,.2,.18,1), .8, 0), 'poster_teal': ((.12,.5,.52,1), .8, 0), 'poster_gold': ((.85,.66,.25,1), .8, 0),
 'poster_violet': ((.42,.26,.66,1), .8, 0),
 # Framed prints: satin black frame, a clear glass skin, a white photo border.
 'frame': ((.035,.035,.04,1), .32, .65), 'poster_glass': ((1,1,1,.02), .04, 0),
 'print_white': ((.92,.91,.88,1), .7, 0), 'tape': ((.93,.9,.78,.55), .45, 0),
 'pin_red': ((.8,.08,.06,1), .3, 0), 'sticky_yellow': ((.98,.86,.32,1), .85, 0),
 'sticky_pink': ((.98,.55,.72,1), .85, 0), 'sticky_green': ((.62,.92,.55,1), .85, 0),
 'wellness_purple': ((.36,.24,.6,1), .8, 0),
 'office_enamel': ((.63,.66,.65,1), .48, .15),
 'frosted_glass': ((.72,.8,.8,.28), .8, 0),
}
# CC0 photographs for the culture-deck prints (assets/environment/posters, see its README).
photos = ['family', 'fail_fast', 'wellbeing', 'machine', 'wellness']
textured = {'carpet': ('carpet', .45), 'plaster': ('painted_plaster', .35), 'walnut': ('walnut_veneer', 1.0),
 'stone': ('polished_concrete', .3), 'metal': ('brushed_metal', 1.0), 'vault_floor': ('vault_floor', .5),
 'ceiling_tile': ('ceiling_tile', .42), 'paper': ('paper', 1.4)}
for name,(color,rough,metallic) in materials.items():
    extra=''; resources=''; header=''
    if name in textured:
        folder, scale = textured[name]
        base = f'res://assets/environment/textures/{folder}/'
        maps = [('albedo_texture','color'), ('normal_texture','normal'), ('roughness_texture','roughness')]
        if (ROOT/'assets/environment/textures'/folder/'metalness.jpg').exists() and metallic:
            maps.append(('metallic_texture','metalness'))
        header=''.join(f'[ext_resource type="Texture2D" path="{base}{m}.jpg" id="{i+1}"]\n' for i,(_,m) in enumerate(maps))
        for i,(slot,_) in enumerate(maps):
            extra+=f'{slot} = ExtResource("{i+1}")\n'
        extra+='normal_enabled = true\nroughness_texture_channel = 0\nmetallic_texture_channel = 0\n'
        extra+=f'uv1_triplanar = true\nuv1_world_triplanar = true\nuv1_scale = Vector3({scale}, {scale}, {scale})\n'
    if name=='fabric':
        resources='''[sub_resource type="FastNoiseLite" id="Noise"]
seed = 459
frequency = 0.16
fractal_octaves = 3
[sub_resource type="Gradient" id="Grain"]
colors = PackedColorArray(0.65, 0.65, 0.65, 1, 1, 1, 1, 1)
[sub_resource type="NoiseTexture2D" id="Texture"]
width = 128
height = 128
seamless = true
noise = SubResource("Noise")
color_ramp = SubResource("Grain")
'''
        extra+='albedo_texture = SubResource("Texture")\nuv1_triplanar = true\nuv1_scale = Vector3(3, 3, 3)\n'
    if name in ('screen','warm','cool','alert','mint','green','amber','purple'):
        extra+=f'emission_enabled = true\nemission = {col(color)}\nemission_energy_multiplier = {0.65 if name=="screen" else 1.3}\n'
    if name.startswith('neon_'):
        extra+=f'emission_enabled = true\nemission = {col(color)}\nemission_energy_multiplier = 3.2\n'
    if name=='glass': extra+='transparency = 1\ncull_mode = 2\n'
    if name in ('poster_glass','tape','frosted_glass'): extra+='transparency = 1\n'
    if name=='poster_glass': extra+='metallic_specular = 1.0\n'
    (OUT/f'{name}.tres').write_text(f'[gd_resource type="StandardMaterial3D" format=3]\n\n{header}{resources}\n[resource]\nalbedo_color = {col(color)}\nroughness = {rough}\nmetallic = {metallic}\n'+extra)
for name in photos:
    (OUT/f'photo_{name}.tres').write_text(f'[gd_resource type="StandardMaterial3D" format=3]\n\n[ext_resource type="Texture2D" path="res://assets/environment/posters/{name}.jpg" id="1"]\n\n[resource]\nalbedo_texture = ExtResource("1")\nroughness = 0.6\nemission_enabled = true\nemission_texture = ExtResource("1")\nemission_energy_multiplier = 0.35\n')
# The tower and the city at night: one procedural curtain-wall shader (facade.gdshader).
(OUT/'facade.tres').write_text('[gd_resource type="ShaderMaterial" format=3]\n\n[ext_resource type="Shader" path="res://game/rooms/office/facade.gdshader" id="1"]\n\n[resource]\nshader = ExtResource("1")\n')
# Poster titles: Cinzel Bold, tracked out like a framed corporate print.
(OUT/'poster_title_font.tres').write_text('[gd_resource type="FontVariation" format=3]\n\n[ext_resource type="FontFile" path="res://assets/fonts/cinzel_variable.ttf" id="1"]\n\n[resource]\nbase_font = ExtResource("1")\nvariation_opentype = {2003265652: 700}\nspacing_glyph = 6\n')

class Scene:
    def __init__(self, name):
        self.name=name; self.res=[]; self.nodes=[f'[node name="{name}" type="Node3D"]']; self.ext={}; self.cache={}; self.i=0
    def external(self,path,kind):
        if path not in self.ext: self.ext[path]=(str(len(self.ext)+1),kind)
        return 'ExtResource("'+self.ext[path][0]+'")'
    def resource(self,kind,props):
        key=(kind,props)
        if key not in self.cache:
            rid=f'r{len(self.res)}'; self.cache[key]=rid
            self.res.append(f'[sub_resource type="{kind}" id="{rid}"]\n{props}')
        return f'SubResource("{self.cache[key]}")'
    def node(self,name,kind,pos=(0,0,0),parent='.',props=''):
        placed='' if kind=='Node' else f'position = {vec(pos)}\n'
        self.nodes.append(f'[node name="{name}" type="{kind}" parent="{parent}"]\n{placed}{props}')
        return name if parent=='.' else parent+'/'+name
    def box(self,name,pos,size,mat,solid=False,parent='.',rot=None,body=''):
        m=self.external(f'res://game/rooms/office/{mat}.tres','Material')
        mesh=self.resource('BoxMesh',f'size = {vec(size)}\nmaterial = {m}')
        rotation='' if rot is None else f'rotation_degrees = {vec(rot)}\n'
        if solid:
            path=self.node(name,'StaticBody3D',pos,parent,rotation+body)
            self.node('Mesh','MeshInstance3D',parent=path,props=f'mesh = {mesh}')
            shape=self.resource('BoxShape3D',f'size = {vec(size)}')
            self.node('Collision','CollisionShape3D',parent=path,props=f'shape = {shape}')
        else: self.node(name,'MeshInstance3D',pos,parent,f'mesh = {mesh}\n'+rotation+('cast_shadow = 0' if mat in ('glass','screen','cool','warm','alert','mint','facade') or name=='CityGround' else ''))
    def collider(self,name,pos,size,parent='.'):
        # Simplified collision envelope for imported or detailed props.
        path=self.node(name,'StaticBody3D',pos,parent)
        shape=self.resource('BoxShape3D',f'size = {vec(size)}')
        self.node('Collision','CollisionShape3D',parent=path,props=f'shape = {shape}')
    def glb(self,name,file,pos,rot=0,scale=1.0,parent='.'):
        ref=self.external(f'res://assets/environment/kenney_furniture/{file}.glb','PackedScene')
        self.nodes.append(f'[node name="{name}" parent="{parent}" instance={ref}]\nposition = {vec(pos)}\nrotation_degrees = Vector3(0, {rot}, 0)\nscale = Vector3({scale}, {scale}, {scale})')
    def marker(self,name,pos,parent='SpawnPoints'):
        self.node(name,'Marker3D',pos,parent)
    def cylinder(self,name,pos,radius,height,mat,parent='.',rot=None):
        m=self.external(f'res://game/rooms/office/{mat}.tres','Material')
        mesh=self.resource('CylinderMesh',f'top_radius = {radius}\nbottom_radius = {radius}\nheight = {height}\nradial_segments = 12\nmaterial = {m}')
        self.node(name,'MeshInstance3D',pos,parent,f'mesh = {mesh}\n'+('' if rot is None else f'rotation_degrees = {vec(rot)}'))
    def text(self,name,text,pos,size=.008,font=40,color=(.65,.77,.77,1),rot=(0,0,0),parent='.',face=None):
        typeface='' if face is None else 'font = '+self.external(face,'FontFile' if face.endswith('.ttf') else 'FontVariation')+'\n'
        self.node(name,'Label3D',pos,parent,f'text = {quote(text)}\n{typeface}font_size = {font}\npixel_size = {size}\nmodulate = {col(color)}\noutline_size = 0\nrotation_degrees = {vec(rot)}\n')
    def quad(self,name,pos,size,mat,rot=(0,0,0),parent='.'):
        # UV-mapped flat face (photos and prints), facing +Z before rotation.
        m=self.external(f'res://game/rooms/office/{mat}.tres','Material')
        mesh=self.resource('QuadMesh',f'size = Vector2({size[0]}, {size[1]})\nmaterial = {m}')
        self.node(name,'MeshInstance3D',pos,parent,f'mesh = {mesh}\nrotation_degrees = {vec(rot)}\ncast_shadow = 0\n')
    def instance(self,name,file,pos,rot=0):
        ref=self.external(f'res://game/rooms/office/{file}.tscn','PackedScene')
        self.nodes.append(f'[node name="{name}" parent="." instance={ref}]\nposition = {vec(pos)}\nrotation_degrees = Vector3(0, {rot}, 0)')
    def light(self,name,pos,color,energy,range_,spot=False,shadow=False,rot=(-90,0,0)):
        props=f'light_color = {col((*color,1))}\nlight_energy = {energy}\nshadow_enabled = {str(shadow).lower()}\n'
        props+=f'spot_range = {range_}\nspot_angle = 65\nspot_attenuation = 0.65\nrotation_degrees = {vec(rot)}' if spot else f'omni_range = {range_}\nomni_attenuation = 1.4'
        self.node(name,'SpotLight3D' if spot else 'OmniLight3D',pos,props=props)
    def save(self,file):
        ext='\n'.join(f'[ext_resource type="{kind}" path="{path}" id="{rid}"]' for path,(rid,kind) in self.ext.items())
        (OUT/f'{file}.tscn').write_text(('[gd_scene format=3]\n\n'+ext+'\n\n'+'\n\n'.join(self.res+self.nodes)).rstrip()+'\n')

chair=Scene('OfficeChair')
chair.box('Seat',(0,.5,0),(.56,.12,.56),'fabric')
chair.box('Back',(0,.93,.23),(.55,.65,.10),'fabric',rot=(-8,0,0))
chair.cylinder('Stem',(0,.25,0),.055,.45,'metal')
for i in range(5):
    angle=i*72
    chair.box(f'Foot{i}',(0,.08,0),(.055,.055,.82),'metal',rot=(0,angle,0))
for x in [-.34,.34]:
    chair.box(f'Arm{x}',(x,.76,.01),(.07,.055,.43),'plastic')
    chair.box(f'Support{x}',(x,.60,.09),(.045,.3,.045),'metal')
chair.save('chair')

# Workstation dimensions are workplace scale, not oversized boxes.
desk=Scene('Workstation')
desk.box('Top',(0,.79,0),(2.25,.065,.95),'walnut',True)
for x in [-.94,.94]:
    desk.box(f'Leg{x}',(x,.38,0),(.075,.76,.70),'metal')
desk.box('CableTray',(0,.53,-.27),(1.8,.14,.16),'metal')
desk.box('Monitor',(0,1.26,-.25),(1.0,.60,.07),'plastic')
desk.box('Display',(0,1.26,-.208),(.93,.53,.01),'screen')
desk.box('Stand',(0,.97,-.25),(.08,.3,.06),'metal')
desk.box('Base',(0,.834,-.16),(.38,.025,.24),'metal')
desk.box('Keyboard',(-.10,.844,.25),(.54,.035,.18),'plastic')
for j in range(4):
    desk.box(f'Keys{j}',(-.10,.865,.195+j*.035),(.49,.007,.012),'metal')
desk.box('Mouse',(.36,.85,.26),(.075,.045,.12),'plastic')
desk.box('Notebook',(-.80,.839,.20),(.27,.025,.34),'paper',rot=(0,12,0))
desk.cylinder('Mug',(.82,.91,.18),.075,.18,'ceramic')
desk.cylinder('Coffee',(.82,1.002,.18),.060,.002,'black')
# Broad editor-like lines stay secondary to the legible large incident dashboards.
for j,w in enumerate([.5,.65,.38,.59,.46]):
    desk.box(f'Code{j}',(-.08,1.40-j*.065,-.198),(w,.012,.005),'mint')
desk.instance('Chair','chair',(0,0,.87),-8)
desk.save('workstation')

# One hero prop trial: preserve all gameplay paths, collision and screen staging.
polished = copy.deepcopy(desk)
polished.name = 'PolishedWorkstation'
polished.nodes[0] = '[node name="PolishedWorkstation" type="Node3D"]'
for i, node in enumerate(polished.nodes):
    if ('name="Mesh"' in node and 'parent="Top"' in node) or any(f'name="{name}"' in node for name in ['Leg-0.94', 'Leg0.94', 'CableTray']):
        polished.nodes[i] += '\nvisible = false'
ref = polished.external('res://assets/environment/poly_haven_workstation/metal_office_desk.glb', 'PackedScene')
polished.nodes.append(f'[node name="DetailedDesk" parent="." instance={ref}]\nscale = Vector3(1.125, 1.04444, 1.00294)')
polished.box('DeskMat', (.04, .827, .24), (.94, .008, .40), 'fabric')
# Small keycaps break the placeholder keyboard stripes into an actual keyboard.
for row in range(4):
    for key in range(13):
        polished.box(f'Keycap{row}_{key}', (-.335 + key*.038, .871, .19 + row*.036), (.031, .012, .027), 'plastic')
polished.box('Spacebar', (-.1, .872, .335), (.23, .012, .025), 'plastic')
polished.box('MonitorLowerBezel', (0, .967, -.208), (1.0, .025, .015), 'plastic')
polished.cylinder('PowerLED', (.45, .968, -.196), .003, .003, 'mint', rot=(90,0,0))
polished.box('NotebookHeader', (-.80, .854, .12), (.20, .001, .015), 'plastic', rot=(0,12,0))
for line in range(5):
    polished.box(f'NotebookRule{line}', (-.80, .854, .18+line*.026), (.20, .001, .0015), 'metal', rot=(0,12,0))
polished.save('polished_workstation')
# Reuse the existing CC0 desk throughout the office, retaining the tested tabletop
# collider and story paths. The hero desk keeps its extra close-up keycaps.
shared = copy.deepcopy(desk)
for i, node in enumerate(shared.nodes):
    if ('name="Mesh"' in node and 'parent="Top"' in node) or any(f'name="{name}"' in node for name in ['Leg-0.94', 'Leg0.94', 'CableTray']):
        shared.nodes[i] += '\nvisible = false'
ref = shared.external('res://assets/environment/poly_haven_workstation/metal_office_desk.glb', 'PackedScene')
shared.nodes.append(f'[node name="DetailedDesk" parent="." instance={ref}]\nscale = Vector3(1.125, 1.04444, 1.00294)')
shared.box('DeskMat', (.04, .827, .24), (.94, .008, .40), 'fabric')
shared.save('workstation')

rack=Scene('ServerRack')
rack.box('Cabinet',(0,1.2,0),(.85,2.4,.90),'metal',True)
rack.box('Front',(0,1.2,.46),(.76,2.23,.025),'plastic')
for j in range(10):
    rack.box(f'Unit{j}',(0,.22+j*.205,.485),(.68,.17,.022),'metal')
    for k in range(4): rack.box(f'Vent{j}_{k}',(-.05,.18+j*.205+k*.023,.5),(.42,.007,.01),'black')
    rack.box(f'LED{j}',(.26,.23+j*.205,.502),(.027,.017,.009),'alert' if j in (2,6,8) else 'mint')
rack.save('server_rack')

lite=Scene('ServerRackLite')
lite.box('Cabinet',(0,1.2,0),(.85,2.4,.90),'metal',True)
lite.box('Front',(0,1.2,.46),(.76,2.23,.025),'plastic')
for j in range(5): lite.box(f'Unit{j}',(0,.32+j*.42,.48),(.68,.3,.02),'black')
# One shared LED strip per rack; the incident swaps its material as the corridor fails.
lite.box('Leds',(.26,1.2,.495),(.03,2.0,.01),'mint')
lite.box('Vent',(-.05,1.2,.495),(.42,2.0,.006),'metal')
lite.save('server_rack_lite')

s=Scene('OfficeAfterHours')
TITLE_FONT='res://game/rooms/office/poster_title_font.tres'
BODY_FONT='res://assets/fonts/inter_variable.ttf'
SIGN_FONT='res://assets/fonts/barlow_condensed_bold.ttf'
def frame(path,w,h,depth=.06,bar=.06):
    """A satin black frame around a w x h print, its glass just inside the bars."""
    for side,pos,size in [('Top',(0,h/2-bar/2,depth/2-.01),(w,bar,depth)),('Bottom',(0,-h/2+bar/2,depth/2-.01),(w,bar,depth)),
        ('Left',(-w/2+bar/2,0,depth/2-.01),(bar,h-2*bar,depth)),('Right',(w/2-bar/2,0,depth/2-.01),(bar,h-2*bar,depth))]:
        s.box('Frame'+side,pos,size,'frame',parent=path)
    s.quad('Glass',(0,0,depth-.02),(w-2*bar,h-2*bar),'poster_glass',parent=path)
# Camera-only blockers for large architecture without collision (see the script).
s.nodes[0]+='\nscript = '+s.external('res://game/rooms/office/office_after_hours.gd','Script')
s.box('Floor',(0,-.25,0),(28,.5,32),'carpet',True)
# North wall opens at x 7..11 onto the restricted corridor; the gate seals it until the boss.
s.box('North',(-3.5,3,-16),(21,6,.5),'plaster',True)
s.box('NorthEast',(12.5,3,-16),(3,6,.5),'plaster',True)
s.box('GateHeader',(9,5,-16),(4,2,.5),'plaster',True)
s.box('South',(0,3,16),(28,6,.5),'plaster',True)
# East wall: two doorways into the meeting wing, near Operations and near the desk.
for name,z,length in [('EastNorth',-14.75,2.5),('East',0,21),('EastSouth',14.75,2.5)]:
    s.box(name,(14,3,z),(.5,6,length),'plaster',True)
for z in [-12,12]:
    s.box(f'WingHeader{z}',(14,4.6,z),(.5,2.8,3),'plaster',True)
    s.box(f'Threshold{z}',(14,-.247,z),(.7,.5,3),'metal',True)
s.box('GateThreshold',(9,-.247,-16),(4,.5,.7),'metal',True)
# Window wall collider is separate from its transparent architectural surface.
shape=s.resource('BoxShape3D','size = Vector3(0.5, 6, 32)')
p=s.node('West','StaticBody3D',(-14,3,0));s.node('Collision','CollisionShape3D',parent=p,props=f'shape = {shape}')
s.box('WindowSill',(-13.75,.45,0),(.35,.9,32),'plaster')
s.box('Windows',(-13.92,3.2,0),(.03,4.3,31.5),'glass')
s.box('Ceiling',(0,5.65,0),(28,.2,32),'black',True)
# Dark stone circulation spine; quiet carpet field replaces lab grid.
s.box('Circulation',(0,.006,0),(8,.012,31.5),'stone')
for x in [-4.03,4.03]: s.box(f'FloorReveal{x}',(x,.018,0),(.035,.018,31.5),'metal')
for z in range(-14,16,2): s.box(f'StoneJoint{z}',(0,.018,z),(8,.004,.012),'metal')
s.box('SkirtingWest',(-13.7,.10,0),(.05,.2,31.5),'metal')
for z,length in [(-14.6,2.3),(0,20.6),(14.6,2.3)]: s.box(f'SkirtingEast{z}',(13.7,.10,z),(.05,.2,length),'metal')
s.box('SkirtingSouth',(0,.10,15.72),(27.5,.2,.05),'metal')
for x,length in [(-3.4,20.7),(12.4,2.7)]: s.box(f'SkirtingNorth{x}',(x,.10,-15.72),(length,.2,.05),'metal')
for x in [-12,12]:
    for z in [-12,-4,4,12]:
        s.box(f'Column{x}_{z}',(x,2.75,z),(.65,5.5,.65),'plaster',True)
        s.box(f'Base{x}_{z}',(x,.20,z),(.68,.4,.68),'metal')
for z in range(-14,16,4):
    s.box(f'Mullion{z}',(-13.75,3,z),(.16,5.2,.11),'metal')
    s.box(f'Beam{z}',(0,5.45,z),(27.5,.23,.16),'metal')
# Reuse exact slope/deck collision dimensions from movement foundation.
s.box('RaisedDeck',(8,.75,-7),(6,1.5,8),'stone',True)
s.box('Ramp',(8,.70,0),(4,.18,6.18466),'stone',True,rot=(14.036,0,0))
for x in [6.05,9.95]: s.box(f'RampEdge{x}',(x,.73,0),(.04,.025,6.18466),'metal',rot=(14.036,0,0))
for x in [6.0,10.0]:
    s.box(f'RampGuard{x}',(x,1.15,0),(.07,1,6.18466),'glass',True,rot=(14.036,0,0))
    s.box(f'RampRail{x}',(x,1.66,0),(.065,.05,6.18466),'metal',rot=(14.036,0,0))
# Conference room west glazing gives an uninterrupted sightline into a silent meeting.
s.box('ConferenceGlass',(5.03,3.18,-7),(.045,3.3,8),'glass',True)
for z in [-11,-9,-7,-5,-3]: s.box(f'GlassFrame{z}',(5,3.18,z),(.065,3.4,.065),'metal')
for y in [1.55,2.55,4.85]: s.box(f'GlassRail{y}',(5,y,-7),(.07,.045,8),'metal')
s.box('ConferenceRear',(8,3.18,-11),(6,3.3,.13),'walnut',True)
s.box('ConferenceEast',(10.97,3.18,-7),(.08,3.3,8),'glass',True)
# Front has a generous opening aligned with ramp; no narrow door collision.
for x in [5.65,10.35]: s.box(f'FrontGlass{x}',(x,3.18,-3),(1.25,3.3,.045),'glass',True)
s.box('Table',(8,2.3,-8),(3.5,.12,1.7),'walnut',True)
for x in [6.9,9.1]: s.box(f'TableLeg{x}',(x,1.9,-8),(.15,.8,.85),'metal')
for x in [6.8,8,9.2]:
    s.instance(f'ChairA{x}','chair',(x,1.5,-9.35),180)
    s.instance(f'ChairB{x}','chair',(x,1.5,-6.6),0)
s.box('MeetingScreen',(8,3.5,-10.90),(3.2,1.5,.07),'plastic')
s.box('MeetingDisplay',(8,3.5,-10.851),(3.02,1.32,.008),'screen')
s.text('MeetingTitle','Q4 ALIGNMENT',(8,3.8,-10.83),.004,55)
s.text('MeetingTarget','DO MORE.\nWITH LESS.',(8,3.3,-10.83),.005,55)
s.text('MeetingName','04  /  ALIGNMENT',(5.0,4.45,-5),.005,45,rot=(0,-90,0))
# Workstation bays keep the central dodge/combo lanes clear.
for idx,(x,z,rot) in enumerate([(-9,5,0),(-6.5,5,0),(-9,0,0),(-6.5,0,0),(-9,-6,0),(-6.5,-6,0)]):
    s.instance(f'Workstation{idx}','workstation',(x,0,z),rot)
for z in [4.45,-.55,-6.55]:
    s.box(f'Partition{z}',(-7.75,.65,z),(5,.13,.12),'fabric')
    s.box(f'PartitionScreen{z}',(-7.75,1.05,z),(5,.70,.09),'fabric',True)
# Starting desk beside the spawn, viewed at an angle; warm pool contrasts operations.
s.instance('YourWorkstation','workstation',(-2.5,0,9.4),0)
s.text('DeskTime','FRI  16:59',(-2.5,1.08,9.205),.002,30)
s.box('TaskLampBase',(-3.35,.85,9.6),(.24,.045,.24),'metal')
s.cylinder('TaskLampStem',(-3.35,1.10,9.6),.022,.5,'metal')
s.box('TaskLampShade',(-3.35,1.37,9.53),(.32,.11,.22),'metal')
s.box('TaskLampBulb',(-3.35,1.31,9.53),(.26,.015,.16),'warm')
s.light('TaskLight',(-3.35,1.30,9.36),(1,.76,.52),2.8,2.2,spot=True,shadow=True,rot=(-65,0,0))
s.instance('CoworkerDesk','workstation',(-7,0,11),180)
s.box('ForgottenBag',(-5,.22,9.6),(.36,.44,.25),'fabric')
# Operations wall: large restrained information, hardware and ordered cable tray.
for idx,x in enumerate([-9.8,-8.7,-7.6,-6.5]): s.instance(f'Rack{idx}','server_rack',(x,0,-13.8),0)
s.box('OperationsPanel',(-1.7,2.5,-15.68),(7.8,3.8,.10),'walnut')
s.text('OperationsTitle','PRODUCTION OPERATIONS',(-1.7,4.10,-15.60),.006,62)
for idx,x in enumerate([-4.1,.7]):
    s.box(f'Dashboard{idx}',(x,2.6,-15.51),(3.5,2.0,.09),'plastic')
    s.box(f'DashboardFace{idx}',(x,2.6,-15.45),(3.33,1.82,.008),'screen')
s.text('Critical','PRODUCTION\nCRITICAL',(-4.1,2.92,-15.43),.007,56,(1,.39,.22,1))
s.text('RootCause','ROOT CAUSE: UNKNOWN',(-4.1,2.02,-15.43),.004,40)
s.text('Clock','FRIDAY  /  16:59',(.7,3.12,-15.43),.005,45)
s.text('Impossible','UPTIME  −00:01',(.7,2.62,-15.43),.006,46)
s.text('ETA','RESOLUTION: PENDING',(.7,2.08,-15.43),.004,40)
s.box('IncidentStrip',(-1.7,1.38,-15.4),(7.4,.055,.03),'alert')
s.light('IncidentSpill',(-2,2.6,-14.5),(1,.16,.065),2.3,6)
s.box('CableTray',(-8,3.35,-14),(5,.12,.4),'metal')
for i in range(6): s.box(f'Cable{i}',(-9.5+i*.09,1.8,-14.1),(.022,3.2,.022),'black')
# A sealed service door frames an impossible repeated tunnel beyond the glass.
# Security shutter: generated without collision so navigation bakes through the doorway;
# the incident enables it until the boss stage and lifts it into the header.
s.box('VaultGate',(9,2,-16),(4,4,.22),'shutter',True,body='collision_layer = 0\n')
for i in range(7): s.box(f'GateSlat{i}',(0,-1.6+i*.55,.12),(3.9,.05,.01),'black',parent='VaultGate')
s.text('GateSign','RESTRICTED  ·  PRODUCTION CORE',(0,.6,.13),.00453,44,(1,.62,.2,1),parent='VaultGate')
s.text('GateSubsign','Authorized personnel and whoever is on call',(0,.18,.13),.0038,30,(1,.8,.5,1),parent='VaultGate')
s.text('DoorNotice','B2  ·  SERVER CORRIDOR',(9,4.45,-15.72),.005,44,(1,.62,.2,1))
s.text('Wayfinding','OPERATIONS  /  04',(-8.3,3.4,-15.6),.005,48)
# Selective dry humor, not a wall of jokes.
# A status-page printout, framed like an award: green dot and all.
status=s.node('StatusPrint','Node3D',(13.70,2.4,7),props='rotation_degrees = Vector3(0, -90, 0)\n')
s.box('Poster',(0,0,0),(1.12,1.65,.03),'paper',parent=status)
frame(status,1.12,1.65,.05,.045)
s.cylinder('StatusDot',(0,.42,.018),.11,.01,'green',parent=status,rot=(90,0,0))
s.text('PosterText','ALL SYSTEMS\nOPERATIONAL*',(0,.05,.018),.00276,46,(.06,.10,.12,1),parent=status,face=SIGN_FONT)
s.text('PosterFootnote','*Except the\nimportant ones.',(0,-.53,.018),.0054,23,(.06,.10,.12,1),parent=status,face=BODY_FONT)
# Fixtures have a visible housing and diffuser. Two shadowed pools only.
for idx,(x,z) in enumerate([(-7,8),(0,7),(-7,-2),(0,-3),(0,-11),(8,-7)]):
    y=5.2
    s.box(f'Fixture{idx}',(x,y,z),(3.0,.13,.34),'metal')
    s.box(f'Diffuser{idx}',(x,y-.075,z),(2.85,.018,.26),'warm' if idx==5 else 'cool')
    s.light(f'CeilingPool{idx}',(x,y-.16,z),(.68,.80,.86) if idx!=5 else (1,.80,.56),3.2,11,True,idx in (1,3))
# Paired fixture cables and ceiling service ducts ground the room's vertical scale.
for x in [-5,5]: s.box(f'Duct{x}',(x,5.15,0),(.48,.35,31.5),'metal')
s.light('WindowBounce',(-11,3.5,0),(.32,.51,.67),2,14)
s.light('ConferenceFill',(8,4.5,-8),(1,.74,.46),1.4,6)
# ---------------------------------------------------------------- Area A stories
# Evidence of late-night work, kept off the central lanes.
s.box('PizzaBox',(-7.4,.84,10.85),(.42,.05,.42),'paper',rot=(0,14,0))
s.box('PizzaBoxTop',(-7.38,.88,10.6),(.42,.02,.42),'paper',rot=(-58,14,0))
s.cylinder('NoodleCup',(-6.35,.9,10.7),.06,.12,'ceramic')
s.box('SleepingBag',(-6.5,.13,-5.25),(1.7,.24,.55),'fabric',rot=(0,4,0))
s.box('SleepingPillow',(-5.85,.2,-5.25),(.4,.12,.32),'paper')
s.text('BuildFailed','BUILD #4,812   FAILED\nretrying (attempt 37)',(-9,1.36,-6.18),.0021,30,(1,.35,.25,1))
# Someone's opinions, in sticky notes far too big, on the column by the desk aisle.
stickies=s.node('StickyColumn','Node3D',(-11.66,0,4),props='rotation_degrees = Vector3(0, 90, 0)\n')
for idx,(y,text,mat,tilt,dx,size) in enumerate([(2.22,'WHO DEPLOYED\nON FRIDAY?','sticky_yellow',-4,-.02,.00134),(1.64,'DO NOT\nTOUCH PROD','sticky_pink',3,.03,.00166),(1.06,'works on\nmy machine','sticky_green',-2,-.02,.00166)]):
    s.box(f'StickyNote{idx}',(dx,y,0),(.56,.56,.01),mat,parent=stickies,rot=(0,0,tilt))
    s.text(f'StickyText{idx}',text,(dx,y,.007),size,64,(.15,.15,.2,1),parent=stickies,rot=(0,0,tilt),face=SIGN_FONT)
s.box('Whiteboard',(-12.0,2.2,-3.65),(1.7,1.1,.04),'paper')
s.text('WhiteboardText','ON-CALL ROTATION\nMon  YOU\nTue  YOU\nWed  YOU (backup: you)',(-12.0,2.25,-3.62),.0028,40,(.15,.2,.3,1))
s.text('Uptime','UPTIME 99.999%',(-1.7,1.05,-15.6),.004,48,(.3,.95,.7,1))

# ---------------------------------------------------------------- Area B/C wing
# Meeting wing: corridor x 14..18.5; Quick Sync and the pantry open off it.
s.box('WingFloor',(20.75,-.25,0),(13,.5,32),'carpet',True)
s.box('WingCeiling',(20.75,3.9,0),(13,.2,32),'ceiling_tile',True)
# Quick Sync annex adds four metres of width without enlarging the pantry.
s.box('WingEastWall',(27.25,2,7),(.5,4,18.5),'plaster',True)
s.box('SyncAnnexFloor',(29.25,-.25,-9),(4,.5,14),'carpet',True)
s.box('SyncAnnexCeiling',(29.25,3.9,-9),(4,.2,14),'ceiling_tile',True)
s.box('SyncEastWall',(31.25,2,-9),(.5,4,14.5),'plaster',True)
s.box('SyncAnnexNorthWall',(29.25,2,-16),(4,4,.5),'plaster',True)
for z in [-16,16]: s.box(f'WingEnd{z}',(20.75,2,z),(13,4,.5),'plaster',True)
for name,(z,length,mat) in {'QuickSyncGlassNorth':(-12.625,6.25,'glass'),'QuickSyncGlassSouth':(-4.25,4.5,'glass'),'CopyRoomWall':(2.125,8.25,'plaster'),'PantryWallSouth':(13.25,5.0,'plaster')}.items():
    s.box(name,(18.5,1.9,z),(.15,3.8,length),mat,True)
for z in [-15.75,-9.5,-6.5,-2]: s.box(f'QuickSyncMullion{z}',(18.5,1.9,z),(.12,3.8,.12),'metal')
s.box('QuickSyncHeader',(18.5,3.45,-8),(.15,.7,3),'plaster')
s.box('PantryHeader',(18.5,3.45,8.5),(.15,.7,4.5),'plaster')
s.box('QuickSyncSouthWall',(24.75,1.9,-2),(12.5,3.8,.2),'plaster',True)
s.box('PantryNorthWall',(22.75,1.9,2.0),(8.5,3.8,.2),'plaster',True)
s.box('PantryBackWall',(22.75,1.9,15.5),(8.5,3.8,.2),'plaster',True)
# Sliding meeting doors: parked inside the glass; the trap moves them shut and solid.
for name,z in [('QuickSyncDoorA',-10.25),('QuickSyncDoorB',-5.75)]:
    s.box(name,(18.42,1.6,z),(.08,3.2,1.5),'glass',True,body='collision_layer = 0\n')
    s.box('Rail',(0,1.5,0),(.1,.06,1.5),'metal',parent=name)
s.text('QuickSyncSign','MEETING ROOM 3  ·  QUICK SYNC',(18.4,3.1,-8),.0045,44,(.95,.95,.95,1),rot=(0,-90,0))
s.text('QuickSyncStatus','IN USE SINCE 2021',(18.4,2.82,-8),.003,32,(1,.45,.35,1),rot=(0,-90,0))
s.text('PantrySign','PANTRY  ·  RECOVERY ZONE',(18.4,3.1,8.5),.0045,44,(.95,.95,.95,1),rot=(0,-90,0))
s.text('CopyRoomSign','COPY ROOM  ·  OUT OF TONER SINCE Q2',(18.4,2.2,1),.0038,32,(.75,.8,.82,1),rot=(0,-90,0))
s.text('WingWayfinding','← OPERATIONS          DESKS →',(14.6,3.0,0),.004,40,(.75,.8,.82,1),rot=(0,90,0))
# Folded into breakout stations: an uninterrupted central floor for dodges and flanks.
s.box('SyncTable',(24.75,.38,-14.2),(4.4,.76,1.1),'walnut',True)
s.box('SyncBreakoutTable',(27.8,.38,-3.6),(3.2,.76,1.1),'walnut',True)
for idx,(x,z,rot) in enumerate([(22.8,-15.1,0),(24.3,-15.1,0),(25.8,-15.1,0),(27,-2.65,180),(28.6,-2.65,180)]):
    s.instance(f'SyncChair{idx}','chair',(x,0,z),rot)
s.box('SyncScreen',(30.95,2.0,-8.75),(.06,1.4,2.6),'plastic')
s.box('SyncDisplay',(30.91,2.0,-8.75),(.01,1.25,2.45),'screen')
s.text('SyncTitle','QUICK SYNC  (15 MIN)',(30.89,2.4,-8.75),.00405,52,(.95,.95,.95,1),rot=(0,-90,0))
s.text('SyncDetail','Production is down.\nFirst: align on alignment.\nThen: discuss going home.',(30.89,1.8,-8.75),.0033,36,(.75,.85,.9,1),rot=(0,-90,0))
s.light('QuickSyncLight',(24.75,3.3,-8.75),(1,.86,.68),1.6,13)
s.light('ProjectorGlow',(29.8,2.0,-8.75),(.4,.75,1),0.0,12)
s.text('SyncParkingLot','THE PARKING LOT\nWhere urgent things go to die.',(24.75,2.2,-2.12),.0035,38,(.75,.85,.9,1),rot=(0,180,0))
# Pantry props have their own authoring module for a focused recovery-room pass.
build_pantry(s, SIGN_FONT, TITLE_FONT, BODY_FONT)
for idx,z in enumerate([-10,0,10]): s.light(f'WingLight{idx}',(16.3,3.4,z),(.68,.8,.88),1.2,7)
s.node('CalendarDrift','Node3D',(16.3,0,0),props='script = '+s.external('res://game/rooms/office/calendar_drift.gd','Script'))

# ---------------------------------------------------------------- Area E corridor + vault
s.box('CorridorFloor',(9,-.25,-23.125),(7,.5,13.75),'vault_floor',True)
s.box('CorridorCeiling',(9,4.1,-23.1),(7.5,.2,14),'black',True)
for x in [5.25,12.75]: s.box(f'CorridorWall{x}',(x,2,-23),(.5,4.2,14),'plaster',True)
for idx in range(8):
    z=-18-idx*1.5
    if abs(z+23.25) > 1.2:
        s.instance(f'CorridorRackW{idx}','server_rack_lite',(6.0,0,z),90)
    s.instance(f'CorridorRackE{idx}','server_rack_lite',(12.0,0,z),-90)
    s.box(f'FloorCable{idx}',(9+((idx%3)-1)*.9,.03,z),(.06,.06,1.4),'black')
for idx,z in enumerate([-18,-22,-26,-29]): s.light(f'CorridorLight{idx}',(9,3.6,z),(.55,.75,1),1.6,6)
# A confident dashboard surrounded by racks that are visibly not fine.
s.box('DeploymentBoard',(5.55,2.0,-23.25),(.08,1.4,2.4),'plastic')
s.box('DeploymentFace',(5.6,2.0,-23.25),(.01,1.28,2.28),'screen')
s.text('DeploymentTitle','DEPLOYMENT SUCCESSFUL',(5.62,2.35,-23.25),.00273,56,(.3,1,.6,1),rot=(0,90,0))
s.text('DeploymentDetail','100% complete\n0 errors  ·  0 warnings\n0 monitors configured',(5.62,1.75,-23.25),.0034,36,(.6,.95,.75,1),rot=(0,90,0))
for idx,z in enumerate([-21.2,-25.3]):
    s.light(f'SparkLight{idx}',(6.6,1.6,z),(1,.6,.25),0.0,2.5)
    s.box(f'Spark{idx}',(6.47,1.6,z),(.04,.04,.04),'amber')
s.box('VaultFloor',(9,-.25,-38.1),(18.5,.5,16.5),'vault_floor',True)
s.box('VaultCeiling',(9,6.1,-38),(18.5,.2,16.5),'black',True)
for name,(x,length) in {'VaultSouthWest':(2.75,6),'VaultSouthEast':(15.25,6)}.items(): s.box(name,(x,3,-30),(length,6,.5),'plaster',True)
s.box('VaultHeader',(9,5.05,-30),(7,1.9,.5),'plaster',True)
s.box('VaultNorth',(9,3,-46.25),(18.5,6,.5),'plaster',True)
for x in [-.25,18.25]: s.box(f'VaultSide{x}',(x,3,-38),(.5,6,16.5),'plaster',True)
for idx in range(8):
    z=-32.5-idx*1.5
    s.instance(f'VaultRackW{idx}','server_rack_lite',(1.0,0,z),90)
    s.instance(f'VaultRackE{idx}','server_rack_lite',(17.0,0,z),-90)
for idx in range(6): s.instance(f'VaultRackN{idx}','server_rack_lite',(2.8+idx*1.1 if idx<3 else 11.0+(idx-3)*1.1,0,-45.4),0)
# The ledger the whole incident argues with: three truths, one wall.
s.box('CoreLedger',(9,2.6,-45.6),(5,5.2,.6),'black',True)
for idx,(text,color) in enumerate([('SUCCESS',(.3,1,.6,1)),('FAILED',(1,.3,.15,1)),('NOT FOUND',(1,.75,.25,1))]):
    s.box(f'LedgerFace{idx}',(9,4.1-idx*1.25,-45.28),(4.4,1.0,.02),'screen')
    s.text(f'LedgerText{idx}',text,(9,4.1-idx*1.25,-45.26),.008,72,color)
s.text('VaultTitle','PRODUCTION CORE  ·  LEDGER OF RECORD',(9,5.45,-45.27),.005,44,(.8,.85,.9,1))
for idx,(x,z,color) in enumerate([(4,-34,(.55,.3,1)),(14,-34,(.55,.3,1)),(9,-43,(1,.2,.12)),(9,-38,(.4,.6,1))]):
    s.light(f'VaultLight{idx}',(x,4.6,z),color,1.4,11)
s.node('SpawnPoints','Node3D')
for name,pos in [('A1',(-2,-8)),('A2',(2,1)),('A3',(-2,5)),('A4',(3,-4)),('D1',(-3,-11)),('D2',(2,-12)),('D3',(4,-7)),('D4',(-1,-6)),('B1',(28.5,-11.5)),('B2',(25.5,-3.5)),('B3',(22,-12)),('B4',(25,-5))]:
    s.marker('Spawn_'+name,(pos[0],.05,pos[1]))
s.marker('VaultArrival',(9,.05,-38))
s.marker('VaultEntry',(9,.05,-29))
s.marker('QuickSyncCenter',(24.75,.05,-8.75))
s.marker('CoffeeMachine',(25.4,.05,5.2))
s.marker('VendingMachine',(20.4,.05,13.65))
s.marker('Microwave',(25.4,.05,8.8))
s.marker('WellnessPoster',(23.4,.05,3.2))
s.marker('Fridge',(25.3,.05,11.55))
nav=s.external('res://game/rooms/office/navigation.tres','NavigationMesh')
s.node('Navigation','NavigationRegion3D',props=f'navigation_mesh = {nav}')
# Quiet lounge edge fills the right foreground without narrowing the combat lane.
s.box('Credenza',(12.65,.55,8),(1.1,1.1,3.6),'walnut',True)
s.box('CredenzaTop',(12.65,1.12,8),(1.15,.06,3.65),'stone')
for z in [6.9,8,9.1]: s.box(f'Drawer{z}',(12.08,.70,z),(.02,.035,.5),'metal')
s.box('Printer',(12.55,1.38,7.2),(.65,.46,.62),'plastic')
s.box('PrinterPaper',(12.25,1.62,7.2),(.4,.02,.4),'paper')
s.box('WallInlay',(13.73,2.6,0),(.025,3.4,7),'walnut')
for z in range(-3,4): s.box(f'WallSlat{z}',(13.68,2.6,z),(.045,3.4,.04),'metal')
s.text('QuietNotice','QUIET HOURS',(13.60,3,0),.006,60,rot=(0,-90,0))
s.text('QuietSubtext','16:59 — UNTIL RESOLVED',(13.60,2.4,0),.0035,38,rot=(0,-90,0))
# ---------------------------------------------------------------- Night-shift decor
# Purely decorative (no collision, outside the combat lanes): life left behind by the
# people who still work here. A brighter PropTint keeps the colour that the after-hours
# palette strips from the pantry kit.
s.node('Decor','Node3D')
s.node('DecorTint','Node',parent='Decor',props='script = '+s.external('res://game/rooms/office/prop_tint.gd','Script')+'\nvalue = 0.85\nsaturation = 0.95')
def decor(name,file,pos,rot=0,scale=2.0): s.glb(name,file,pos,rot,scale,parent='Decor')
# Window line: plants and warm floor lamps between the desk clusters and the glass.
for idx,z in enumerate([-13.2,-8.6,-3.2,2.6,8.2,13.4]): decor(f'WindowPlant{idx}','potted_plant',(-13.1,0,z),idx*40,2.3)
for idx,z in enumerate([-5.8,5.4]):
    decor(f'WindowLamp{idx}','lamp_round_floor',(-12.9,0,z),0,2.2)
    s.light(f'WindowLampLight{idx}',(-12.9,2.4,z),(1,.72,.45),1.1,4.5)
# Desks: the overtime crew's clutter, a lamp per cluster, boxes nobody unpacked.
for idx,(x,z) in enumerate([(-9.0,5.0),(-6.5,5.0),(-9.0,0.0),(-6.5,0.0),(-9.0,-6.0),(-6.5,-6.0)]):
    decor(f'DeskPlant{idx}',['plant_small_1','plant_small_2','plant_small_3'][idx%3],(x-.75,.76,z-.25),idx*55,1.6)
    decor(f'DeskBooks{idx}','books',(x+.7,.76,z-.2),idx*30,1.5)
    decor(f'DeskBox{idx}','cardboard_box_open' if idx%2 else 'cardboard_box_closed',(x+.55,0,z+.55),idx*25,1.6)
for idx,(x,z) in enumerate([(-7.75,5.0),(-7.75,-6.0)]):
    decor(f'DeskLamp{idx}','lamp_square_table',(x,.76,z-.3),0,1.8)
    s.light(f'DeskLampLight{idx}',(x,1.35,z-.3),(1,.78,.5),.9,3.2)
# The lounge (south-east): a compact seating group, clear of the wing doorway.
# Keep x >= 11.8, z 10.5..13.5 free for the approach; imported pivots are off-centre.
decor('LoungeRug','rug_round',(6.4,0.012,13.4),0,3.4)
decor('LoungeSofa','lounge_design_sofa',(9.4,0,13.9),180,2.1)
decor('LoungeChairWest','lounge_chair_relax',(7.0,0,12.5),90,2.0)
decor('LoungeChairEast','lounge_chair_relax',(9.8,0,11.4),-90,2.0)
decor('LoungeTable','table_coffee',(8.8,0,12.0),0,2.0)
decor('LoungeLaptop','laptop',(8.3,0.46,11.95),0,0.9)
decor('LoungeLamp','lamp_round_floor',(11.8,0,14.6),0,2.2)
decor('LoungePlantA','potted_plant',(6.2,0,15.0),0,2.5)
decor('LoungePlantB','potted_plant',(10.9,0,14.6),70,2.1)
decor('LoungeTV','television_modern',(9.4,.9,15.55),180,2.0)
decor('LoungeSpeakerA','speaker',(8.1,0,15.4),180,1.8)
decor('LoungeSpeakerB','speaker',(10.7,0,15.4),180,1.8)
decor('LoungeShelf','bookcase_open',(5.6,0,15.35),180,2.0)
s.light('LoungeLampLight',(11.8,2.3,14.6),(1,.7,.42),1.2,5)
s.light('LoungeTVGlow',(9.4,1.6,14.9),(.35,.75,1),.8,4)
# Deck and wing: plants on the deck corners, a bench and greenery along the corridor.
for idx,x in enumerate([5.6,10.4]): decor(f'DeckPlant{idx}','potted_plant',(x,1.5,-10.5),idx*90,2.0)
decor('WingBench','bench_cushion',(18.05,0,-1.2),-90,2.0)
for idx,z in enumerate([-14.6,14.6]): decor(f'WingPlant{idx}','potted_plant',(17.9,0,z),idx*120,2.3)
# Neon: the company's three beliefs, lit in colour so the floor never reads grey.
for name,text,pos,rot,mat,color in [
    ('NeonMoveFast','MOVE FAST',(-8.8,4.3,-15.7),0,'neon_cyan',(.2,.88,1)),
    ('NeonShipIt','SHIP IT',(9.4,3.6,15.7),180,'neon_pink',(1,.22,.62)),
    ('NeonDeploy','THINK DIFFERENT.\nDEPLOY THE SAME.',(14.3,3.1,-7.0),90,'neon_amber',(1,.7,.25))]:
    s.node(name,'Label3D',pos,props=f'text = {quote(text)}\nfont_size = 96\npixel_size = 0.006\nmodulate = {col((color[0]*2.4,color[1]*2.4,color[2]*2.4,1))}\noutline_size = 18\noutline_modulate = {col((color[0],color[1],color[2],.55))}\nshaded = false\nrotation_degrees = {vec((0,rot,0))}\n')
    tube=s.resource('BoxMesh',f'size = Vector3(4.2, 0.04, 0.04)\nmaterial = '+s.external(f'res://game/rooms/office/{mat}.tres','Material'))
    s.node(name+'Tube','MeshInstance3D',(pos[0],pos[1]-.75 if '\n' not in text else pos[1]-1.05,pos[2]),props=f'mesh = {tube}\nrotation_degrees = {vec((0,rot,0))}')
    light_offset=(0,0,.6) if rot==0 else ((0,0,-.6) if rot==180 else (.6,0,0))
    s.light(name+'Light',(pos[0]+light_offset[0],pos[1]-.3,pos[2]+light_offset[2]),color,1.4,6)
# Posters: the culture deck as framed motivational prints (black mat, photograph, serif
# title, the punchline as the caption), on the south and north walls.
for idx,(title,caption,x,z,rot,photo,accent) in enumerate([
    ('WE ARE A FAMILY*','*terms apply',-9.5,15.7,180,'family',(.95,.55,.45,1)),
    ('FAIL FAST','(NOT IN PROD)',3.0,15.7,180,'fail_fast',(.45,.85,.85,1)),
    ('YOUR WELLBEING','IS A KPI',-12.0,-15.7,0,'wellbeing',(.95,.8,.4,1)),
    ('IT WORKED','ON MY MACHINE',12.0,-15.7,0,'machine',(.75,.62,1,1))]):
    print_=s.node(f'CulturePrint{idx}','Node3D',(x,2.4,z),props=f'rotation_degrees = Vector3(0, {rot}, 0)\n')
    s.box(f'Poster{idx}',(0,0,0),(1.7,2.2,.04),'black',parent=print_)
    frame(print_,1.7,2.2)
    s.quad('PhotoBorder',(0,.36,.021),(1.26,.94),'print_white',parent=print_)
    s.quad('Photo',(0,.36,.022),(1.22,.9),f'photo_{photo}',parent=print_)
    s.box('Rule',(0,-.68,.021),(.5,.006,.002),'print_white',parent=print_)
    s.text(f'PosterText{idx}',title,(0,-.36,.022),.00137,96,(.97,.96,.93,1),parent=print_,face=TITLE_FONT)
    s.text(f'PosterCaption{idx}',caption,(0,-.58,.022),.0032,44,accent,parent=print_,face=BODY_FONT)
# The company: a lobby logo over the operations wall. The mark is an arrow that only ever
# circles back to itself.
logo=s.node('CompanyLogo','Node3D',(-.3,3.6,15.69),props='rotation_degrees = Vector3(0, 180, 0)\n')
mark=(0,.86)
for i in range(13):
    angle=math.radians(110+i*22)
    s.box(f'MarkArc{i}',(mark[0]+math.cos(angle)*.42,mark[1]+math.sin(angle)*.42,.04),(.09,.17,.05),'metal',parent=logo,rot=(0,0,math.degrees(angle)))
tip=math.radians(110+13*22)
head=s.resource('CylinderMesh','top_radius = 0.0\nbottom_radius = 0.15\nheight = 0.21\nradial_segments = 3\nmaterial = '+s.external('res://game/rooms/office/metal.tres','Material'))
s.node('MarkHead','MeshInstance3D',(mark[0]+math.cos(tip)*.42,mark[1]+math.sin(tip)*.42,.04),logo,f'mesh = {head}\nrotation_degrees = {vec((0,0,math.degrees(tip)+180))}\n')
s.cylinder('MarkCore',(mark[0],mark[1],.03),.11,.04,'neon_cyan',parent=logo,rot=(90,0,0))
s.node('Wordmark','Label3D',(0,0,.03),logo,'text = "SYNERGEX"\nfont = '+s.external(SIGN_FONT,'FontFile')+'\nfont_size = 160\npixel_size = 0.0048\nmodulate = Color(0.93, 0.96, 0.98, 1)\noutline_size = 14\noutline_modulate = Color(0.2, 0.88, 1, 0.35)\nshaded = false\n')
s.text('Tagline','WE PUT THE \'I\' IN TEAM\u2122',(0,-.4,.03),.0026,64,(.2,.88,1,1),parent=logo,face=SIGN_FONT)
s.text('SmallPrint','Now with 30% fewer employees.',(0,-.66,.03),.0028,40,(.6,.68,.72,1),parent=logo,face=BODY_FONT)
s.light('LogoWash',(-.3,5.0,14.7),(.75,.88,1),1.1,3.4)
# ---------------------------------------------------------------- The tower at night
# Our tower wraps the office floor (above every ceiling, below every floor, and out past
# the west glass), so the opening can fly in from the city and through the window.
for name,(x0,x1,y0,y1,z0,z1) in {
        'TowerAbove': (-14.3, 28.5, 6.4, 92.0, -47.0, 25.0),
        'TowerBelow': (-14.3, 28.5, -70.0, -.55, -47.0, 25.0),
        'TowerNorth': (-14.3, -1.0, -.55, 6.4, -47.0, -16.2),
        'TowerSouth': (-14.3, 14.3, -.55, 6.4, 16.2, 25.0)}.items():
    s.box(name,((x0+x1)/2,(y0+y1)/2,(z0+z1)/2),(x1-x0,y1-y0,z1-z0),'facade')
# The city: towers on every side, kept off the opening's flight line in from the west.
import random
city=random.Random(4759)
flight=((-150.0,75.0),(-14.0,1.0))
def off_flight(x,z,margin):
    (ax,az),(bx,bz)=flight
    t=max(0.0,min(1.0,((x-ax)*(bx-ax)+(z-az)*(bz-az))/((bx-ax)**2+(bz-az)**2)))
    return math.hypot(x-(ax+t*(bx-ax)),z-(az+t*(bz-az)))>margin
placed=0
while placed<46:
    angle=city.uniform(0,math.tau)
    reach=city.uniform(55,260)
    x=7+math.cos(angle)*reach
    z=-10+math.sin(angle)*reach
    w=city.uniform(14,30); d=city.uniform(14,30); h=city.uniform(30,150)
    if not off_flight(x,z,w*.7+18) or (abs(x-7)<40 and abs(z+10)<45):
        continue
    s.box(f'CityTower{placed}',(x,-70+h/2,z),(w,h,d),'facade')
    placed+=1
s.box('CityGround',(7,-70.2,-10),(700,.4,700),'black')
# Append trial resources last so unrelated scene resource IDs remain stable.
polished_ref = s.external('res://game/rooms/office/polished_workstation.tscn', 'PackedScene')
for i, node in enumerate(s.nodes):
    if 'name="YourWorkstation"' in node:
        s.nodes[i] = node.replace(s.external('res://game/rooms/office/workstation.tscn', 'PackedScene'), polished_ref)
s.nodes = [node for node in s.nodes if not any(f'name="{name}"' in node for name in ['TaskLampBase', 'TaskLampStem', 'TaskLampShade', 'TaskLampBulb'])]
lamp = s.external('res://assets/environment/poly_haven_workstation/desk_lamp_arm_01.glb', 'PackedScene')
s.nodes.append(f'[node name="TaskLamp" parent="." instance={lamp}]\nposition = Vector3(-3.37, 0.8225, 9.12)\nrotation_degrees = Vector3(0, 180, 0)\nscale = Vector3(0.72, 0.72, 0.72)')
build_office_details(s)
s.save('office_after_hours')
print('Authored office scene, shared materials, and three reusable furniture scenes.')
