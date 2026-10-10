extends Node3D
## One episode, owned locally. No asynchronous timers survive a reset.

enum Stage { ALERT, ENCOUNTER_ONE, INVESTIGATION, ENCOUNTER_TWO, BOSS, RESOLVED, FAILED }
const RECORD: PackedScene = preload("res://game/enemies/incident.tscn")
const VARIANCE: Script = preload("res://game/incidents/variance.gd")
const CONSOLE_POSITION: Vector3 = Vector3(-1.7, 0, -12.5)

@export var boss_health: int = 700
const ARCHETYPES: Dictionary = {
	"record": null,
	"blocker": preload("res://game/enemies/blocker.gd"),
	"invite": preload("res://game/enemies/meeting_invite.gd"),
	"scope": preload("res://game/enemies/scope_creep.gd"),
	"bug": preload("res://game/enemies/bug.gd"),
}
## Minion swarms per wave (index matches WAVES): one-hit bugs that rush in beside the wave.
## They never count toward a wave; survivors are closed as WONTFIX when the stage clears.
const SWARMS: Dictionary = {
	Stage.ENCOUNTER_ONE: [3, 4],
	Stage.ENCOUNTER_TWO: [4, 5],
}
const ZONE: Script = preload("res://game/enemies/meeting_zone.gd")
## Authored encounters: each wave is [kind, spawn marker]; waves arrive after a breather.
const WAVES: Dictionary = {
	Stage.ENCOUNTER_ONE: [[["record", "A1"], ["record", "A3"]], [["record", "A2"], ["scope", "A4"]]],
	Stage.ENCOUNTER_TWO: [[["blocker", "D2"], ["record", "D1"], ["record", "D3"]], [["invite", "D2"], ["record", "D4"], ["scope", "D1"]]],
}
## Roaming: each main wave breaks out somewhere on the floor, never on top of the
## engineer. Sites rotate in this order, skipping any closer than ROAM_DISTANCE and the
## one just used; positions are snapped to the navigation mesh at spawn time and must be
## reachable on foot from the main floor (sealed rooms bake their own islands).
const SITES: Array = [
	["the desks", Vector3(-8.0, 0, -2.5)],
	["the pantry", Vector3(22.5, 0, 8.8)],
	["Operations", Vector3(0.0, 0, -12.0)],
	["the east corridor", Vector3(16.2, 0, 5.5)],
	["the conference deck", Vector3(8.0, 1.5, -7.0)],
	["the lounge", Vector3(9.5, 0, 11.0)],
	["the meeting wing", Vector3(16.2, 0, -9.5)],
]
const ROAM_DISTANCE: float = 14.0
## Outbreaks: every wave member starts as an overtime employee planted on the floor ahead
## of time. When the wave is due, a short cutscene watches one of them turn; all of them
## break out OUTBREAK_BURST seconds later. Headless runs skip the turn unless asked.
const HOST: Script = preload("res://game/enemies/employee_host.gd")
const OUTBREAK_BURST: float = 2.4
@export var outbreak_in_headless: bool = false
## Employees planted for the next wave (in wave order) and for the Quick Sync.
var hosts: Array[Node3D] = []
var sync_hosts: Array[Node3D] = []
var pending_hosts: Array = []
var crew_index: Dictionary = {}
var outbreak_left: float = 0.0
var swarm_waiting: Array = []
## A due wave waits inside its employees until the engineer sets one off: talking to
## them, hovering too close for too long, or hitting them. If ignored, they snap anyway.
const ARMED_PATIENCE: float = 45.0
const HOVER_RANGE: float = 2.8
const HOVER_LIMIT: float = 5.0
var armed: bool = false
var armed_left: float = 0.0
var hover: Dictionary = {}
var trigger_reason: String = ""
var hr_cooldown: float = 0.0
## A cleared stage waits for its kill cam, then a beat, before the change request
## appears. Counted in real time, so slow motion never stretches it.
var upgrade_delay: float = 0.0
const UPGRADE_BEAT: float = .6
## The run's end plays out (the boss's kill cam, the engineer's fall) before the report.
var ending_hold: float = 0.0
const ENDING_HOLD: float = 2.0
## Headless suites step frames and expect the report at once, unless a test opts in.
var hold_ending: bool = DisplayServer.get_name() != "headless"
## Kill feedback: corporate death notices, and streaks for kills in quick succession.
const STAMPS: Array[String] = ["CLOSED", "RESOLVED", "WONTFIX", "DEPRECATED", "OFFBOARDED", "SUNSET", "ARCHIVED", "MERGED", "ROLLED BACK", "RIGHT-SIZED"]
const BUG_STAMPS: Array[String] = ["FIXED", "SQUASHED", "PATCHED", "NOT A BUG"]
const STREAK_WINDOW: float = 2.2
var kill_streak: int = 0
var last_kill_at: float = -99.0
var closing_bugs: bool = false
## Talking to the night shift: RPG-style dialogue while nothing is hunting the engineer.
const DIALOGUES: Script = preload("res://game/incidents/dialogues.gd")
const TALK_RANGE: float = 2.4
var dialogue: CanvasLayer
var talk_prompt: CanvasLayer
var talking: Node3D
var talked: Dictionary = {}
var talk_with: Dictionary = {}
var talk_line: int = 0
## The optional meeting: an invite holds the room while two records press in.
const QUICK_SYNC: Array = [["invite", "B1"], ["record", "B3"], ["record", "B4"]]
@export_range(0, 6) var max_telegraphs: int = 2
@export_range(0, 6) var wave_breather: float = 2.8
const RUN: Script = preload("res://game/incidents/run_progression.gd")
const UPGRADE_UI: Script = preload("res://game/ui/upgrade_selection.gd")
const INTERACTION: Script = preload("res://game/incidents/interaction_point.gd")
## Crossing into the server vault starts The Variance's arrival.
const VAULT_LINE: float = -30.5
@export_range(5, 120) var coffee_seconds: float = 40.0
@export_range(0, .5) var coffee_bonus: float = .15
var boss_triggered: bool = false
var boss_time: float = 0.0
var coffee_left: float = 0.0
var coffee_cups: int = 0
var interactions: Dictionary = {}
var voice: Node
var presentation: CanvasLayer
var battle_mode: CanvasLayer
var coworkers: Node3D
var enemies_defeated: int = 0
var boss_encountered: bool = false
var run: Node
var upgrade_ui: CanvasLayer
@export_range(1, 600) var commitment_seconds: float = 300.0
var decision_pending: bool = false
var corporate_choice: int = -1
var challenge_left: float = 0.0
var challenge_result: String = "Not requested"
var upgrade_pending: bool = false
var upgrade_next: Stage = Stage.INVESTIGATION
var stage: Stage = Stage.ALERT
var elapsed: float = 0.0
var stage_time: float = 0.0
var alert_played: bool = false
var spawn_delay: float = 0.0
var remaining: int = 0
var mistakes: int = 0
var inspected: bool = false
var objective: String = ""
var message: String = ""
var report: String = ""
## Compatibility view for the single-foe era: the boss, else the first live enemy.
var active_enemy: CharacterBody3D:
	get:
		if is_instance_valid(boss) and boss.health > 0:
			return boss
		for actor: CharacterBody3D in alive + sync_alive:
			if is_instance_valid(actor) and actor.health > 0:
				return actor
		return null
var alive: Array[CharacterBody3D] = []
var sync_alive: Array[CharacterBody3D] = []
var boss: CharacterBody3D
var pending: Array = []
var pop_left: float = 0.0
var wave_index: int = 0
var zones: Array[Node3D] = []
var corpses: Dictionary = {}
var bugs: Array[CharacterBody3D] = []
var site_cursor: int = 0
var wave_area: String = ""
var wave_site: Vector3 = Vector3.ZERO
var last_area: String = ""
var beacon: Node3D
var bugs_fixed: int = 0
var seen_kinds: Dictionary = {}
## Postmortem timeline: [elapsed seconds, event], recorded as the run happens.
var timeline: Array = []
var quick_sync: String = "idle"
var actors: Array[Node3D] = []
var copies: Array[Node3D] = []
var console_marker: Label3D
var light_target: float = 0.6
@onready var main: Node3D = get_parent()
@onready var player: CharacterBody3D = main.get_node("Player")
@onready var room: Node3D = main.get_node("OfficeAfterHours")


