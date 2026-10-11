"""Authored pantry props; used by build_office.py alongside the meeting-room layout."""
import math
import random

# The kitchen run follows the annex's east wall (inner face x=31).
KITCHEN = 4.0
PARTY = (26.5, 13.4)
# Kenney's food kit is modelled at roughly 2.4x life size.
FOOD = .42
BALLOONS = ['balloon_pink', 'balloon_cyan', 'balloon_gold', 'balloon_lime', 'balloon_violet']


def build_pantry(s, SIGN_FONT, TITLE_FONT, BODY_FONT):
    k = KITCHEN
    # Perimeter dining leaves a clear central lane through the expanded recovery room.
    s.box('PantryTileFloor',(24.75,.012,8.75),(12.25,.02,13.15),'stone')
    # The kit's pivot is at a corner, not its centre. Keep its 0.9 m width inside
    # the east wall's inner face and centre collision on the visible cabinet.
    s.collider('CounterCollision',(26.35+k,.45,7.31),(.9,.9,6.02))
    for idx,z in enumerate([4.3,5.16,6.02,7.74,8.6,9.46]): s.glb(f'Cabinet{idx}','kitchen_cabinet',(25.9+k,0,z),-90,2.0)
    s.glb('Sink','kitchen_sink',(25.9+k,0,6.88),-90,2.0)
    s.glb('CoffeeMachine','kitchen_coffee_machine',(26.1+k,.9,5.2),-90,2.0)
    # Printed in a hurry, taped up crooked by someone who has given up.
    notice=s.node('CoffeeNoticeSheet','Node3D',(26.98+k,1.9,5.2),props='rotation_degrees = Vector3(0, -90, -2.5)\n')
    s.box('CoffeeNoticePaper',(0,0,0),(1.0,.5,.01),'paper',parent=notice)
    s.text('CoffeeNotice','PLEASE LIMIT\nCOFFEE TO ONE CUP\nPER EMPLOYEE',(0,0,.008),.0028,34,(.15,.15,.18,1),parent=notice,face=SIGN_FONT)
    for side in (-1,1): s.box(f'Tape{side+1}',(side*.46,.24,.007),(.18,.05,.002),'tape',parent=notice,rot=(0,0,side*-35))
    s.glb('Microwave','kitchen_microwave',(26.1+k,.9,8.8),-90,2.0)
    warning=s.node('MicrowaveNoticeSheet','Node3D',(26.98+k,1.78,8.8),props='rotation_degrees = Vector3(0, -90, 2)\n')
    s.box('MicrowaveNoticePaper',(0,0,0),(.8,.62,.01),'paper',parent=warning)
    s.text('MicrowaveNotice','DO NOT USE\nTICKET OPEN\nSINCE 2019',(0,0,.008),.0041,32,(.85,.15,.1,1),parent=warning,face=SIGN_FONT)
    for side in (-1,1): s.box(f'Tape{side+1}',(side*.36,.29,.007),(.16,.05,.002),'tape',parent=warning,rot=(0,0,side*35))
    s.glb('Toaster','toaster',(26.1+k,.9,9.6),-90,2.0)
    s.glb('Fridge','kitchen_fridge_large',(26.35+k,0,11.55),-90,1.4)
    s.collider('FridgeCollision',(26.545+k,.644,11.914),(.57,1.288,.728))
    s.box('VendingBody',(20.4,1.0,14.85),(1.1,2.0,.8),'black',True)
    s.box('VendingGlass',(20.25,1.15,14.44),(.75,1.45,.02),'screen')
    for row,y in enumerate([.65,.98,1.31]):
        for column,x in enumerate([19.98,20.25,20.52]):
            s.box(f'SnackPacket{row}_{column}',(x,y,14.42),(.15,.22,.035),['paper','poster_gold','poster_teal'][(row+column)%3])
            s.box(f'SnackStripe{row}_{column}',(x,y,14.399),(.13,.035,.005),'plastic')
    s.box('VendingPanel',(20.83,1.15,14.44),(.2,1.0,.02),'plastic')
    s.text('VendingName','SNACK-O-MATIC',(20.4,1.94,14.43),.00205,40,(1,.85,.3,1),rot=(0,180,0))
    s.box('VendingErrorStrip',(20.25,1.74,14.426),(.72,.15,.004),'screen',rot=(0,180,0))
    s.text('VendingError','ERR: ITEM 404',(20.25,1.74,14.422),.0028,30,(1,.35,.25,1),rot=(0,180,0),face=SIGN_FONT)
    s.cylinder('PantryTableTop',(20.6,.74,4.4),.6,.04,'walnut')
    s.cylinder('PantryTableStem',(20.6,.37,4.4),.06,.72,'metal')
    s.collider('PantryTableCollision',(20.6,.4,4.4),(1.1,.8,1.1))
    s.cylinder('PantryMug',(20.4,.81,4.2),.05,.1,'ceramic')
    for idx,(x,z,rot) in enumerate([(19.6,4.4,-90),(21.6,4.4,90),(20.6,5.4,180)]): s.instance(f'PantryChair{idx}','chair',(x,0,z),rot)
    s.node('PropTint','Node',props='script = '+s.external('res://game/rooms/office/prop_tint.gd','Script'))
    s.glb('PantryPlant','potted_plant',(19.2,0,2.7),0,2.4)
    s.glb('PantryTrash','trashcan',(25.7+k,0,14.7),0,1.4)
    # People & Culture flyer: purple header, a calming stock sky, four pins.
    flyer=s.node('WellnessFlyer','Node3D',(23.4,1.75,2.12))
    s.box('WellnessPoster',(0,0,0),(1.2,1.6,.01),'paper',parent=flyer)
    s.box('WellnessBand',(0,.56,.006),(1.2,.48,.004),'wellness_purple',parent=flyer)
    s.text('WellnessTitle','BURNOUT IS\nA MINDSET',(0,.56,.01),.00229,60,(1,.97,.92,1),parent=flyer,face=TITLE_FONT)
    s.quad('WellnessPhoto',(0,-.02,.007),(1.0,.66),'photo_wellness',parent=flyer)
    s.text('WellnessBody','Wellness Week:\ntake one deep breath\n(between meetings)',(0,-.57,.008),.003,34,(.2,.2,.25,1),parent=flyer,face=BODY_FONT)
    for idx,(x,y) in enumerate([(-.54,.74),(.54,.74),(-.54,-.74),(.54,-.74)]): s.cylinder(f'Pin{idx}',(x,y,.012),.018,.02,'pin_red',parent=flyer,rot=(90,0,0))
    s.light('PantryLight',(24.875,3.3,8.25),(1,.78,.55),1.8,12)
    s.light('PantryBackFill',(24.875,3.2,13.7),(1,.8,.6),.7,7)
    s.text('LunchCourtSign','LUNCH TRIBUNAL\nALL APPLIANCES ARE INNOCENT\nUNTIL PROVEN UNDER WARRANTY',(22.0,2.5,15.38),.003,38,(.8,.85,.82,1),rot=(0,180,0))
    s.box('SamToolbox',(19.3,.18,12.7),(.65,.36,.35),'plastic')
    s.box('SamToolboxStripe',(19.3,.24,12.515),(.55,.07,.01),'poster_gold')
    s.box('SamToolboxHandle',(19.3,.42,12.7),(.28,.12,.04),'metal')
    build_party(s, SIGN_FONT, TITLE_FONT, BODY_FONT)
    s.node('PantryAntics','Node3D',props='script = '+s.external('res://game/rooms/office/pantry_antics.gd','Script'))


