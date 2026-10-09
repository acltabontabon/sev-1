#!/usr/bin/env python3
"""Author deterministic, editable Godot scenes. No runtime generation or dependencies.
Layout and modular prop sources live here; regenerate then rebake navigation.
"""
from pathlib import Path
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'game/rooms/office'
OUT.mkdir(parents=True, exist_ok=True)

def vec(v): return 'Vector3(%s)' % ', '.join(f'{x:.5f}' for x in v)
def col(v): return 'Color(%s)' % ', '.join(str(x) for x in v)
def quote(s): return '"' + s.replace('"', '\\"').replace('\n', '\\n') + '"'

# Small, shared native materials; texture noise adds tactile scale without downloads.
materials = {
 'carpet': ((.14,.16,.17,1), .96, 0), 'plaster': ((.29,.32,.32,1), .9, 0),
 'walnut': ((.32,.19,.105,1), .55, 0), 'metal': ((.105,.125,.14,1), .32, .8),
 'plastic': ((.022,.028,.033,1), .65, 0), 'fabric': ((.08,.11,.12,1), .98, 0),
 'stone': ((.22,.25,.25,1), .36, 0), 'paper': ((.7,.69,.61,1), .9, 0),
 'ceramic': ((.38,.40,.36,1), .25, 0), 'black': ((.012,.017,.025,1), .85, 0),
 'screen': ((.015,.055,.068,1), .42, 0), 'warm': ((1,.74,.43,1), .45, 0),
 'cool': ((.67,.81,.85,1), .5, 0), 'alert': ((.85,.10,.035,1), .5, 0),
 'city': ((.12,.18,.23,1), .9, 0), 'mint': ((.18,.46,.45,1), .5, 0), 'glass': ((.17,.29,.32,.12), .12, .15),
}
for name,(color,rough,metallic) in materials.items():
    extra=''; resources=''
    if name in ('carpet','plaster','walnut','fabric'):
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
        if name=='walnut': extra=extra.replace('Vector3(3, 3, 3)','Vector3(0.3, 7, 7)')
    if name in ('screen','warm','cool','alert','mint'):
        extra+=f'emission_enabled = true\nemission = {col(color)}\nemission_energy_multiplier = {0.65 if name=="screen" else 1.3}\n'
    if name=='glass': extra+='transparency = 1\ncull_mode = 2\n'
    (OUT/f'{name}.tres').write_text(f'[gd_resource type="StandardMaterial3D" format=3]\n\n{resources}\n[resource]\nalbedo_color = {col(color)}\nroughness = {rough}\nmetallic = {metallic}\n'+extra)

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
        self.nodes.append(f'[node name="{name}" type="{kind}" parent="{parent}"]\nposition = {vec(pos)}\n{props}')
        return name if parent=='.' else parent+'/'+name
    def box(self,name,pos,size,mat,solid=False,parent='.',rot=None):
        m=self.external(f'res://game/rooms/office/{mat}.tres','Material')
        mesh=self.resource('BoxMesh',f'size = {vec(size)}\nmaterial = {m}')
        rotation='' if rot is None else f'rotation_degrees = {vec(rot)}\n'
        if solid:
            path=self.node(name,'StaticBody3D',pos,parent,rotation)
            self.node('Mesh','MeshInstance3D',parent=path,props=f'mesh = {mesh}')
            shape=self.resource('BoxShape3D',f'size = {vec(size)}')
            self.node('Collision','CollisionShape3D',parent=path,props=f'shape = {shape}')
        else: self.node(name,'MeshInstance3D',pos,parent,f'mesh = {mesh}\n'+rotation+('cast_shadow = 0' if mat in ('glass','screen','cool','warm','alert','mint') else ''))
    def cylinder(self,name,pos,radius,height,mat,parent='.',rot=None):
        m=self.external(f'res://game/rooms/office/{mat}.tres','Material')
        mesh=self.resource('CylinderMesh',f'top_radius = {radius}\nbottom_radius = {radius}\nheight = {height}\nradial_segments = 12\nmaterial = {m}')
        self.node(name,'MeshInstance3D',pos,parent,f'mesh = {mesh}\n'+('' if rot is None else f'rotation_degrees = {vec(rot)}'))
    def text(self,name,text,pos,size=.008,font=40,color=(.65,.77,.77,1),rot=(0,0,0),parent='.'):
        self.node(name,'Label3D',pos,parent,f'text = {quote(text)}\nfont_size = {font}\npixel_size = {size}\nmodulate = {col(color)}\noutline_size = 0\nrotation_degrees = {vec(rot)}\n')
    def instance(self,name,file,pos,rot=0):
        ref=self.external(f'res://game/rooms/office/{file}.tscn','PackedScene')
        self.nodes.append(f'[node name="{name}" parent="." instance={ref}]\nposition = {vec(pos)}\nrotation_degrees = Vector3(0, {rot}, 0)')
    def light(self,name,pos,color,energy,range_,spot=False,shadow=False,rot=(-90,0,0)):
        props=f'light_color = {col((*color,1))}\nlight_energy = {energy}\nshadow_enabled = {str(shadow).lower()}\n'
        props+=f'spot_range = {range_}\nspot_angle = 65\nspot_attenuation = 0.65\nrotation_degrees = {vec(rot)}' if spot else f'omni_range = {range_}\nomni_attenuation = 1.4'
        self.node(name,'SpotLight3D' if spot else 'OmniLight3D',pos,props=props)
    def save(self,file):
        ext='\n'.join(f'[ext_resource type="{kind}" path="{path}" id="{rid}"]' for path,(rid,kind) in self.ext.items())
        (OUT/f'{file}.tscn').write_text('[gd_scene format=3]\n\n'+ext+'\n\n'+'\n\n'.join(self.res+self.nodes)+'\n')

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