func _ready() -> void:
	main.get_node("Enemy").hide()
	main.get_node("Enemy").process_mode = Node.PROCESS_MODE_DISABLED
	main.get_node("Enemy").collision_layer = 0
	main.get_node("Enemy").remove_from_group("enemies")
	console_marker = Label3D.new()
	console_marker.position = CONSOLE_POSITION + Vector3.UP * 2.5
	console_marker.font_size = 48
	console_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	console_marker.modulate = Color(.5, .95, 1)
	add_child(console_marker)
	run = RUN.new()
	run.name = "RunProgression"
	add_child(run)
	upgrade_ui = UPGRADE_UI.new()
	add_child(upgrade_ui)
	upgrade_ui.selected.connect(_choose_modal)
	player.damage_accepted.connect(_on_damage_accepted)
	voice = preload("res://game/incidents/voice_controller.gd").new()
	voice.name = "Voice"
	add_child(voice)
	presentation = preload("res://game/incidents/incident_presentation.gd").new()
	add_child(presentation)
	battle_mode = preload("res://game/incidents/battle_mode.gd").new()
	battle_mode.name = "BattleMode"
	add_child(battle_mode)
	_make_beacon()
	if DisplayServer.get_name() != "headless":
		Blood.prewarm()
	dialogue = preload("res://game/ui/dialogue_box.gd").new()
	dialogue.name = "Dialogue"
	add_child(dialogue)
	dialogue.finished.connect(_end_talk)
	talk_prompt = preload("res://game/ui/talk_prompt.gd").new()
	talk_prompt.name = "TalkPrompt"
	add_child(talk_prompt)
	coworkers = preload("res://game/incidents/coworkers.gd").new()
	coworkers.name = "Coworkers"
	coworkers.incident = self
	# The incident runs always (menus, voice); the night shift stops when play does.
	coworkers.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(coworkers)
	# Pantry objects: honest reactions, one of them useful.
	for entry: Array in [["coffee", "CoffeeMachine", "E — COFFEE"], ["vending", "VendingMachine", "E — SNACK"], ["microwave", "Microwave", "E — MICROWAVE"], ["poster", "WellnessPoster", "E — READ"]]:
		var point: Node3D = INTERACTION.new()
		point.name = "Use_" + entry[0]
		point.prompt = entry[2]
		point.position = room.get_node("SpawnPoints/" + entry[1]).position
		add_child(point)
		interactions[entry[0]] = point
	reset_incident()


func reset_incident() -> void:
	if dialogue.is_open():
		# Restarting mid-conversation must not set the wave off on the way out.
		armed = false
		dialogue.close()
	talked.clear()
	_cleanup()
	decision_pending = false
	corporate_choice = -1
	challenge_left = 0
	challenge_result = "Not requested"
	upgrade_pending = false
	upgrade_ui.close()
	run.reset_run()
	run.apply_to(player)
	stage = Stage.ALERT
	alert_played = false
	boss_triggered = false
	boss_time = 0
	coffee_left = 0
	coffee_cups = 0
	player.move_multiplier = 1.0
	player.zone_multiplier = 1.0
	quick_sync = "idle"
	timeline.clear()
	noticed_stage = -1
	seen_kinds.clear()
	wave_index = 0
	_reset_doors()
	$AlertSound.stop()
	enemies_defeated = 0
	bugs_fixed = 0
	site_cursor = 0
	last_area = ""
	boss_encountered = false
	elapsed = 0
	stage_time = 0
	spawn_delay = 0
	remaining = 0
	mistakes = 0
	inspected = false
	report = ""
	objective = "Friday, 4:59 PM. Head into the office."
	message = "Your shift is over. Almost.   •   TAB skips the opening."
	console_marker.text = ""
	light_target = .6
	room.get_node("IncidentSpill").light_energy = .6
	_dashboard("PRODUCTION\nHEALTHY", "ALL SYSTEMS OPERATIONAL")
	room.get_node("Impossible").text = "TRANSACTIONS: CONSISTENT"
	room.get_node("ETA").text = "Happy Friday, team!\nEnjoy your well-deserved weekend!"
	room.get_node("Clock").text = "FRIDAY / 16:59"
	presentation.reset_story()
	battle_mode.reset()
	coworkers.reset()


func _reset_doors() -> void:
	var gate: StaticBody3D = room.get_node("VaultGate")
	gate.position.y = 2.0
	gate.collision_layer = 1
	for entry: Array in [["QuickSyncDoorA", -10.25], ["QuickSyncDoorB", -5.75]]:
		var door: StaticBody3D = room.get_node(entry[0])
		door.position.z = entry[1]
		door.collision_layer = 0


func terminal() -> bool:
	return stage == Stage.RESOLVED or stage == Stage.FAILED


func _cleanup() -> void:
	alive.clear()
	sync_alive.clear()
	boss = null
	pending.clear()
	zones.clear()
	corpses.clear()
	bugs.clear()
	hosts.clear()
	sync_hosts.clear()
	pending_hosts.clear()
	crew_index.clear()
	swarm_waiting.clear()
	outbreak_left = 0.0
	armed = false
	hover.clear()
	trigger_reason = ""
	upgrade_delay = 0.0
	ending_hold = 0.0
	kill_streak = 0
	last_kill_at = -99.0
	wave_area = ""
	if beacon != null:
		beacon.hide()
	for actor in actors:
		if is_instance_valid(actor):
			actor.process_mode = Node.PROCESS_MODE_DISABLED
			if actor is CollisionObject3D:
				actor.collision_layer = 0
			actor.remove_from_group("enemies")
			actor.hide()
			actor.queue_free()
	actors.clear()
	copies.clear()
	Blood.clear(get_tree())


func _enter(next: Stage) -> void:
	if terminal() or (modal_pending() and next != Stage.FAILED):
		return
	var valid: bool = next == Stage.FAILED or int(next) == int(stage) + 1
	if not valid:
		return
	stage = next
	stage_time = 0
	log_event(["", "Incident declared; first records arrive", "Discrepancy confirmed; investigation opened", "Containment started", "Escalated to: you (production core opened)", "Resolved", "Reopened: engineer offline"][stage])
	spawn_delay = 2.0
	match stage:
		Stage.ENCOUNTER_ONE:
			wave_index = 0
			remaining = stage_total()
			objective = "1/3 · The Discrepancy"
			_plant(0)
			message = "The night shift is not okay.  •  Hit first: double damage."
			light_target = 2.3
		Stage.INVESTIGATION:
			objective = "Investigate at OPERATIONS"
			message = "DISCREPANCY CONFIRMED  •  The pantry still has coffee."
			console_marker.text = "↓ OPERATIONS\nE — INSPECT"
			_plant_sync()
			_dashboard("RECONCILIATION\nFAILED", "INVESTIGATION REQUIRED")
		Stage.ENCOUNTER_TWO:
			wave_index = 0
			remaining = stage_total()
			objective = "2/3 · Contain the delivery"
			# A meeting nobody attended adjourns; its attendees go home instead of
			# twitching through containment like a due wave.
			for host: Node3D in sync_hosts:
				if is_instance_valid(host):
					host.queue_free()
			sync_hosts.clear()
			_plant(0)
			message = "Payment Processing lost the record.  •  These ones are faster."
			console_marker.text = ""
			light_target = 3.2
			_dashboard("DELIVERY\nFAILED", "MISSING: PAYMENT RECORD")
		Stage.BOSS:
			# The gate lifts now; the arrival waits for the engineer to walk into the vault.
			room.get_node("VaultGate").collision_layer = 0
			spawn_delay = 9999.0
			boss_triggered = false
			objective = "3/3 · The Variance"
			message = "The original carries a solid ◆. Copies are hollow ◇."
			_dashboard("FALSE\nPOSITIVES", "VERIFY BEFORE RESOLVING")
		Stage.RESOLVED, Stage.FAILED:
			_finish()
	presentation.stage_changed()