def catenary(start, end, sag, count):
    """Evenly spaced points along a sagging line between two ceiling fixings."""
    for index in range(count):
        t = (index + .5) / count
        yield tuple(start[i] + (end[i] - start[i]) * t for i in range(3)), t, sag * 4 * t * (1 - t)


def string(s, name, low, high, parent='.'):
    """A thin ribbon from a tie-off up to a balloon's knot."""
    v = [high[i] - low[i] for i in range(3)]
    length = math.sqrt(sum(x * x for x in v))
    pitch = math.degrees(math.acos(v[1] / length))
    yaw = math.degrees(math.atan2(v[0], v[2]))
    middle = tuple((high[i] + low[i]) / 2 for i in range(3))
    s.box(name, middle, (.006, length, .006), 'paper', parent=parent, rot=(pitch, yaw, 0))


def balloon(s, name, at, color, tie=None, parent='.'):
    s.sphere(name, at, .17, color, parent=parent, scale=(1, 1.2, 1))
    knot = (at[0], at[1] - .215, at[2])
    s.sphere(name + 'Knot', knot, .025, color, parent=parent)
    if tie is not None:
        string(s, name + 'String', tie, knot, parent)


def build_party(s, SIGN_FONT, TITLE_FONT, BODY_FONT):
    """Kevin's birthday: a Culture Committee celebration taking over the back of the pantry."""
    rng = random.Random(41)
    x, z = PARTY
    # Someone was allowed to paint one wall. It had to be this one.
    s.box('PartyFeatureWall',(24.875,1.9,15.392),(12.4,3.8,.01),'party_wall')
    # A mail-merge banner: the template field was never filled in.
    s.box('PartyBannerStrip',(x,2.72,15.37),(6.0,.6,.012),'paper')
    s.text('PartyBanner','HAPPY BIRTHDAY {FIRST_NAME}!',(x,2.72,15.36),.0031,64,(.86,.1,.44,1),rot=(0,180,0),face=TITLE_FONT)
    for side in (-1,1): s.box(f'PartyBannerTape{side+1}',(x+side*2.95,2.98,15.36),(.2,.06,.003),'tape',rot=(0,180,side*30))
    # The table: a folding table under a plastic cloth that reaches the floor.
    s.box('PartyTable',(x,.38,z),(2.6,.76,1.0),'party_cloth')
    s.collider('PartyTableCollision',(x,.4,z),(2.6,.8,1.0))
    cake = s.node('BirthdayCake','Node3D',(x,.76,z-.05))
    intact = s.node('Intact','Node3D',parent=cake)
    s.box('CakeBoard',(0,.01,0),(.68,.02,.48),'paper',parent=intact)
    s.box('CakeSponge',(0,.085,0),(.6,.13,.4),'frosting',parent=intact)
    for idx,(px,pz,sx,sz) in enumerate([(0,-.2,.62,.03),(0,.2,.62,.03),(-.3,0,.03,.42),(.3,0,.03,.42)]):
        s.box(f'CakePiping{idx}',(px,.155,pz),(sx,.03,sz),'balloon_pink',parent=intact)
    # Procurement had one font left and a different employee on file.
    s.text('CakeIcing','HAPPY BIRTHDAY\nKELVIN',(0,.152,-.03),.0012,56,(.06,.22,.78,1),rot=(-90,180,0),parent=intact,face=SIGN_FONT)
    flames = s.node('Flames','Node3D',parent=cake)
    for idx in range(6):
        cx = -.2 + idx * .08
        s.cylinder(f'Candle{idx}',(cx,.2,.14),.008,.09,['balloon_cyan','balloon_pink','balloon_gold'][idx%3],parent=intact)
        s.sphere(f'Flame{idx}',(cx,.262,.14),.013,'flame',parent=flames,scale=(1,1.8,1))
    s.node('CandleGlow','OmniLight3D',(0,.5,.22),parent=flames,props='light_color = Color(1, 0.7, 0.35, 1)\nlight_energy = 0.35\nomni_range = 1.6\nshadow_enabled = false\n')
    # After the bugs come out: a crater and frosting everywhere it should not be.
    ruin = s.node('Ruin','Node3D',parent=cake,props='visible = false\n')
    s.box('RuinBoard',(0,.01,0),(.68,.02,.48),'paper',parent=ruin)
    s.box('RuinSponge',(-.12,.04,.04),(.32,.06,.3),'frosting',parent=ruin,rot=(0,24,8))
    for idx in range(14):
        angle = idx * 2.4
        reach = .35 + .5 * ((idx * .618) % 1)
        lift = .0 if reach < .6 else -.75
        s.sphere(f'Splat{idx}',(math.cos(angle)*reach,lift+.02,math.sin(angle)*reach*.7),.05+.03*(idx%3),['frosting','balloon_pink'][idx%4==0],parent=ruin,scale=(1,.18,1))
    # Office party catering: two pizzas, cupcakes, donuts, soda. The gift is from
    # Leadership; the card is from everyone, for someone.
    for idx in range(2): s.glb(f'PizzaBox{idx}','pizza_box',(x-.95,.76+idx*.04,z+.15),idx*7,FOOD,kit='kenney_food')
    s.glb('PartyPizza','pizza',(x-.95,.84,z+.15),20,FOOD*.95,kit='kenney_food')
    for idx,(cx,cz) in enumerate([(-.5,-.3),(-.36,-.36),(-.62,-.38)]): s.glb(f'Cupcake{idx}','cupcake',(x+cx,.76,z+cz),idx*40,FOOD,kit='kenney_food')
    for idx,(cx,cz) in enumerate([(.42,-.34),(.56,-.28)]): s.glb(f'Donut{idx}','donut_sprinkles',(x+cx,.76,z+cz),idx*60,FOOD,kit='kenney_food')
    s.glb('SodaBottle','soda_bottle',(x-1.15,.76,z-.3),0,FOOD,kit='kenney_food')
    for idx,(cx,cz) in enumerate([(1.0,.3),(1.12,.12),(-.3,.38)]): s.glb(f'SodaCan{idx}','soda_can',(x+cx,.76,z+cz),idx*50,FOOD*.85,kit='kenney_food')
    s.glb('CrushedCan','soda_can_crushed',(x+1.9,.0,z-.9),30,FOOD*.85,kit='kenney_food')
    s.glb('LeftoverPizzaBox','pizza_box',(20.75,.76,4.25),12,FOOD,kit='kenney_food')
    s.glb('LeftoverPizza','pizza',(20.75,.8,4.25),40,FOOD*.95,kit='kenney_food')
    s.box('GiftBox',(x+1.0,.89,z+.05),(.3,.26,.3),'balloon_cyan')
    s.box('GiftRibbonA',(x+1.0,.89,z+.05),(.31,.27,.05),'balloon_gold')
    s.box('GiftRibbonB',(x+1.0,.89,z+.05),(.05,.27,.31),'balloon_gold')
    s.sphere('GiftBow',(x+1.0,1.04,z+.05),.06,'balloon_gold',scale=(1.4,.6,1))
    s.box('GiftTag',(x+1.0,.86,z-.105),(.2,.11,.004),'paper')
    s.text('GiftTagText','FROM: LEADERSHIP\n(it\'s a mug)',(x+1.0,.86,z-.11),.0005,40,(.15,.15,.2,1),rot=(0,180,0),face=BODY_FONT)
    s.box('BirthdayCard',(x+.5,.87,z-.33),(.3,.2,.008),'paper',rot=(0,10,0))
    s.text('BirthdayCardText','Dear Kelvin,\nBest wishes!\n— Everyone\n(Legal declined to sign)',(x+.5,.87,z-.336),.0006,40,(.2,.2,.3,1),rot=(0,190,0),face=BODY_FONT)
    for idx in range(5): s.cylinder(f'PartyPlate{idx}',(x+.45,.765+idx*.006,z+.3),.11,.005,'paper')
    for idx in range(30):
        s.box(f'TableConfetti{idx}',(x+rng.uniform(-1.25,1.25),.762,z+rng.uniform(-.45,.45)),(.035,.002,.025),BALLOONS[idx%5],rot=(0,rng.uniform(0,180),0))
    for idx in range(48):
        angle, reach = rng.uniform(0, math.tau), rng.uniform(1.0, 2.6)
        s.box(f'FloorConfetti{idx}',(x+math.cos(angle)*reach*1.3,.024,min(15.2,z+math.sin(angle)*reach)),(.04,.002,.03),BALLOONS[idx%5],rot=(0,rng.uniform(0,180),0))
    # Balloon bunches tied to each end of the table; one has already given up.
    for side,tie in [(-1,(x-1.25,.77,z-.4)),(1,(x+1.25,.77,z-.4))]:
        for idx in range(4):
            angle = idx * 1.9 + side
            at = (tie[0]+math.cos(angle)*.32+side*.1, 1.75+.22*idx+rng.uniform(-.05,.05), tie[2]+math.sin(angle)*.28-.05)
            balloon(s, f'Bunch{side+1}Balloon{idx}', at, BALLOONS[(idx+side+5)%5], tie)
    s.sphere('SadBalloon',(x+1.7,.16,z-1.15),.17,'balloon_violet',scale=(1,.75,1.15))
    s.text('SadBalloonText','41',(x+1.7,.18,z-1.37),.0022,48,(1,1,1,1),rot=(0,180,0),face=TITLE_FONT)
    # Helium has found the ceiling across the room, strings dangling at head height.
    for idx in range(14):
        at = (rng.uniform(19.6,30.4), 3.56, rng.uniform(3.0,14.6))
        balloon(s, f'CeilingBalloon{idx}', at, BALLOONS[idx%5], (at[0]+rng.uniform(-.12,.12), 2.45+rng.uniform(0,.4), at[2]+rng.uniform(-.12,.12)))
    # Bunting: one run along the painted wall, one across the room from the door.
    for name,start,end,sag,count in [('BackBunting',(18.8,3.55,15.25),(31.0,3.55,15.25),.35,24),
                                     ('CrossBunting',(19.0,3.6,2.3),(31.0,3.6,15.2),.6,30)]:
        run = (end[0]-start[0], end[2]-start[2])
        yaw = math.degrees(math.atan2(-run[1], run[0]))
        for idx,(at,t,drop) in enumerate(catenary(start, end, sag, count)):
            s.prism(f'{name}{idx}',(at[0],at[1]-drop-.1,at[2]),(.2,.24,.004),BALLOONS[idx%5],rot=(0,yaw,180))
    # Fairy lights over the painted wall: decoration, not illumination.
    for idx,(at,t,drop) in enumerate(catenary((18.8,3.15,15.33),(31.0,3.15,15.33),.45,40)):
        s.sphere(f'FairyLight{idx}',(at[0],at[1]-drop,at[2]),.022,'fairy')
    for idx in range(9):
        at = (rng.uniform(23.5,30.2), 3.3, rng.uniform(10.5,15.0))
        s.box(f'Streamer{idx}',at,(.07,1.0,.004),BALLOONS[idx%5],rot=(0,rng.uniform(0,180),rng.uniform(-4,4)))
    s.light('PartyGlowPink',(x,2.9,z-.6),(1,.42,.72),1.3,6.5)
    s.light('PartyGlowCyan',(21.5,3.0,10.5),(.35,.8,1),.7,6)
    # The invitation, inside by the door, and a sign hung under the pantry header.
    invite=s.node('PartyFlyer','Node3D',(18.59,1.55,12.0),props='rotation_degrees = Vector3(0, 90, 1.5)\n')
    s.box('PartyFlyerPaper',(0,0,0),(1.3,1.7,.01),'paper',parent=invite)
    s.box('PartyFlyerBand',(0,.6,.006),(1.3,.44,.004),'balloon_pink',parent=invite)
    s.text('PartyFlyerTitle','CULTURE COMMITTEE\nPRESENTS',(0,.6,.01),.0016,48,(1,.97,.92,1),parent=invite,face=TITLE_FONT)
    s.text('PartyFlyerBody','KEVIN TURNS 41\nPantry · 5:30–5:45\nCake fund: $10\n(auto-deducted)\nAttendance tracked',(0,-.2,.008),.0031,34,(.2,.2,.25,1),parent=invite,face=BODY_FONT)
    for idx,(px,py) in enumerate([(-.58,.8),(.58,.8)]): s.box(f'PartyFlyerTape{idx}',(px,py,.007),(.16,.05,.002),'tape',parent=invite,rot=(0,0,(idx*2-1)*-35))
    s.box('PartyDoorSign',(18.4,2.92,8.5),(.012,.3,2.4),'balloon_pink')
    s.text('PartyDoorText','PARTY IN PROGRESS  ·  CAKE (MANDATORY)',(18.39,2.92,8.5),.0028,40,(1,1,1,1),rot=(0,-90,0),face=SIGN_FONT)
    for idx in range(3):
        at = (18.05+idx*.05, 1.6+.25*idx, 11.15+(idx-1)*.22)
        balloon(s, f'DoorBalloon{idx}', at, BALLOONS[idx*2%5], (18.1,.05,11.15))
    s.box('DoorBalloonWeight',(18.1,.05,11.15),(.1,.1,.1),'balloon_gold')
