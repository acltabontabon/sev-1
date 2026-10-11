"""Authored pantry props; used by build_office.py alongside the meeting-room layout."""


def build_pantry(s, SIGN_FONT, TITLE_FONT, BODY_FONT):
    # Perimeter dining leaves a clear central lane through the expanded recovery room.
    s.box('PantryTileFloor',(22.75,.012,8.75),(8.25,.02,13.15),'stone')
    # The kit's pivot is at a corner, not its centre. Keep its 0.9 m width inside
    # the east wall's inner face at x=27 and centre collision on the visible cabinet.
    s.collider('CounterCollision',(26.35,.45,7.31),(.9,.9,6.02))
    for idx,z in enumerate([4.3,5.16,6.02,7.74,8.6,9.46]): s.glb(f'Cabinet{idx}','kitchen_cabinet',(25.9,0,z),-90,2.0)
    s.glb('Sink','kitchen_sink',(25.9,0,6.88),-90,2.0)
    s.glb('CoffeeMachine','kitchen_coffee_machine',(26.1,.9,5.2),-90,2.0)
    # Printed in a hurry, taped up crooked by someone who has given up.
    notice=s.node('CoffeeNoticeSheet','Node3D',(26.98,1.9,5.2),props='rotation_degrees = Vector3(0, -90, -2.5)\n')
    s.box('CoffeeNoticePaper',(0,0,0),(1.0,.5,.01),'paper',parent=notice)
    s.text('CoffeeNotice','PLEASE LIMIT\nCOFFEE TO ONE CUP\nPER EMPLOYEE',(0,0,.008),.0028,34,(.15,.15,.18,1),parent=notice,face=SIGN_FONT)
    for side in (-1,1): s.box(f'Tape{side+1}',(side*.46,.24,.007),(.18,.05,.002),'tape',parent=notice,rot=(0,0,side*-35))
    s.glb('Microwave','kitchen_microwave',(26.1,.9,8.8),-90,2.0)
    warning=s.node('MicrowaveNoticeSheet','Node3D',(26.98,1.78,8.8),props='rotation_degrees = Vector3(0, -90, 2)\n')
    s.box('MicrowaveNoticePaper',(0,0,0),(.8,.62,.01),'paper',parent=warning)
    s.text('MicrowaveNotice','DO NOT USE\nTICKET OPEN\nSINCE 2019',(0,0,.008),.0041,32,(.85,.15,.1,1),parent=warning,face=SIGN_FONT)
    for side in (-1,1): s.box(f'Tape{side+1}',(side*.36,.29,.007),(.16,.05,.002),'tape',parent=warning,rot=(0,0,side*35))
    s.glb('Toaster','toaster',(26.1,.9,9.6),-90,2.0)
    s.glb('Fridge','kitchen_fridge_large',(26.35,0,11.55),-90,1.4)
    s.collider('FridgeCollision',(26.545,.644,11.914),(.57,1.288,.728))
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
    s.glb('PantryTrash','trashcan',(25.7,0,14.7),0,1.4)
    # People & Culture flyer: purple header, a calming stock sky, four pins.
    flyer=s.node('WellnessFlyer','Node3D',(23.4,1.75,2.12))
    s.box('WellnessPoster',(0,0,0),(1.2,1.6,.01),'paper',parent=flyer)
    s.box('WellnessBand',(0,.56,.006),(1.2,.48,.004),'wellness_purple',parent=flyer)
    s.text('WellnessTitle','BURNOUT IS\nA MINDSET',(0,.56,.01),.00229,60,(1,.97,.92,1),parent=flyer,face=TITLE_FONT)
    s.quad('WellnessPhoto',(0,-.02,.007),(1.0,.66),'photo_wellness',parent=flyer)
    s.text('WellnessBody','Wellness Week:\ntake one deep breath\n(between meetings)',(0,-.57,.008),.003,34,(.2,.2,.25,1),parent=flyer,face=BODY_FONT)
    for idx,(x,y) in enumerate([(-.54,.74),(.54,.74),(-.54,-.74),(.54,-.74)]): s.cylinder(f'Pin{idx}',(x,y,.012),.018,.02,'pin_red',parent=flyer,rot=(90,0,0))
    s.light('PantryLight',(22.75,3.3,8.25),(1,.78,.55),1.8,10)
    s.light('PantryBackFill',(22.75,3.2,13.7),(1,.8,.6),.7,5)
    s.text('LunchCourtSign','LUNCH TRIBUNAL\nALL APPLIANCES ARE INNOCENT\nUNTIL PROVEN UNDER WARRANTY',(23.6,2.5,15.38),.003,38,(.8,.85,.82,1),rot=(0,180,0))
    s.box('SamToolbox',(19.3,.18,12.7),(.65,.36,.35),'plastic')
    s.box('SamToolboxStripe',(19.3,.24,12.515),(.55,.07,.01),'poster_gold')
    s.box('SamToolboxHandle',(19.3,.42,12.7),(.28,.12,.04),'metal')
    s.node('PantryAntics','Node3D',props='script = '+s.external('res://game/rooms/office/pantry_antics.gd','Script'))