func _process(delta: float) -> void:
	var spill: OmniLight3D = room.get_node("IncidentSpill")
	spill.light_energy = move_toward(spill.light_energy, light_target + (0.0 if terminal() else run.band() * .35), delta * 1.2)
	var real_delta: float = delta / maxf(Engine.time_scale, .01)
	if terminal() and ending_hold > 0 and not get_tree().paused:
		player.narrative_hold = true
		if presentation.beat_shot != "killcam":
			ending_hold = maxf(0.0, ending_hold - real_delta)
			if ending_hold == 0:
				player.camera_rig.set_capture(false)
	if terminal() or get_tree().paused:
		return
	for point: Node3D in interactions.values():
		point.refresh(player, not modal_pending() and stage != Stage.ALERT)
	_refresh_talk_prompt()
	if stage == Stage.ENCOUNTER_TWO and challenge_result == "Active":
		challenge_left = maxf(0, challenge_left - delta)
		if challenge_left == 0:
			challenge_result = "Expired — no penalty"
	elapsed += delta
	stage_time += delta
	if stage == Stage.ALERT and stage_time >= presentation.opening_duration():
		_enter(Stage.ENCOUNTER_ONE)
	if stage == Stage.BOSS and not boss_triggered and player.global_position.z < VAULT_LINE:
		trigger_boss()
	if boss_triggered:
		boss_time += delta
	if coffee_left > 0:
		coffee_left = maxf(0, coffee_left - delta)
		if coffee_left == 0:
			run.motivation = 0
			player.move_multiplier = 1.0
			run.apply_to(player)
			message = "Motivation expired. Productivity returns to baseline."
	if upgrade_delay > 0 and presentation.beat_shot != "killcam":
		upgrade_delay = maxf(0.0, upgrade_delay - real_delta)
		if upgrade_delay == 0:
			_offer_upgrade(upgrade_next)
	if outbreak_left > 0:
		outbreak_left = maxf(0.0, outbreak_left - delta)
		if outbreak_left == 0:
			end_outbreak()
	if stage in [Stage.ENCOUNTER_ONE, Stage.ENCOUNTER_TWO] and not modal_pending():
		if not pending.is_empty():
			pop_left -= delta
			if pop_left <= 0:
				_spawn_entry(pending.pop_front(), alive, pending_hosts.pop_front() if not pending_hosts.is_empty() else null)
				pop_left = .4
		elif alive.is_empty() and wave_index < waves().size():
			spawn_delay -= delta
			if spawn_delay <= 0:
				if outbreaks() and not hosts.is_empty():
					_watch_hosts(delta)
				else:
					_spawn()
	elif stage == Stage.BOSS and not is_instance_valid(boss):
		spawn_delay -= delta
		if spawn_delay <= 0:
			_spawn()
	_update_beacon()
	_assign_slots(delta)
	_complain_to_hr(delta)
	if quick_sync == "idle" and stage == Stage.INVESTIGATION and not modal_pending() and in_quick_sync():
		_start_quick_sync()
	var attending: bool = false
	for zone: Node3D in zones:
		attending = attending or zone.contains(player)
	player.zone_multiplier = .5 if attending else 1.0
	for actor: Node3D in corpses.keys():
		corpses[actor] -= delta
		if corpses[actor] <= 0:
			corpses.erase(actor)
			actors.erase(actor)
			if is_instance_valid(actor):
				actor.queue_free()


func log_event(text: String) -> void:
	if not text.is_empty():
		timeline.append([elapsed, text])


func trigger_boss() -> void:
	if stage != Stage.BOSS or boss_triggered:
		return
	log_event("Entered the vault; The Variance manifested")
	boss_triggered = true
	boss_time = 0
	presentation.vault_entered()
	spawn_delay = presentation.boss_length


func arrival_site() -> Vector3:
	if stage == Stage.BOSS:
		return room.get_node("SpawnPoints/VaultArrival").position
	# Authored clear floor per area; choose the farthest so arrivals never hit immediately.
	var prefix: String = "Spawn_D" if stage == Stage.ENCOUNTER_TWO else "Spawn_A"
	var sites: Array[Vector3] = []
	for marker: Node3D in room.get_node("SpawnPoints").get_children():
		if marker.name.begins_with(prefix):
			sites.append(marker.position)
	var site: Vector3 = sites[0]
	for candidate in sites:
		if candidate.distance_to(player.position) > site.distance_to(player.position):
			site = candidate
	return site


func waves() -> Array:
	if not WAVES.has(stage):
		return []
	var list: Array = WAVES[stage].duplicate(true)
	# Escalating the dependency returns it: a Blocker joins the final containment wave.
	if stage == Stage.ENCOUNTER_TWO and corporate_choice == 2:
		list[list.size() - 1].append(["blocker", "D3", "dependency"])
	return list


func stage_total() -> int:
	var total: int = 0
	for wave: Array in waves():
		total += wave.size()
	return total


## Queue the next wave (popping its first member now), or manifest the boss.
func _spawn() -> void:
	if modal_pending() or terminal() or stage not in [Stage.ENCOUNTER_ONE, Stage.ENCOUNTER_TWO, Stage.BOSS]:
		return
	if stage == Stage.BOSS:
		if is_instance_valid(boss):
			return
		var actor: CharacterBody3D = RECORD.instantiate()
		actor.set_script(VARIANCE)
		actor.max_health = boss_health
		actor.process_mode = Node.PROCESS_MODE_PAUSABLE
		actor.position = arrival_site()
		actor.detection_distance = 50
		actor.move_speed *= run.pressure()
		add_child(actor)
		actors.append(actor)
		boss = actor
		boss_encountered = true
		actor.died.connect(_on_record_died.bind(actor), CONNECT_ONE_SHOT)
		actor.false_positives.connect(_make_copies, CONNECT_ONE_SHOT)
		actor.show_impact(Color(.4, 1, 1))
		return
	var opening: bool = pending.is_empty()
	if opening:
		if wave_index >= waves().size():
			return
		pending = waves()[wave_index].duplicate(true)
		pending_hosts = hosts.duplicate()
		hosts.clear()
		_match_hosts()
		var patient: Node3D = pending_hosts[0] if not pending_hosts.is_empty() and is_instance_valid(pending_hosts[0]) else null
		if patient != null:
			wave_area = patient.get_meta("area", "")
			wave_site = patient.position
			last_area = wave_area
		else:
			_choose_site()
		log_event("Wave %d breaks out across the floor" % (wave_index + 1))
		if outbreaks():
			outbreak_left = OUTBREAK_BURST
			swarm_waiting = [wave_index, pending[0][1]]
		else:
			_release_swarm(wave_index, pending[0][1])
		wave_index += 1
		# The next wave's employees take their places now, far from the engineer.
		if wave_index < waves().size():
			_plant(wave_index)
	var first: CharacterBody3D = _spawn_entry(pending.pop_front(), alive, pending_hosts.pop_front() if not pending_hosts.is_empty() else null)
	pop_left = .4
	if opening and outbreaks() and trigger_reason != "hit":
		presentation.outbreak(first, wave_area, trigger_reason)
		trigger_reason = ""


func _release_swarm(index: int, site: String) -> void:
	var sizes: Array = SWARMS.get(stage, [])
	if index >= sizes.size():
		return
	var origin: Vector3 = wave_site if wave_area != "" else spawn_site(site)
	for count in range(sizes[index]):
		var bug: CharacterBody3D = RECORD.instantiate()
		bug.set_script(ARCHETYPES["bug"])
		bug.starts_aware = false
		bug.process_mode = Node.PROCESS_MODE_PAUSABLE
		bug.position = _near_site(origin - wave_site + Vector3(cos(count * 2.1), 0, sin(count * 2.1)) * 2.2) if wave_area != "" else origin + Vector3(cos(count * 2.1), 0, sin(count * 2.1)) * 1.4
		bug.detection_distance = 50
		add_child(bug)
		bug.move_speed = (3.4 if stage == Stage.ENCOUNTER_TWO else 2.4) * bug.speed_scale * run.pressure()
		actors.append(bug)
		bugs.append(bug)
		bug.died.connect(_on_bug_died.bind(bug), CONNECT_ONE_SHOT)
	if not seen_kinds.has("bug"):
		seen_kinds["bug"] = true
		presentation.introduce("bug", bugs.back())


func _on_bug_died(bug: CharacterBody3D) -> void:
	bugs.erase(bug)
	bugs_fixed += 1
	corpses[bug] = 1.4
	if not closing_bugs:
		_kill_feedback(bug, true)


## Every kill lands: a stamp, an impact, a punch, a little FOCUS, and a streak banner for
## kills in quick succession. The finisher kill cam replaces the freeze-frame.
func _kill_feedback(actor: CharacterBody3D, minor: bool) -> void:
	kill_streak = kill_streak + 1 if elapsed - last_kill_at < STREAK_WINDOW else 1
	last_kill_at = elapsed
	var stamp: String = (BUG_STAMPS if minor else STAMPS)[randi() % (BUG_STAMPS if minor else STAMPS).size()]
	player.specials.add_focus((2.0 if minor else 6.0) + 3.0 * (kill_streak - 1))
	if presentation.beat_shot != "killcam":
		ElementFx.freeze(self, .035 if minor else .07, .05)
	player.camera_rig.add_impulse(.35 if minor else .9)
	presentation.kill_pop(actor, stamp, minor, kill_streak)


