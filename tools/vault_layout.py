"""Production Core: expanded 24 x 21 m arena with serviced industrial perimeter.

Keep incident-owned ledger labels/lights at the room root. Geometry is authored
once into text scenes; navigation is baked from fitted solid envelopes.
"""

def build_vault(s, Scene, font):
    rack = Scene('ProductionRack')
    rack.box('Cabinet', (0, 1.55, 0), (1.05, 3.1, 1.15), 'plastic', True)
    rack.box('Toe', (0, .09, .05), (1.12, .18, 1.2), 'black')
    for x in [-.48, .48]:
        rack.box(f'Rail{x}', (x, 1.58, .61), (.055, 2.9, .065), 'metal')
    for i in range(10):
        y=.31+i*.255
        rack.box(f'Blade{i}', (0,y,.607), (.88,.225,.10), 'metal')
        rack.box(f'Intake{i}', (-.12,y,.665), (.51,.145,.014), 'black')
        for slot in range(5):
            rack.box(f'Vent{i}_{slot}', (-.33+slot*.105,y,.679), (.025,.105,.01), 'plastic')
        rack.box(f'Handle{i}', (.33,y,.70), (.075,.115,.045), 'black')
        rack.box(f'Status{i}', (.20,y+.038,.677), (.027,.027,.013), 'mint' if i%4 else 'amber')
    rack.box('Header', (0,2.99,.61), (.94,.34,.08), 'black')
    rack.text('RackTag', 'CORE', (0,3,.665), .005, 36, face=font)
    rack.save('production_rack')

    s.box('VaultFloor',(9,-.25,-40.5),(24,.5,21),'vault_concrete',True)
    s.box('VaultCeiling',(9,7.6,-40.5),(24,.2,21),'black',True)
    for name,x in [('VaultSouthWest',1.25),('VaultSouthEast',16.75)]:
        s.box(name,(x,3.75,-30),(8.5,7.5,.5),'plaster',True)
    s.box('VaultHeader',(9,5.8,-30),(7,3.4,.5),'plastic',True)
    s.box('VaultNorth',(9,3.75,-51),(24,7.5,.5),'plaster',True)
    for side,x in [('West',-3),('East',21)]:
        s.box('VaultSide'+side,(x,3.75,-40.5),(.5,7.5,21),'plaster',True)
    # Separate service aisles with flush metal grating and restrained safety boundaries.
    for side,x in [('W',-.4),('E',18.4)]:
        s.box('ServiceFloor'+side,(x,.006,-40.5),(4.5,.01,20),'vault_floor')
        s.box('AisleLine'+side,(x+(2.3 if side=='W' else -2.3),.016,-40.5),(.06,.01,19),'poster_gold')
        for i,z in enumerate([-33.5,-37,-40.5,-44,-47.5]):
            s.instance(f'VaultRack{side}{i}','production_rack',(x,0,z),90 if side=='W' else -90)
            s.text(f'Bay{side}{i}',f'{side} / {i+1:02}',(x,3.65,z),.005,42,rot=(0,90 if side=='W' else -90,0),face=font)
    # Architectural rhythm: steel portal frames, ceiling ribs and real cable trays.
    for i,z in enumerate([-31.6,-37,-43,-49.5]):
        for side,x in [('W',-2.3),('E',20.3)]:
            s.box(f'VaultPier{side}{i}',(x,3.65,z),(.5,7.3,.65),'metal',True)
            s.box(f'PierFoot{side}{i}',(x,.32,z),(.75,.64,.85),'black')
            s.box(f'PierInset{side}{i}',(x+(.27 if side=='W' else -.27),3.7,z),(.035,2.9,.26),'black')
        s.box(f'VaultRoofRib{i}',(9,7.13,z),(22.8,.4,.65),'metal')
        s.box(f'VaultRoofLight{i}',(9,6.9,z),(9,.045,.13),'cool')
    for side,x in [('W',2),('E',16)]:
        for edge in [-.37,.37]:
            s.box(f'TrayRail{side}{edge}',(x+edge,5.5,-40.5),(.07,.22,18),'metal')
        for i in range(36):
            s.box(f'TrayRung{side}{i}',(x,5.39,-31.8-i*.5),(.75,.055,.075),'metal')
        for cable in range(4):
            s.cylinder(f'CeilingCable{side}{cable}',(x-.22+cable*.14,5.52,-40.5),.045,18,'black',rot=(90,0,0))
        s.cylinder('CoolingMain'+side,(x,6.35,-40.5),.18,19,'metal',rot=(90,0,0))
        for i,z in enumerate([-33,-39,-45]):
            s.cylinder(f'PipeCollar{side}{i}',(x,6.35,z),.22,.12,'black',rot=(90,0,0))
    # Deep back wall: four cooling stacks flank a monumental ledger enclosure.
    for x in [-.6,2.0,16.0,18.6]:
        s.box(f'CoolingCabinet{x}',(x,2.1,-49.9),(2.1,4.2,1.4),'plastic',True)
        s.box(f'CoolingFrame{x}',(x,2.2,-49.17),(1.9,3.75,.08),'metal')
        for fan,y in enumerate([1.25,3.05]):
            s.cylinder(f'CoolingFan{x}_{fan}',(x,y,-49.09),.68,.06,'black',rot=(90,0,0))
            s.cylinder(f'FanHub{x}_{fan}',(x,y,-49.02),.16,.06,'metal',rot=(90,0,0))
            for bar in range(7):
                s.box(f'FanGuard{x}_{fan}_{bar}',(x-.6+bar*.2,y,-48.96),(.025,1.20,.025),'metal')
        s.box(f'CoolingPilot{x}',(x,4.02,-49.05),(.8,.035,.02),'cool')
    s.box('CoreLedger',(9,3.35,-50.3),(8.1,6.7,.8),'black',True)
    for x in [4.6,13.4]:
        s.box(f'LedgerSpine{x}',(x,3.55,-49.75),(.45,7.1,.8),'metal')
        s.box(f'LedgerBeacon{x}',(x,3.6,-49.30),(.07,5.8,.025),'alert')
    for idx,(text,color) in enumerate([('SUCCESS',(.3,1,.6,1)),('FAILED',(1,.3,.15,1)),('NOT FOUND',(1,.75,.25,1))]):
        y=5.3-idx*1.65
        s.box(f'LedgerFrame{idx}',(9,y,-49.80),(7.4,1.47,.16),'metal')
        s.box(f'LedgerFace{idx}',(9,y,-49.70),(7.15,1.27,.025),'screen')
        s.text(f'LedgerText{idx}',text,(9,y,-49.675),.0105,72,color,face=font)
    s.text('VaultTitle','PRODUCTION CORE  /  001',(9,7.0,-49.72),.007,54,(.78,.85,.85,1),face=font)
    s.text('CoreSubhead','THREE SOURCES OF TRUTH. ZERO AGREEMENT.',(9,.8,-49.68),.006,42,(.55,.65,.67,1),face=font)
    # Floor hardware, repaired panels and cable gutters stay flush with the combat floor.
    for x in [3,15]:
        s.box(f'FloorGutter{x}',(x,.012,-40.8),(.32,.014,17.5),'black')
        for i in range(45):
            s.box(f'GutterSlot{x}_{i}',(x,.024,-32.2-i*.39),(.30,.012,.025),'metal')
    for i,z in enumerate([-33,-36,-39,-42,-45,-48]):
        s.box(f'FloorSeam{i}',(9,.009,z),(11.7,.008,.018),'black')
    for x in [5,13]:
        for z in [-34,-46]:
            s.box(f'AccessPlate{x}_{z}',(x,.017,z),(1.1,.016,.8),'metal')
            s.box(f'PlateHandle{x}_{z}',(x,.03,z),(.19,.012,.035),'black')
    s.text('FloorCore','PRODUCTION / NO ROLLBACK',(9,.028,-45.8),.01,64,(.46,.50,.47,1),rot=(-90,0,0),face=font)
    # Downloaded industrial power boxes, with conduit feeds and readable hazard plates.
    power=s.external('res://assets/environment/vault/power_box_01.glb','PackedScene')
    for i,(x,z,rot) in enumerate([(-.8,-38.75,90),(18.8,-38.75,-90)]):
        s.nodes.append(f'[node name="VaultPowerBox{i}" parent="." instance={power}]\nposition = Vector3({x}, 1.65, {z})\nrotation_degrees = Vector3(0, {rot}, 0)\nscale = Vector3(2.8,2.8,2.8)')
        s.box(f'PowerPedestal{i}',(x+(-.35 if i==0 else .35),1.6,z),(.18,3.2,1.5),'plastic',True)
        s.cylinder(f'PowerFeed{i}',(x+(-.35 if i==0 else .35),4.1,z),.045,1.8,'metal')
    for i,(x,z) in enumerate([(3,-32),(15,-32),(3,-47),(15,-47)]):
        ref=s.external('res://assets/environment/operations/caged_hanging_light.glb','PackedScene')
        s.nodes.append(f'[node name="VaultPractical{i}" parent="." instance={ref}]\nposition = Vector3({x},5.05,{z})\nscale = Vector3(1.5,1.5,1.5)')
        s.cylinder(f'PracticalDrop{i}',(x,6.15,z),.018,2.2,'black')
    s.text('SafetyWest','PPE REQUIRED\nBUDGET NOT PROVIDED',(-2.70,4.0,-35),.008,42,(.8,.72,.46,1),rot=(0,90,0),face=font)
    s.text('SafetyEast','FIRE RESPONSE\nPLEASE LOG A TICKET',(20.70,4.0,-35),.008,42,(.8,.72,.46,1),rot=(0,-90,0),face=font)
    # Restrained cool perimeter; warm practical pools establish the fight silhouette.
    for idx,(x,z,color) in enumerate([(3,-34,(.52,.66,.73)),(15,-34,(.52,.66,.73)),(9,-47,(1,.34,.14)),(9,-39,(.58,.7,.8))]):
        s.light(f'VaultLight{idx}',(x,5.2,z),color,1.2,12)
    for i,z in enumerate([-35,-44]):
        s.light(f'VaultCombatKey{i}',(9,6.8,z),(.74,.80,.82),1.8,13,spot=True,shadow=True)
    # Bounded breakable pockets, reachable from the new side and rear dodge lanes.
    for i,(x,z) in enumerate([(2.2,-35.5),(16.1,-34.1),(2.2,-44.3),(16.3,-44.8),(5,-47.3),(13,-47.3)]):
        s.node(f'VaultBreakable{i}','StaticBody3D',(x,0,z),props='script = '+s.external('res://game/rooms/office/vault_breakable.gd','Script')+f'\ncanister = {str(i%2==0).lower()}')
