"""Static office finish: ceiling, workstation hardware and perimeter storage.

Original native geometry; existing CC0 materials. Filing cabinets have fitted static collision; small finish remains decorative.
"""


def build_office_details(s):
    # A continuous acoustic ceiling with tee runners hides the warehouse void.
    # Keep it above existing fixtures and camera clearance; no new floor obstacles.
    p = s.node('OfficeFinish', 'Node3D')
    s.box('AcousticCeiling', (0, 5.5, 0), (27.5, .06, 31.5), 'ceiling_tile', parent=p)
    for x in range(-13, 14, 2):
        s.box(f'CeilingTeeX{x}', (x, 5.455, 0), (.025, .025, 31.5), 'office_enamel', parent=p)
    for z in range(-15, 16, 2):
        s.box(f'CeilingTeeZ{z}', (0, 5.455, z), (27.5, .025, .025), 'office_enamel', parent=p)
    # Ducts disappear above the acoustic panels. Recessed return grilles remain.
    for idx, (x, z) in enumerate([(-10, -10), (-10, 10), (10, 10), (2, -6)]):
        s.box(f'AirReturnFrame{idx}', (x, 5.405, z), (1.0, .06, .6), 'office_enamel', parent=p)
        s.box(f'AirReturnWell{idx}', (x, 5.37, z), (.9, .015, .5), 'black', parent=p)
        for slat in range(6):
            s.box(f'AirReturn{idx}Slat{slat}', (x, 5.355, z-.21+slat*.084), (.9, .02, .025), 'office_enamel', parent=p)
    for i, node in enumerate(s.nodes):
        if any(f'name="Duct{x}"' in node for x in [-5, 5]):
            s.nodes[i] += '\nvisible = false'
    # Partition edging and small pinboard details make these read as office bays.
    for idx, z in enumerate([4.45, -.55, -6.55]):
        s.box(f'DividerCap{idx}', (-7.75, 1.412, z), (5.03, .04, .12), 'office_enamel', parent=p)
        for side, x in enumerate([-10.25, -7.75, -5.25]):
            s.box(f'DividerPost{idx}_{side}', (x, 1.05, z), (.04, .75, .13), 'office_enamel', parent=p)
        for note, (x, mat) in enumerate([(-9.5, 'sticky_yellow'), (-6.9, 'sticky_pink')]):
            s.box(f'BayNote{idx}_{note}', (x, 1.22, z+.052), (.12, .13, .008), mat, parent=p, rot=(0, 0, -5+note*9))
    # Low metal storage fills the unused south wall, outside circulation and the
    # opening's approach to the desk. Fitted boxes stop bodies at the cabinet fronts.
    for idx, x in enumerate([-12.1, -10.8, -7.0]):
        cabinet = s.node(f'FileCabinet{idx}', 'Node3D', (x, 0, 15.18), parent=p)
        s.collider('Collision', (0,.61,0), (1.16,1.22,.74), parent=cabinet)
        s.box('Carcass', (0, .63, 0), (1.16, 1.18, .70), 'office_enamel', parent=cabinet)
        s.box('Plinth', (0, .055, 0), (1.08, .11, .62), 'black', parent=cabinet)
        for drawer in range(3):
            y = .27+drawer*.37
            s.box(f'Drawer{drawer}', (0, y, -.361), (1.09, .34, .024), 'office_enamel', parent=cabinet)
            s.box(f'Pull{drawer}', (0, y+.06, -.39), (.27, .03, .035), 'metal', parent=cabinet)
            s.box(f'LabelFrame{drawer}', (.32, y-.055, -.378), (.17, .065, .009), 'metal', parent=cabinet)
            s.box(f'Label{drawer}', (.32, y-.055, -.384), (.14, .044, .003), 'paper', parent=cabinet)
        for binder in range(4):
            s.box(f'Binder{binder}', (-.4+binder*.13, 1.37, .03), (.10, .28, .25), 'fabric' if binder%2 else 'plastic', parent=cabinet)
    # Meeting room glass gets an etched privacy stripe, while threats stay visible.
    s.box('ConferencePrivacyWest', (4.999, 2.55, -7), (.008, .18, 7.85), 'frosted_glass', parent=p)
    for idx, (z, length) in enumerate([(-12.625, 6.1), (-4.25, 4.35)]):
        s.box(f'SyncPrivacy{idx}', (18.411, 1.45, z), (.008, .18, length), 'frosted_glass', parent=p)
    for idx, z in enumerate([-10.25, -5.75]):
        # Attached to moving doors, so handles follow the optional meeting trap.
        s.box('Handle', (-.075, 0, 0), (.06, .42, .04), 'metal', parent='QuickSyncDoor'+('A' if idx == 0 else 'B'))
    # Conference call equipment, pads and cups are at the existing table perimeter.
    s.cylinder('ConferenceSpeaker', (8, 2.38, -8), .19, .05, 'plastic', parent=p)
    for idx, x in enumerate([6.9, 9.1]):
        s.box(f'MeetingPad{idx}', (x, 2.368, -7.5), (.30, .015, .24), 'paper', parent=p, rot=(0, 7-idx*14, 0))
        s.cylinder(f'MeetingCup{idx}', (x+.28, 2.44, -7.6), .065, .16, 'ceramic', parent=p)