## The stage is clear: whatever bugs are left get triaged the usual way.
func _close_bugs() -> void:
	var open: Array[CharacterBody3D] = bugs.duplicate()
	closing_bugs = true
	for bug: CharacterBody3D in open:
		if is_instance_valid(bug) and bug.health > 0:
			ElementFx.glyphs(bug, bug.global_position + Vector3.UP * 1.1, Color(.7, .75, .8), ["WONTFIX"], .9, 0.0)
			bug.receive_damage(bug.health, bug.global_position)
	closing_bugs = false
	if not open.is_empty():
		log_event("%d bug%s closed as WONTFIX" % [open.size(), "" if open.size() == 1 else "s"])


## True when waves break out of employees with a cutscene (always in a rendered game).
func outbreaks() -> bool:
	return DisplayServer.get_name() != "headless" or outbreak_in_headless


## Place the employees a wave will break out of, each at its own outbreak site.
func _plant(index: int) -> void:
	for host in hosts:
		if is_instance_valid(host):
			actors.erase(host)
			host.queue_free()
	hosts.clear()
	var list: Array = waves()
	if index >= list.size():
		return
	var area: String = wave_area
	var site: Vector3 = wave_site
	for entry: Array in list[index]:
		_choose_site()
		var host: Node3D = _make_host(entry[0], wave_site if wave_area != "" else spawn_site(entry[1]))
		host.set_meta("area", wave_area)
		hosts.append(host)
	# Planting looks ahead; the wave in progress keeps its own site for its swarm.
	wave_area = area
	wave_site = site


## The Quick Sync is already in session: three attendees standing round the table.
func _plant_sync() -> void:
	if quick_sync != "idle" or not sync_hosts.is_empty():
		return
	var center: Vector3 = room.get_node("SpawnPoints/Spawn_B1").position
	for entry: Array in QUICK_SYNC:
		var host: Node3D = _make_host(entry[0], spawn_site(entry[1]))
		host.set_meta("area", "Meeting Room 3")
		var away: Vector3 = center - host.position
		if away.length() > .5:
			host.rotation.y = atan2(-away.x, -away.z)
		sync_hosts.append(host)


func _make_host(kind: String, at: Vector3) -> Node3D:
	var host: Node3D = HOST.create(kind, crew_index.get(kind, 0))
	crew_index[kind] = crew_index.get(kind, 0) + 1
	host.position = at
	host.rotation.y = randf() * TAU
	host.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(host)
	actors.append(host)
	return host


## The wave is due: its employees act strange and wait for the engineer to set one off.
func _watch_hosts(delta: float) -> void:
	if not armed:
		armed = true
		armed_left = ARMED_PATIENCE
		hover.clear()
		message = "Something is off with the night shift."
	armed_left -= delta
	var closest: Node3D = null
	for host: Node3D in hosts:
		if not is_instance_valid(host):
			continue
		if closest == null or _flat(host.global_position) < _flat(closest.global_position):
			closest = host
		# Hovering: a polite question, then a much less polite answer.
		var near: bool = _flat(host.global_position) < HOVER_RANGE
		hover[host] = (hover.get(host, 0.0) + delta) if near else maxf(0.0, hover.get(host, 0.0) - delta)
		host.dread = .35 * clampf(hover[host] / HOVER_LIMIT, 0, 1)
		if near and hover[host] > HOVER_LIMIT * .25 and not host.get_meta("asked", false):
			host.set_meta("asked", true)
			host.say("hover")
		if hover[host] >= HOVER_LIMIT:
			_break_out(host, "hover")
			return
		if _swung_at(host):
			_break_out(host, "hit")
			return
	if armed_left <= 0 and closest != null:
		_break_out(closest, "timeout")


## True while the engineer's live swing would land on this spot.
func _swung_at(host: Node3D) -> bool:
	if not player.melee.is_active():
		return false
	var offset: Vector3 = host.global_position - player.global_position
	offset.y = 0
	var facing: Vector3 = -player.visual.global_basis.z
	return offset.length() < player.melee.reach + .3 and Vector2(facing.x, facing.z).normalized().dot(Vector2(offset.x, offset.z).normalized()) > .2


## Set off: this employee is the one the cutscene watches; the rest of the wave turns too.
## Each employee turns into the monster they were planted as, whoever set the wave off.
func _match_hosts() -> void:
	var rest: Array = pending.duplicate()
	var ordered: Array = []
	for host: Node3D in pending_hosts:
		var found: int = -1
		if is_instance_valid(host):
			for index in range(rest.size()):
				if rest[index][0] == host.kind:
					found = index
					break
		ordered.append(rest.pop_at(found) if found >= 0 else null)
	for index in range(ordered.size()):
		if ordered[index] == null and not rest.is_empty():
			ordered[index] = rest.pop_front()
	pending = ordered.filter(func(entry: Variant) -> bool: return entry != null) + rest


func _break_out(host: Node3D, reason: String) -> void:
	if not hosts.has(host):
		return
	armed = false
	trigger_reason = reason
	hosts.erase(host)
	hosts.push_front(host)
	log_event("%s set off the wave (%s)" % [str(host.identity.get("name", "Someone")).capitalize(), reason])
	_spawn()
	if reason == "hit" and not alive.is_empty():
		# No cutscene for a swing: the whole wave turns on the spot, and the blow lands as
		# the surprise review.
		end_outbreak()
		alive[0].receive_damage(player.melee.effective_damage(), player.global_position)


## Swinging at an employee who is not part of the due wave: paperwork, not violence.
func _complain_to_hr(delta: float) -> void:
	hr_cooldown = maxf(0.0, hr_cooldown - delta)
	if hr_cooldown > 0 or not player.melee.is_active():
		return
	for host: Node3D in hosts + sync_hosts:
		if is_instance_valid(host) and (not armed or sync_hosts.has(host)) and _swung_at(host):
			hr_cooldown = 1.5
			ElementFx.glyphs(self, host.global_position + Vector3.UP * 2.0, Color(1, .8, .4), ["HR HAS BEEN NOTIFIED"], 1.2, 0.0)
			host.say("hr")
			return


## The turn completes: every employee still wearing an incident breaks out, and the
## wave's bugs pour out of the first one.
func end_outbreak() -> void:
	outbreak_left = 0.0
	for actor: CharacterBody3D in alive + sync_alive:
		if is_instance_valid(actor) and actor.disguised():
			actor.reveal()
	if not swarm_waiting.is_empty():
		_release_swarm(swarm_waiting[0], swarm_waiting[1])
		swarm_waiting.clear()


## Pick where the next wave breaks out: the next site in rotation that is far enough
## from the engineer and not the one just used.
func _choose_site() -> void:
	for step in range(SITES.size()):
		var entry: Array = SITES[(site_cursor + step) % SITES.size()]
		var point: Vector3 = _on_floor(entry[1])
		if entry[0] != last_area and reachable(point) and Vector2(point.x - player.global_position.x, point.z - player.global_position.z).length() >= ROAM_DISTANCE:
			site_cursor = (site_cursor + step + 1) % SITES.size()
			wave_area = entry[0]
			wave_site = point
			last_area = wave_area
			return
	wave_area = ""


## Where an unaware enemy strolls next: somewhere near another outbreak site, so patrols
## cross the whole floor instead of loitering where they arrived.
func patrol_point(from: Vector3) -> Vector3:
	for attempt in range(6):
		var entry: Array = SITES[randi() % SITES.size()]
		var point: Vector3 = _on_floor(entry[1] + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)))
		if point.distance_to(from) > 5.0 and reachable(point):
			return point
	return from


## Spread a spawn around the outbreak, never onto a patch the engineer cannot walk to.
func _near_site(offset: Vector3) -> Vector3:
	var point: Vector3 = _on_floor(wave_site + offset)
	return point if reachable(point) else wave_site


## True when a walking path from the main floor ends where the point is.
func reachable(point: Vector3) -> bool:
	var map: RID = get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return true
	var hub: Vector3 = NavigationServer3D.map_get_closest_point(map, Vector3(0, .05, 4))
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map, hub, point, true)
	return not path.is_empty() and path[path.size() - 1].distance_to(point) < .6


func _on_floor(point: Vector3) -> Vector3:
	var map: RID = get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return point
	return NavigationServer3D.map_get_closest_point(map, point) + Vector3.UP * .05