rack=Scene('ServerRack')
rack.box('Cabinet',(0,1.2,0),(.85,2.4,.90),'metal',True)
rack.box('Front',(0,1.2,.46),(.76,2.23,.025),'plastic')
for j in range(10):
    rack.box(f'Unit{j}',(0,.22+j*.205,.485),(.68,.17,.022),'metal')
    for k in range(4): rack.box(f'Vent{j}_{k}',(-.05,.18+j*.205+k*.023,.5),(.42,.007,.01),'black')
    rack.box(f'LED{j}',(.26,.23+j*.205,.502),(.027,.017,.009),'alert' if j in (2,6,8) else 'mint')
rack.save('server_rack')

s=Scene('OfficeAfterHours')
s.box('Floor',(0,-.25,0),(28,.5,32),'carpet',True)
s.box('North',(0,3,-16),(28,6,.5),'plaster',True)
s.box('South',(0,3,16),(28,6,.5),'plaster',True)
s.box('East',(14,3,0),(.5,6,32),'plaster',True)
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
for x in [-13.7,13.7]: s.box(f'Skirting{x}',(x,.10,0),(.05,.2,31.5),'metal')
for z in [-15.72,15.72]: s.box(f'Skirting{z}',(0,.10,z),(27.5,.2,.05),'metal')
for x in [-12,12]:
    for z in [-12,-4,4,12]:
        s.box(f'Column{x}_{z}',(x,2.75,z),(.65,5.5,.65),'plaster',True)
        s.box(f'Base{x}_{z}',(x,.20,z),(.68,.4,.68),'metal')
for z in range(-14,16,4):
    s.box(f'Mullion{z}',(-13.75,3,z),(.16,5.2,.11),'metal')
    s.box(f'Beam{z}',(0,5.45,z),(27.5,.23,.16),'metal')
    # Skyline glimpses between structural bays, entirely outside playable shell.
    for j in range(3):
        x=-19-j*4
        s.box(f'Tower{z}_{j}',(x,1+j*1.1,z),(2.6,10+j*2,2.2),'black')
        for k in range(4): s.box(f'CityLight{z}_{j}_{k}',(x+1.31,1+k*.8,z),(.01,.08,1.35),'city')
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
s.box('MeetingDisplay',(8,3.5,-9.651),(3.02,1.32,.008),'screen')
s.text('MeetingTitle','Q4 ALIGNMENT',(8,3.8,-9.63),.004,55)
s.text('MeetingTarget','DO MORE.\nWITH LESS.',(8,3.3,-9.63),.005,55)
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
s.light('TaskLight',(-3.35,1.28,9.5),(1,.67,.36),2.8,3.5)
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
s.box('ServiceDoor',(9,2.15,-15.70),(3.6,4.3,.10),'black')
for i in range(9):
    scale=1-i*.083
    for side in [-1,1]: s.box(f'Tunnel{i}_{side}',(9+side*1.55*scale,2.3,-15.59+i*.004),(.035,3.6*scale,.005),'cool')
    s.box(f'TunnelTop{i}',(9,2.3+1.8*scale,-15.55+i*.004),(3.1*scale,.035,.005),'cool')
s.text('DoorNotice','AUTHORIZED PERSONNEL', (9,.68,-15.47),.004,38)
s.text('Wayfinding','OPERATIONS  /  04',(-8.3,3.4,-15.6),.005,48)
# Selective dry humor, not a wall of jokes.
s.box('Poster',(13.70,2.4,7),(.07,1.65,1.12),'paper')
s.text('PosterText','ALL SYSTEMS\nOPERATIONAL*',(13.65,2.6,7),.004,46,(.06,.10,.12,1),rot=(0,-90,0))
s.text('PosterFootnote','*Except the important ones.',(13.64,1.88,7),.003,23,(.06,.10,.12,1),rot=(0,-90,0))
s.text('OfficeIdentity','SEV / 01',(0,3.7,15.69),.008,85,rot=(0,180,0))
s.text('OfficeSubtitle','ENGINEERING  ·  AFTER HOURS',(0,2.8,15.68),.005,40,rot=(0,180,0))
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
s.save('office_after_hours')
print('Authored office scene, shared materials, and three reusable furniture scenes.')
