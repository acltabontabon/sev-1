"""Operations command station: original geometry plus documented CC0 practical lights.

Keep all incident-controlled labels at the room root. Console collision is baked offline.
"""


def build_operations(s, font):
    # Equipment surround: a black recessed bay, mounted steel rails and one dominant
    # alarm screen. The smaller right display is a clock / incident detail panel.
    s.box('OperationsPanel', (-1.6, 2.45, -15.55), (9.0, 4.5, .32), 'black')
    for idx, x in enumerate([-6.05, 2.85]):
        s.box(f'OpsSteelPillar{idx}', (x, 2.45, -15.32), (.14, 4.5, .15), 'metal')
        s.box(f'OpsPilotStrip{idx}', (x, 3.8, -15.23), (.035, 1.2, .025), 'cool')
    s.box('OpsHeader', (-1.6, 4.60, -15.30), (9.0, .34, .15), 'office_enamel')
    s.text('OperationsTitle', 'PRODUCTION  /  INCIDENT COMMAND', (-1.6, 4.61, -15.20), .0045, 54, (.85, .93, .93, 1), face=font)
    s.box('Dashboard0', (-3.0, 2.90, -15.20), (5.75, 2.62, .20), 'metal')
    s.box('DashboardFace0', (-3.0, 2.90, -15.085), (5.48, 2.36, .018), 'screen')
    s.text('Critical', 'PRODUCTION\nCRITICAL', (-3.0, 3.10, -15.062), .0078, 64, (1, .39, .22, 1), face=font)
    s.text('RootCause', 'ROOT CAUSE: UNKNOWN', (-3.0, 1.99, -15.062), .004, 40, face=font)
    s.box('Dashboard1', (1.35, 2.90, -15.20), (2.45, 2.62, .20), 'metal')
    s.box('DashboardFace1', (1.35, 2.90, -15.085), (2.18, 2.36, .018), 'screen')
    s.text('Clock', 'FRIDAY / 16:59', (1.35, 3.74, -15.062), .0042, 44, (.8, .9, .92, 1), face=font)
    s.text('Impossible', 'CORE: SUCCESS', (1.35, 3.02, -15.062), .0036, 40, (.6, .9, .8, 1), face=font)
    s.text('ETA', 'PAYMENTS: NOT FOUND', (1.35, 2.26, -15.062), .0035, 36, (1, .68, .48, 1), face=font)
    # Original telemetry lines: visual rhythm below the live status, never objectives.
    for chart in range(3):
        for step in range(14):
            h = .04 + ((step * 7 + chart * 3) % 9) * .018
            s.box(f'OpsChart{chart}_{step}', (-5.3+step*.12, 1.47+chart*.055+h*.5, -15.08), (.07, h, .014), 'mint')
    s.box('IncidentStrip', (-1.6, 1.56, -15.05), (8.55, .065, .035), 'alert')
    s.light('IncidentSpill', (-2.0, 2.3, -14.3), (1, .16, .065), 2.3, 5)
    # A solid console gives the wall scale, depth and a believable place to work.
    s.box('OpsConsole', (-1.7, .52, -14.63), (7.9, 1.04, 1.22), 'office_enamel', True)
    s.box('OpsConsoleTop', (-1.7, 1.075, -14.63), (8.12, .09, 1.38), 'black')
    s.box('OpsConsoleFront', (-1.7, .56, -13.998), (7.68, .78, .025), 'plastic')
    for idx, x in enumerate([-4.7, -2.7, -.7, 1.3]):
        s.box(f'OpsConsoleSeam{idx}', (x, .56, -13.97), (.024, .77, .012), 'metal')
        s.box(f'OpsConsoleHandle{idx}', (x+.8, .74, -13.96), (.28, .045, .04), 'metal')
    s.text('Uptime', 'LIVE INCIDENT STATUS', (-1.7, .62, -13.956), .0038, 40, (.55, .8, .85, 1), face=font)
    # Two integrated, angled operator screens; keyboards have visible keycaps.
    for idx, x in enumerate([-4.25, .55]):
        s.box(f'OpsTerminal{idx}', (x, 1.23, -14.67), (1.3, .48, .55), 'plastic', rot=(-18, 0, 0))
        s.box(f'OpsTerminalFace{idx}', (x, 1.31, -14.365), (1.12, .32, .015), 'screen', rot=(-18, 0, 0))
        s.text(f'OpsTerminalLabel{idx}', ['INC-001 LIVE', 'DO NOT REBOOT'][idx], (x, 1.34, -14.33), .0033, 36, (.55, .9, .85, 1), rot=(-18, 0, 0), face=font)
        s.box(f'OpsKeyboard{idx}', (x, 1.145, -14.12), (.8, .04, .24), 'plastic')
        for row in range(3):
            for key in range(12):
                s.box(f'OpsKey{idx}_{row}_{key}', (x-.35+key*.062, 1.171, -14.20+row*.068), (.048, .017, .046), 'office_enamel')
    # A covered emergency stop is a physical focal point, rather than more tiny text.
    s.cylinder('OpsEmergencyButton', (-1.7, 1.16, -14.15), .10, .08, 'alert')
    s.box('OpsButtonGuard', (-1.7, 1.24, -14.18), (.32, .08, .28), 'glass')
    s.text('OpsConsoleJoke', 'IN CASE OF PANIC: PANIC', (-1.7, .23, -13.956), .003, 36, (.65, .7, .72, 1), face=font)
    # Cable trough and rack wall. The existing rack footprints and employee aisle stay.
    s.box('OpsRackBack', (-8.2, 1.7, -15.55), (4.9, 3.4, .16), 'office_enamel')
    s.text('Wayfinding', '01  /  EQUIPMENT', (-8.2, 3.58, -15.43), .004, 44, (.75, .87, .9, 1), face=font)
    s.box('CableTray', (-8.2, 3.2, -14), (4.6, .16, .5), 'black')
    for idx, x in enumerate([-9.8, -8.7, -7.6, -6.5]):
        s.instance(f'Rack{idx}', 'operations_rack', (x, 0, -13.8))
        for cable in range(3):
            s.box(f'OpsLoom{idx}_{cable}', (x-.12+cable*.10, 2.8, -14.18), (.028, .75, .03), 'black')
        s.box(f'OpsCableTie{idx}', (x-.02, 2.9, -14.145), (.3, .025, .028), 'amber')
    # A high amber route sign leads away from the equipment, toward the actual gate.
    s.box('OpsRoutePlate', (4.75, 3.15, -15.59), (2.8, 1.2, .12), 'black')
    s.text('OpsRoute', 'SERVER CORE\n→', (4.75, 3.16, -15.51), .005, 56, (1, .72, .36, 1), face=font)
    for idx, x in enumerate([-4.2, .7]):
        lamp = s.external('res://assets/environment/operations/caged_hanging_light.glb', 'PackedScene')
        s.nodes.append(f'[node name="OpsPendant{idx}" parent="." instance={lamp}]\nposition = Vector3({x}, 5.32, -13.8)\nscale = Vector3(1.7, 1.0, 1.0)')
        s.light(f'OpsTaskPool{idx}', (x, 4.5, -13.8), (.65, .83, .86), 1.35, 4.8, spot=True)