## What the engineer should do right now, for the HUD compass and the waypoint marker:
## {text, point (INF when there is nowhere to go), tag (marker word, empty for none)}.
func next_step() -> Dictionary:
	var none: Vector3 = Vector3.INF
	if terminal() or stage == Stage.ALERT or modal_pending():
		return {}
	match stage:
		Stage.ENCOUNTER_ONE, Stage.ENCOUNTER_TWO:
			var near: CharacterBody3D = nearest_threat()
			if near != null:
				return {"text": "Hunt them. Hit before they see you.", "point": near.global_position, "tag": "THREAT"}
			if not alive.is_empty() or not pending.is_empty():
				return {"text": "Dodge the orange arcs, strike after.", "point": none, "tag": ""}
			if armed and _strangest() != null:
				return {"text": "Talk to the strange coworker, or hit first.", "point": _strangest().global_position, "tag": "???"}
			if wave_index >= waves().size():
				return {"text": "Area clear.", "point": none, "tag": ""}
			return {"text": "Catch your breath.", "point": none, "tag": ""}
		Stage.INVESTIGATION:
			if quick_sync == "active":
				return {"text": "Survive the Quick Sync.", "point": none, "tag": ""}
			return {"text": "Inspect the Operations console (E).", "point": CONSOLE_POSITION, "tag": "CONSOLE"}
		Stage.BOSS:
			if not boss_triggered:
				return {"text": "North, through the corridor, to the vault.", "point": room.get_node("SpawnPoints/VaultEntry").global_position, "tag": "VAULT"}
			if is_instance_valid(boss) and boss.health > 0:
				return {"text": "Strike The Variance only while OPEN.", "point": none, "tag": ""}
	return {}


## A marker over the next step: the nearest unaware threat, the console or the vault.
func _show_beacon() -> void:
	beacon.global_position = wave_site
	beacon.show()


func _make_beacon() -> void:
	if beacon == null:
		beacon = Node3D.new()
		beacon.name = "IncidentBeacon"
		add_child(beacon)
		var column: MeshInstance3D = MeshInstance3D.new()
		var tube: CylinderMesh = CylinderMesh.new()
		tube.top_radius = .05
		tube.bottom_radius = .9
		tube.height = 7.0
		tube.cap_top = false
		tube.cap_bottom = false
		var glow: StandardMaterial3D = StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		glow.cull_mode = BaseMaterial3D.CULL_DISABLED
		glow.albedo_color = Color(1, .3, .15, .22)
		tube.material = glow
		column.mesh = tube
		column.position.y = 3.5
		column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beacon.add_child(column)
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = Color(1, .35, .2)
		light.light_energy = 1.6
		light.omni_range = 6.0
		light.position.y = 1.5
		beacon.add_child(light)
		# Seen through walls at a constant size: the way to the outbreak from anywhere.
		var marker: Label3D = Label3D.new()
		marker.name = "Marker"
		marker.font = preload("res://assets/fonts/barlow_condensed_bold.ttf")
		marker.font_size = 40
		marker.fixed_size = true
		marker.pixel_size = .0011
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.no_depth_test = true
		marker.modulate = Color(1, .45, .25)
		marker.outline_size = 10
		marker.position.y = 3.4
		beacon.add_child(marker)
	beacon.hide()


func _update_beacon() -> void:
	if beacon == null:
		return
	var step: Dictionary = next_step()
	# Cutscenes and kill cams play clean: no waypoint floating through the shot.
	if step.is_empty() or step.tag == "" or not (step.point as Vector3).is_finite() or not presentation.beat_shot.is_empty():
		beacon.hide()
		return
	var point: Vector3 = step.point
	var distance: int = roundi(Vector2(point.x - player.global_position.x, point.z - player.global_position.z).length())
	if distance < 3:
		beacon.hide()
		return
	beacon.global_position = point
	beacon.show()
	(beacon.get_node("Marker") as Label3D).text = "▼\n%s · %d m" % [step.tag, distance]


var slot_clock: float = 0.0


## Squad: engaged enemies share out positions around the engineer, sides and back
## first, so a wave surrounds instead of queueing in front. Re-planned a few times a second.
func _assign_slots(delta: float) -> void:
	slot_clock -= delta
	if slot_clock > 0:
		return
	slot_clock = .3
	var squad: Array[CharacterBody3D] = []
	for actor: CharacterBody3D in alive + sync_alive + bugs:
		if is_instance_valid(actor) and actor.health > 0 and actor.awareness == actor.Awareness.ENGAGED:
			squad.append(actor)
	if squad.is_empty():
		return
	var facing: Vector3 = -player.visual.global_basis.z
	var behind: float = atan2(-facing.x, -facing.z)
	var free: Array[float] = []
	for index in range(squad.size()):
		# Spread around the engineer starting behind them, alternating left and right.
		var step: float = TAU / maxf(squad.size(), 3)
		free.append(behind + (ceili(index / 2.0) * step) * (1 if index % 2 == 0 else -1))
	for actor: CharacterBody3D in squad:
		var here: float = atan2(actor.global_position.x - player.global_position.x, actor.global_position.z - player.global_position.z)
		var best: int = 0
		for index in range(free.size()):
			if absf(angle_difference(here, free[index])) < absf(angle_difference(here, free[best])):
				best = index
		var angle: float = free[best]
		free.remove_at(best)
		var radius: float = 2.6 if actor.attack_style != "nip" else 1.8
		actor.slot = _on_floor(player.global_position + Vector3(sin(angle), 0, cos(angle)) * radius)


## The closest living wave member that is not already chasing the engineer.
func nearest_threat() -> CharacterBody3D:
	var best: CharacterBody3D = null
	var best_distance: float = INF
	for actor: CharacterBody3D in alive:
		if not is_instance_valid(actor) or actor.health <= 0 or actor.awareness == actor.Awareness.ENGAGED or actor.disguised():
			continue
		var distance: float = actor.global_position.distance_to(player.global_position)
		if distance < best_distance:
			best = actor
			best_distance = distance
	return best


func spawn_site(name: String) -> Vector3:
	var site: Vector3 = room.get_node("SpawnPoints/Spawn_" + name).position
	# Never materialize on top of the engineer; fall back to the farthest clear site.
	return arrival_site() if site.distance_to(player.position) < 4.0 and stage != Stage.INVESTIGATION else site


func _spawn_entry(entry: Array, group: Array[CharacterBody3D], host: Node3D = null) -> CharacterBody3D:
	var kind: String = entry[0]
	var actor: CharacterBody3D = RECORD.instantiate()
	if ARCHETYPES[kind] != null:
		actor.set_script(ARCHETYPES[kind])
	# Waves arrive unaware and must find the engineer; the Quick Sync is an ambush.
	actor.starts_aware = is_same(group, sync_alive)
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	if not is_instance_valid(host):
		host = null
	if host != null:
		actor.position = _on_floor(host.position) if reachable(_on_floor(host.position)) else host.position
	elif is_same(group, alive) and wave_area != "":
		# Each member breaks out at its own site away from the engineer, then patrols.
		_choose_site()
		var slot: float = (alive.size() + bugs.size()) * 2.4
		actor.position = _near_site(Vector3(cos(slot), 0, sin(slot)) * 1.2)
	else:
		actor.position = spawn_site(entry[1])
	actor.detection_distance = 50
	if outbreaks():
		if host == null:
			host = _make_host(kind, actor.position)
		actors.erase(host)
		actor.disguise(host, maxf(outbreak_left, .05))
	elif host != null:
		actors.erase(host)
		host.queue_free()
		host = null
	add_child(actor)
	if host != null:
		host.reparent(actor)
		host.position = Vector3.ZERO
		# Bodies face +Z, enemies face -Z: the monster looks where the employee looked.
		actor.visual.rotation.y = host.rotation.y + PI
	actor.move_speed = (3.4 if stage == Stage.ENCOUNTER_TWO else 2.4) * actor.speed_scale * run.pressure()
	actors.append(actor)
	group.append(actor)
	actor.died.connect(_on_record_died.bind(actor), CONNECT_ONE_SHOT)
	if actor.has_signal("grew"):
		actor.grew.connect(_on_scope_grew)
	if actor.has_signal("zone_requested"):
		actor.zone_requested.connect(_book_meeting)
	if actor.has_signal("shield_cast"):
		actor.shield_cast.connect(_on_shield_cast)
	if entry.size() > 2:
		var tag: Label3D = Label3D.new()
		tag.name = "RecordMarker"
		tag.text = "DEPENDENCY RETURNED\nOWNERSHIP: STILL YOU"
		tag.position.y = 3.3
		tag.font_size = 30
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		actor.add_child(tag)
	if actor.disguised():
		actor.revealed.connect(_announce.bind(kind, actor), CONNECT_ONE_SHOT)
	else:
		_announce(kind, actor)
	return actor


func _announce(kind: String, actor: CharacterBody3D) -> void:
	if not is_instance_valid(actor) or terminal():
		return
	actor.show_impact(Color(.4, 1, 1))
	if not seen_kinds.has(kind):
		seen_kinds[kind] = true
		presentation.introduce(kind, actor)
	elif stage == Stage.ENCOUNTER_ONE:
		presentation.say("enemy")


var noticed_stage: int = -1


## First sighting in a stage: the system files the engineer as the owner.
func on_enemy_noticed(_actor: Node) -> void:
	if noticed_stage == stage:
		return
	noticed_stage = stage
	presentation.say("spotted")
	message = "@here Engineer detected in production. Ticket assigned to: you."


func on_surprise(_actor: Node) -> void:
	presentation.say("surprise")


## At most a few enemies wind up at once, so a crowd reads as a sequence of tells.
func request_attack(actor: Node) -> bool:
	# Nobody swings while the camera is watching an employee turn.
	if outbreak_left > 0:
		return false
	var busy: int = 0
	# Bugs nip freely and never queue the real threats behind them.
	if bugs.has(actor):
		return true
	for other: CharacterBody3D in alive + sync_alive:
		if other != actor and is_instance_valid(other) and other.health > 0 and other.melee.attacking and other.melee.elapsed < other.melee.windup + other.melee.active_time:
			busy += 1
	return busy < max_telegraphs


func _book_meeting(at: Vector3) -> void:
	if terminal():
		return
	var zone: Node3D = ZONE.new()
	zone.player = player
	zone.position = at
	zone.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(zone)
	actors.append(zone)
	zones.append(zone)
	zone.expired.connect(_on_zone_expired.bind(zone), CONNECT_ONE_SHOT)
	presentation.meeting_booked()


func _on_zone_expired(zone: Node3D) -> void:
	zones.erase(zone)
	actors.erase(zone)
	zone.queue_free()


func _on_scope_grew(stage_reached: int) -> void:
	presentation.say("scope_grow%d" % stage_reached)
	message = ["", "SCOPE CHANGE • One small requirement has been added.", "SCOPE CHANGE • …and one more. Tiny.", "SCOPE CHANGE • Final requirement. (Not final.)"][stage_reached]


func _on_shield_cast(count: int) -> void:
	if count > 0:
		message = "DEPENDENCY LOCK  •  %d shielded. Hit the Blocker mid-cast." % count


func in_quick_sync() -> bool:
	var at: Vector3 = player.global_position
	return at.x > 18.8 and at.z > -15.5 and at.z < -2.3


func _start_quick_sync() -> void:
	quick_sync = "active"
	log_event("Pulled into a Quick Sync (15 min)")
	for entry: Array in [["QuickSyncDoorA", -8.75], ["QuickSyncDoorB", -7.25]]:
		var door: StaticBody3D = room.get_node(entry[0])
		door.position.z = entry[1]
		door.collision_layer = 1
	presentation.quick_sync(true)
	message = "QUICK SYNC (15 MIN) • Leadership has taken this offline. Survive the meeting."
	if outbreaks():
		outbreak_left = OUTBREAK_BURST
	for index in range(QUICK_SYNC.size()):
		_spawn_entry(QUICK_SYNC[index], sync_alive, sync_hosts[index] if index < sync_hosts.size() else null)
	sync_hosts.clear()
	if outbreaks():
		presentation.outbreak(sync_alive[0], "Meeting Room 3")


func _end_quick_sync() -> void:
	quick_sync = "done"
	log_event("Quick Sync survived; action items: none")
	for entry: Array in [["QuickSyncDoorA", -10.25], ["QuickSyncDoorB", -5.75]]:
		var door: StaticBody3D = room.get_node(entry[0])
		door.position.z = entry[1]
		door.collision_layer = 0
	player.health = mini(player.max_health, player.health + 30)
	player.health_changed.emit(player.health)
	run.change_burnout(-20, "Quick Sync minutes")
	run.apply_to(player)
	presentation.quick_sync(false)
	message = "MEETING ENDED • Action items: none • +30 health • Burnout −20"


func _on_record_died(actor: CharacterBody3D) -> void:
	if terminal():
		return
	if actor == boss:
		presentation.kill_cam(actor.global_position, player.global_position, true, 2.8)
		enemies_defeated += 1
		_enter(Stage.RESOLVED)
		return
	var in_sync: bool = sync_alive.has(actor)
	if not in_sync and not alive.has(actor):
		return
	enemies_defeated += 1
	corpses[actor] = 3.0
	if actor.has_node("RecordMarker"):
		actor.get_node("RecordMarker").hide()
	if actor.get("growth") != null and actor.growth >= 2:
		run.change_burnout(-8, "Descoped")
		run.apply_to(player)
		presentation.say("descoped")
	if in_sync:
		sync_alive.erase(actor)
		_kill_feedback(actor, false)
		if sync_alive.is_empty():
			presentation.kill_cam(actor.global_position, player.global_position, true)
			_end_quick_sync()
		return
	alive.erase(actor)
	remaining -= 1
	# Finishers: the last kill of a wave always gets the kill cam; big cuts now and then.
	var last_kill: bool = alive.is_empty() and pending.is_empty()
	if last_kill or actor.last_damage >= MonsterRig.SLICE_DAMAGE:
		presentation.kill_cam(actor.global_position, player.global_position, last_kill)
	_kill_feedback(actor, false)
	if alive.is_empty() and pending.is_empty():
		if wave_index >= waves().size():
			_close_bugs()
			if stage == Stage.ENCOUNTER_TWO:
				_complete_containment()
			var next: Stage = Stage.INVESTIGATION if stage == Stage.ENCOUNTER_ONE else Stage.BOSS
			if outbreaks():
				upgrade_next = next
				upgrade_delay = UPGRADE_BEAT
			else:
				_offer_upgrade(next)
		else:
			# Stray bugs would keep the floor "in battle" and block talking to the next wave.
			_close_bugs()
			spawn_delay = wave_breather


func near_console() -> bool:
	return player.position.distance_to(CONSOLE_POSITION) < 4.0


## The nearest employee the due wave is waiting inside.
func _strangest() -> Node3D:
	var best: Node3D = null
	for host: Node3D in hosts:
		if is_instance_valid(host) and (best == null or _flat(host.global_position) < _flat(best.global_position)):
			best = host
	return best


func encounter_status() -> String:
	if armed and _strangest() != null:
		return "%d acting strange · %d m · snap in %ds" % [hosts.size(), roundi(_flat(_strangest().global_position)), maxi(0, ceili(armed_left))]
	if quick_sync == "active":
		return "Quick Sync · %d left" % sync_alive.size()
	if stage in [Stage.ENCOUNTER_ONE, Stage.ENCOUNTER_TWO] and nearest_threat() != null:
		var near: CharacterBody3D = nearest_threat()
		var distance: int = roundi(Vector2(near.global_position.x - player.global_position.x, near.global_position.z - player.global_position.z).length())
		return "%d threat%s · nearest %d m" % [remaining, "" if remaining == 1 else "s", distance]
	if stage in [Stage.ENCOUNTER_ONE, Stage.ENCOUNTER_TWO] and wave_index >= waves().size() and alive.is_empty() and pending.is_empty():
		return "Area clear"
	if stage in [Stage.ENCOUNTER_ONE, Stage.ENCOUNTER_TWO]:
		return "%d left · wave %d/%d%s" % [remaining, wave_index, waves().size(), " · next in %ds" % maxi(1, ceili(spawn_delay)) if alive.is_empty() and pending.is_empty() and not modal_pending() else ""]
	if stage == Stage.BOSS and not boss_triggered:
		return "Gate open · head north"
	if stage == Stage.BOSS and not is_instance_valid(active_enemy):
		return "Arriving in %ds" % maxi(1, ceili(spawn_delay))
	return ""


func inspect_console() -> void:
	if stage != Stage.INVESTIGATION or not near_console():
		return
	presentation.say("evidence_open")
	if not inspected:
		presentation.evidence_shot()
	inspected = true
	console_marker.text = "EVIDENCE OPEN"
	objective = "Which system lost it?  1 · 2 · 3"
	message = "1  Core Ledger: SUCCESS — signed receipt confirms money was saved.\n2  Loan Management: FAILED — waiting for payment confirmation.\n3  Payment Processing: NOT FOUND — delivery log stops before arrival."


func interact() -> void:
	if terminal() or modal_pending() or stage == Stage.ALERT:
		return
	var nearest: String = ""
	for key: String in interactions:
		if interactions[key].in_range(player) and (nearest.is_empty() or _flat(interactions[key].global_position) < _flat(interactions[nearest].global_position)):
			nearest = key
	var someone: Dictionary = talk_target()
	if not someone.is_empty() and (nearest.is_empty() or _flat(someone.body.global_position) < _flat(interactions[nearest].global_position)):
		talk(someone)
	elif not nearest.is_empty():
		use(nearest)


func _flat(at: Vector3) -> float:
	return Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length()


## Who the engineer could talk to right now: the nearest coworker or planted employee in
## reach, never while a fight is on. {body, tree, name, standing}, or empty.
func talk_target() -> Dictionary:
	if terminal() or modal_pending() or stage == Stage.ALERT or battle_mode.engaged or outbreak_left > 0:
		return {}
	var best: Dictionary = {}
	var best_distance: float = TALK_RANGE
	for someone: Dictionary in coworkers.people:
		var distance: float = _flat(someone.body.global_position)
		# The dead, and the ones charging a monster, are not taking questions.
		if distance < best_distance and DIALOGUES.has_tree(someone.entry.name) and not someone.dead and not someone.charging:
			best_distance = distance
			best = {"body": someone.body, "tree": DIALOGUES.tree(someone.entry.name), "name": someone.entry.name,
				"standing": someone.entry.routine not in ["asleep", "sit"], "animator": someone.animator}
	for host: Node3D in hosts + sync_hosts:
		if is_instance_valid(host) and _flat(host.global_position) < best_distance:
			best_distance = _flat(host.global_position)
			best = {"body": host, "tree": DIALOGUES.host_tree(host.identity, host.kind), "name": host.name, "standing": true, "animator": host.animator}
	return best


func _refresh_talk_prompt() -> void:
	var someone: Dictionary = talk_target()
	if someone.is_empty():
		talk_prompt.show_for(null, "", false, 0.0)
	else:
		talk_prompt.show_for(someone.body, someone.tree.who, str(someone.tree.get("voice", "")).begins_with("host_"), 2.2 if someone.standing else 1.8)


## Stop and talk: the world pauses, the two face each other, the camera finds the pair.
func talk(someone: Dictionary) -> void:
	if someone.is_empty() or modal_pending():
		return
	talking = someone.body
	talk_prompt.show_for(null, "", false, 0.0)
	# Their passing remark would hang over the conversation.
	for label: Node in talking.find_children("*", "Label3D", false, false):
		(label as Label3D).visible = false
	player.melee.cancel()
	player.clear_combo()
	var to: Vector3 = talking.global_position - player.global_position
	to.y = 0
	if to.length() > .1:
		player.visual.rotation.y = atan2(-to.x, -to.z)
		if someone.standing:
			# Office bodies face +Z: turn the speaker back toward the engineer.
			talking.global_rotation.y = atan2(-to.x, -to.z)
	# The two of them keep breathing (and gesturing) while everything else waits.
	talking.process_mode = Node.PROCESS_MODE_ALWAYS
	player.get_node("Visual/Character").process_mode = Node.PROCESS_MODE_ALWAYS
	# Nobody wants a giant keyboard in the two-shot; it comes back with play.
	player.get_node("Visual/Character").weapon.visible = false
	if "talking" in talking:
		talking.talking = true
	talk_with = someone
	talk_line = 0
	if someone.standing and someone.animator != null:
		(someone.animator as AnimationPlayer).play("CharacterArmature|Idle", .2)
	presentation.begin_dialogue(talking, someone.standing)
	log_event("Stopped to talk to " + someone.tree.who.capitalize())
	player.camera_rig.set_capture(false)
	dialogue.open(someone.tree, _talk_effect, talked.has(someone.name), _talk_frame)
	talked[someone.name] = true


func _talk_effect(effect: Dictionary) -> void:
	if effect.has("burnout"):
		run.change_burnout(int(effect.burnout), effect.get("note", "Small talk"))
		run.apply_to(player)


## Every frame of a talk: the camera cuts with whoever speaks, and the other person acts
## the line out (an emphatic line gets arms up, a question gets a point).
func _talk_frame(who: String, time: float, line: int, text: String) -> void:
	presentation.dialogue_camera(who, time, line)
	var animator: AnimationPlayer = talk_with.get("animator")
	if animator == null or not talk_with.get("standing", false):
		return
	if line != talk_line:
		talk_line = line
		var clip: String = "CharacterArmature|Idle"
		if who == "them":
			clip = "CharacterArmature|Victory" if text.contains("!") else ("ual/no" if text.begins_with("No") or text.begins_with("Don't") else "ual/talking")
		if animator.has_animation(clip):
			animator.play(clip, .25)
		animator.speed_scale = 1.0
	elif not animator.is_playing() or (animator.current_animation.ends_with("Victory") and time > 2.4):
		animator.play("CharacterArmature|Idle", .3)


func _end_talk() -> void:
	if is_instance_valid(talking):
		talking.process_mode = Node.PROCESS_MODE_INHERIT if not talking.has_method("turn") else Node.PROCESS_MODE_PAUSABLE
		if "talking" in talking:
			talking.talking = false
	player.get_node("Visual/Character").process_mode = Node.PROCESS_MODE_INHERIT
	player.get_node("Visual/Character").weapon.visible = true
	var spoken_to: Node3D = talking
	talk_with = {}
	talking = null
	presentation.release_camera()
	if not terminal():
		player.camera_rig.set_capture(true)
	# A conversation with someone the wave is waiting inside only ends one way.
	if armed and hosts.has(spoken_to):
		_break_out(spoken_to, "talk")


func use(key: String) -> void:
	match key:
		"coffee":
			coffee_cups += 1
			if coffee_cups == 1:
				log_event("One coffee (policy maximum)")
				coffee_left = coffee_seconds
				run.motivation = coffee_bonus
				player.move_multiplier = 1.0 + coffee_bonus
				run.change_burnout(-10, "Coffee")
				run.apply_to(player)
				presentation.say("coffee")
				message = "TEMPORARY MOTIVATION • +%d%% damage and speed for %ds • Burnout −10" % [roundi(coffee_bonus * 100), roundi(coffee_seconds)]
			elif coffee_cups == 2:
				presentation.say("coffee_denied")
				message = "Corporate Notice: Please limit coffee consumption to one cup per employee."
			else:
				presentation.say("coffee_water")
				message = "The machine dispenses hot water. Motivation not included."
		"vending":
			presentation.say("vending")
			message = "SNACK-O-MATIC: ERR ITEM 404. Your snack exists in a different environment."
		"microwave":
			presentation.say("microwave")
			message = "Facilities ticket #2019-0412 (Microwave): status changed to WON'T FIX."
		"poster":
			presentation.say("poster")
			message = "Wellness tip of the week: Burnout is a mindset."
	presentation.used(key)


func buff_text() -> String:
	return "MOTIVATED  %ds" % ceili(coffee_left) if coffee_left > 0 else ""


func choose_system(choice: int) -> void:
	if modal_pending() or stage != Stage.INVESTIGATION or not inspected or not near_console():
		return
	if choice == 3:
		_offer_corporate()
	elif choice in [1, 2]:
		mistakes += 1
		objective = "Not that one. Who never received it?  1 · 2 · 3"


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or event.is_echo():
		return
	if event.is_action_pressed("inspect_record"):
		if stage == Stage.INVESTIGATION and near_console():
			inspect_console()
		else:
			interact()
		get_viewport().set_input_as_handled()
	for index in range(1, 4):
		if event.is_action_pressed("choose_record_" + str(index)):
			choose_system(index)
			get_viewport().set_input_as_handled()


func _make_copies() -> void:
	if stage != Stage.BOSS or not is_instance_valid(active_enemy) or not copies.is_empty():
		return
	presentation.say("variance_half")
	presentation.say("copies", true)
	for side in [-1, 1]:
		var copy: Node3D = Node3D.new()
		copy.position = active_enemy.position + Vector3(side * 2.3, 0, 0)
		add_child(copy)
		actors.append(copy)
		copies.append(copy)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(.65, .3, .6, .55)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var rig: MonsterRig = active_enemy.rig
		if rig != null:
			copy.add_child(rig.projection(material))
		for original in active_enemy.visual.find_children("*", "MeshInstance3D", true, false):
			if original.mesh == null or original == active_enemy.tell or original == active_enemy.melee.arc:
				continue
			if not original.is_visible_in_tree() or (rig != null and rig.is_ancestor_of(original)):
				continue
			var mesh: MeshInstance3D = MeshInstance3D.new()
			mesh.mesh = original.mesh
			mesh.transform = active_enemy.visual.global_transform.affine_inverse() * original.global_transform
			mesh.material_override = material
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			copy.add_child(mesh)
		var tag: Label3D = Label3D.new()
		tag.text = "◇  UNVERIFIED COPY\nSUCCESS?"
		tag.position.y = 4.1
		tag.font_size = 32
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		copy.add_child(tag)
	message = "FALSE POSITIVES  •  Strike the solid ◆ when it's OPEN."


func fail() -> void:
	_enter(Stage.FAILED)


func _finish() -> void:
	decision_pending = false
	if challenge_result == "Active":
		challenge_result = "Interrupted"
	challenge_left = 0
	upgrade_pending = false
	upgrade_ui.close()
	var won: bool = stage == Stage.RESOLVED
	console_marker.text = ""
	message = "Friday, 17:00. You may now leave. Subject to availability." if won else "Friday, 16:59. The incident has been reassigned to you."
	for actor in actors:
		if is_instance_valid(actor) and actor is CharacterBody3D:
			actor.melee.cancel()
	for zone: Node3D in zones:
		zone.hide()
		zone.set_physics_process(false)
	player.zone_multiplier = 1.0
	for copy in copies:
		copy.hide()
		copy.queue_free()
	copies.clear()
	light_target = .35 if won else 1.2
	_dashboard("PRODUCTION\nRECOVERED" if won else "INCIDENT\nUNRESOLVED", "FRIDAY / 17:00" if won else "OWNER: YOU")
	objective = "R — return to Friday, 4:59 PM"
	report = "INCIDENT 001 — RESOLVED\n\nRoot cause: downstream transaction delivery failed.\nResolution: missing record identified; discrepancy eliminated.\n\nManagement: Great collaborative effort.\nSpecial thanks to leadership for driving the resolution.\nActual engineering contributors: 1" if won else "INCIDENT 001 — UNRESOLVED\n\nRoot cause: engineer failed to anticipate undocumented behavior.\nCorrective action: Improve anticipation.\nAssigned owner: You.    Due date: Yesterday.\n\nField note: evade the orange arc; counter during recovery.\nThe Variance takes damage only while marked OPEN."
	report += "\n\nDebt: %d — %s\nUpgrades: %s" % [run.debt, run.severity(), run.summary()]
	report += "\nBurnout: %d — %s\nManagement: %s\nCommitment: %s" % [run.burnout, run.burnout_title(), corporate_title(), challenge_result]
	report += "\nPeak Burnout: %d • Enemies defeated: %d\nBoss: %s" % [run.peak_burnout, enemies_defeated, "Eliminated" if won else ("Encountered — unresolved" if boss_encountered else "Not encountered")]
	report += "\n\nTime: %d:%02d    Investigation retries: %d\nR — restart incident" % [int(elapsed) / 60, int(elapsed) % 60, mistakes]
	report += "\n\nEngineer request: go home. Status: pending approval.\nCalendar: Retrospective — tomorrow, 09:00." if won else "\n\nCalendar: Your retrospective attendance is still required."
	room.get_node("Clock").text = "FRIDAY / 17:00" if won else "FRIDAY / 16:59"
	player.melee.cancel()
	player.narrative_hold = true
	if hold_ending and player.camera_rig.controls_active:
		ending_hold = ENDING_HOLD
	else:
		player.camera_rig.set_capture(false)


func _dashboard(title: String, detail: String) -> void:
	var recovered: bool = stage == Stage.RESOLVED
	var color: Color = Color(.3, .9, .75) if recovered or (stage == Stage.ALERT and not alert_played) else Color(1, .3, .12)
	room.get_node("Critical").modulate = color
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	room.get_node("IncidentStrip").material_override = material
	room.get_node("Critical").text = title
	room.get_node("RootCause").text = detail
	room.get_node("Impossible").text = "CORE: SUCCESS"
	room.get_node("ETA").text = "PAYMENTS: RECOVERED" if stage == Stage.RESOLVED else "PAYMENTS: NOT FOUND"
	_debt_dashboard()


func _offer_upgrade(next: Stage) -> void:
	if modal_pending() or terminal():
		return
	upgrade_next = next
	upgrade_pending = true
	player.melee.cancel()
	player.clear_combo()
	player.camera_rig.set_capture(false)
	upgrade_ui.open(run)


func choose_upgrade(index: int) -> void:
	if not upgrade_pending or index < 0 or index > 2 or terminal():
		return
	var before: int = run.debt
	run.select(index)
	run.apply_to(player)
	upgrade_pending = false
	upgrade_ui.close()
	_enter(upgrade_next)
	message = "%s • +%d DEBT → %d / %s\n%s" % [run.TITLES[index], run.debt - before, run.debt, run.severity(), message]
	if run.debt > before:
		presentation.say("debt")
	player.camera_rig.set_capture(true)


func _debt_dashboard() -> void:
	if run.debt == 0 or terminal():
		return
	var color: Color = [Color(1, .55, .2), Color(1, .4, .12), Color(1, .2, .12), Color(1, .12, .3)][run.band()]
	room.get_node("Critical").modulate = color
	var material: StandardMaterial3D = room.get_node("IncidentStrip").material_override
	material.albedo_color = color
	material.emission = color
	room.get_node("Impossible").text = "DEBT %d / %s" % [run.debt, run.severity()]
	room.get_node("ETA").text = "PURSUIT +%d%% / RISK ACCEPTED" % roundi((run.pressure() - 1) * 100)


func modal_pending() -> bool:
	return upgrade_pending or decision_pending or talking != null


func _choose_modal(index: int) -> void:
	if decision_pending:
		choose_corporate(index)
	else:
		choose_upgrade(index)


func _offer_corporate() -> void:
	if modal_pending() or terminal() or corporate_choice != -1:
		return
	decision_pending = true
	player.melee.cancel()
	player.clear_combo()
	player.camera_rig.set_capture(false)
	upgrade_ui.open_corporate(run, commitment_seconds)


func choose_corporate(index: int) -> void:
	if not decision_pending or terminal() or index < 0 or index > 2:
		return
	log_event("Told Leadership: " + ["“Five minutes.”", "“A realistic estimate, shortly.”", "“It's blocked on another team.”"][index])
	corporate_choice = index
	decision_pending = false
	upgrade_ui.close()
	var responses: Array[String] = [
		"Commitment logged. The estimate is now a deadline.",
		"Estimate logged. An estimate of the estimate has been requested.",
		"Dependency escalated. It has been reassigned back to you as a Blocker."]
	var changes: Array[int] = [run.commit_burnout, run.estimate_burnout, -run.dependency_relief]
	run.change_burnout(changes[index], corporate_title())
	run.apply_to(player)
	if index == 0:
		challenge_left = commitment_seconds
		challenge_result = "Active"
	_enter(Stage.ENCOUNTER_TWO)
	message = responses[index] + "\n" + ("Optional: clear containment before the timer for Burnout relief." if index == 0 else "Containment: %d records. Clear them for Burnout relief." % remaining)
	player.camera_rig.set_capture(true)


func corporate_title() -> String:
	return "None" if corporate_choice < 0 else ["Commit to Five Minutes", "Give a Realistic Estimate", "Escalate the Dependency"][corporate_choice]


func _on_damage_accepted(base_amount: int) -> void:
	if terminal() or base_amount < run.meaningful_hit:
		return
	run.change_burnout(run.hit_burnout, "Meaningful hit")
	run.apply_to(player)
	if run.burnout >= 70:
		presentation.say("burnout", true)
	if player.health <= 30:
		presentation.say("low_health")


func _complete_containment() -> void:
	var relief: int = run.containment_relief
	if challenge_result == "Active":
		challenge_result = "Met — bonus recovery"
		relief += run.commitment_reward
	challenge_left = 0
	run.change_burnout(-relief, "Containment resolved")
	run.apply_to(player)
