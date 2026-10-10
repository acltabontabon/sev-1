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
}
const ZONE: Script = preload("res://game/enemies/meeting_zone.gd")
## Authored encounters: each wave is [kind, spawn marker]; waves arrive after a breather.
const WAVES: Dictionary = {
	Stage.ENCOUNTER_ONE: [[["record", "A1"], ["record", "A3"]], [["record", "A2"], ["scope", "A4"]]],
	Stage.ENCOUNTER_TWO: [[["blocker", "D2"], ["record", "D1"], ["record", "D3"]], [["invite", "D2"], ["record", "D4"], ["scope", "D1"]]],
}
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
var seen_kinds: Dictionary = {}
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
	noticed_stage = -1
	seen_kinds.clear()
	wave_index = 0
	_reset_doors()
	$AlertSound.stop()
	enemies_defeated = 0
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


func _enter(next: Stage) -> void:
	if terminal() or (modal_pending() and next != Stage.FAILED):
		return
	var valid: bool = next == Stage.FAILED or int(next) == int(stage) + 1
	if not valid:
		return
	stage = next
	stage_time = 0
	spawn_delay = 2.0
	match stage:
		Stage.ENCOUNTER_ONE:
			wave_index = 0
			remaining = stage_total()
			objective = "1 / 3 — The Discrepancy: eliminate corrupted records."
			message = "Orange arc: an attack is coming. Dodge aside, then counter."
			light_target = 2.3
		Stage.INVESTIGATION:
			objective = "Follow the cyan OPERATIONS marker to the far wall. Press E nearby."
			message = "DISCREPANCY CONFIRMED • RECONCILIATION FAILED\nINVESTIGATION REQUIRED • The east wing pantry still has coffee."
			console_marker.text = "↓ OPERATIONS\nE — INSPECT"
			_dashboard("RECONCILIATION\nFAILED", "INVESTIGATION REQUIRED")
		Stage.ENCOUNTER_TWO:
			wave_index = 0
			remaining = stage_total()
			objective = "2 / 3 — Contain the failed delivery. Clear the aggressive records."
			message = "Payment Processing is missing the delivered record.\nCore saved it. Delivery stopped downstream. These records pursue faster."
			console_marker.text = ""
			light_target = 3.2
			_dashboard("DELIVERY\nFAILED", "MISSING: PAYMENT RECORD")
		Stage.BOSS:
			# The gate lifts now; the arrival waits for the engineer to walk into the vault.
			room.get_node("VaultGate").collision_layer = 0
			spawn_delay = 9999.0
			boss_triggered = false
			objective = "3 / 3 — The Variance: enter the production core, north through the server corridor."
			message = "The original always carries a solid ◆ and VERIFIED ORIGINAL.\nFalse copies have broken ◇ markers. Trust the steady shape."
			_dashboard("FALSE\nPOSITIVES", "VERIFY BEFORE RESOLVING")
		Stage.RESOLVED, Stage.FAILED:
			_finish()
	presentation.stage_changed()


func _process(delta: float) -> void:
	var spill: OmniLight3D = room.get_node("IncidentSpill")
	spill.light_energy = move_toward(spill.light_energy, light_target + (0.0 if terminal() else run.band() * .35), delta * 1.2)
	if terminal() or get_tree().paused:
		return
	for point: Node3D in interactions.values():
		point.refresh(player, not modal_pending() and stage != Stage.ALERT)
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
	if stage in [Stage.ENCOUNTER_ONE, Stage.ENCOUNTER_TWO] and not modal_pending():
		if not pending.is_empty():
			pop_left -= delta
			if pop_left <= 0:
				_spawn_entry(pending.pop_front(), alive)
				pop_left = .4
		elif alive.is_empty() and wave_index < waves().size():
			spawn_delay -= delta
			if spawn_delay <= 0:
				_spawn()
	elif stage == Stage.BOSS and not is_instance_valid(boss):
		spawn_delay -= delta
		if spawn_delay <= 0:
			_spawn()
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


func trigger_boss() -> void:
	if stage != Stage.BOSS or boss_triggered:
		return
	boss_triggered = true
	boss_time = 0
	spawn_delay = presentation.boss_length
	presentation.vault_entered()


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
	if pending.is_empty():
		if wave_index >= waves().size():
			return
		pending = waves()[wave_index].duplicate(true)
		wave_index += 1
	_spawn_entry(pending.pop_front(), alive)
	pop_left = .4


func spawn_site(name: String) -> Vector3:
	var site: Vector3 = room.get_node("SpawnPoints/Spawn_" + name).position
	# Never materialize on top of the engineer; fall back to the farthest clear site.
	return arrival_site() if site.distance_to(player.position) < 4.0 and stage != Stage.INVESTIGATION else site


func _spawn_entry(entry: Array, group: Array[CharacterBody3D]) -> CharacterBody3D:
	var kind: String = entry[0]
	var actor: CharacterBody3D = RECORD.instantiate()
	if ARCHETYPES[kind] != null:
		actor.set_script(ARCHETYPES[kind])
	# Waves arrive unaware and must find the engineer; the Quick Sync is an ambush.
	actor.starts_aware = is_same(group, sync_alive)
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	actor.position = spawn_site(entry[1])
	actor.detection_distance = 50
	add_child(actor)
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
	actor.show_impact(Color(.4, 1, 1))
	if not seen_kinds.has(kind):
		seen_kinds[kind] = true
		presentation.introduce(kind, actor)
	elif stage == Stage.ENCOUNTER_ONE:
		presentation.say("enemy")
	return actor


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
	var busy: int = 0
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
		message = "DEPENDENCY LOCK • %d ally shielded for 5s. Break it: hit the Blocker mid-cast, or take it down." % count


func in_quick_sync() -> bool:
	var at: Vector3 = player.global_position
	return at.x > 18.8 and at.z > -15.5 and at.z < -2.3


func _start_quick_sync() -> void:
	quick_sync = "active"
	for entry: Array in [["QuickSyncDoorA", -8.75], ["QuickSyncDoorB", -7.25]]:
		var door: StaticBody3D = room.get_node(entry[0])
		door.position.z = entry[1]
		door.collision_layer = 1
	presentation.quick_sync(true)
	message = "QUICK SYNC (15 MIN) • Leadership has taken this offline. Survive the meeting."
	for entry: Array in QUICK_SYNC:
		_spawn_entry(entry, sync_alive)


func _end_quick_sync() -> void:
	quick_sync = "done"
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
		enemies_defeated += 1
		_enter(Stage.RESOLVED)
		return
	var in_sync: bool = sync_alive.has(actor)
	if not in_sync and not alive.has(actor):
		return
	enemies_defeated += 1
	corpses[actor] = 3.0
	if actor.label != null:
		actor.label.text = "RECORD RECONCILED"
	if actor.has_node("RecordMarker"):
		actor.get_node("RecordMarker").hide()
	if actor.get("growth") != null and actor.growth >= 2:
		run.change_burnout(-8, "Descoped")
		run.apply_to(player)
		presentation.say("descoped")
	if in_sync:
		sync_alive.erase(actor)
		if sync_alive.is_empty():
			_end_quick_sync()
		return
	alive.erase(actor)
	remaining -= 1
	if alive.is_empty() and pending.is_empty():
		if wave_index >= waves().size():
			if stage == Stage.ENCOUNTER_TWO:
				_complete_containment()
			_offer_upgrade(Stage.INVESTIGATION if stage == Stage.ENCOUNTER_ONE else Stage.BOSS)
		else:
			spawn_delay = wave_breather


func near_console() -> bool:
	return player.position.distance_to(CONSOLE_POSITION) < 4.0


func encounter_status() -> String:
	if quick_sync == "active":
		return "Quick Sync in progress • %d attendee%s remaining" % [sync_alive.size(), "" if sync_alive.size() == 1 else "s"]
	if stage in [Stage.ENCOUNTER_ONE, Stage.ENCOUNTER_TWO]:
		return "%d threat%s remaining • wave %d / %d%s" % [remaining, "" if remaining == 1 else "s", wave_index, waves().size(), " • Next arrival in %ds" % maxi(1, ceili(spawn_delay)) if alive.is_empty() and pending.is_empty() and not modal_pending() else ""]
	if stage == Stage.BOSS and not boss_triggered:
		return "The restricted gate is open. Follow the corridor north."
	if stage == Stage.BOSS and not is_instance_valid(active_enemy):
		return "The Variance arrives in %ds" % maxi(1, ceili(spawn_delay))
	return ""


func inspect_console() -> void:
	if stage != Stage.INVESTIGATION or not near_console():
		return
	presentation.say("evidence_open")
	if not inspected:
		presentation.evidence_shot()
	inspected = true
	console_marker.text = "EVIDENCE OPEN"
	objective = "Which system is missing the record? Press 1, 2, or 3."
	message = "1  Core Ledger: SUCCESS — signed receipt confirms money was saved.\n2  Loan Management: FAILED — waiting for payment confirmation.\n3  Payment Processing: NOT FOUND — delivery log stops before arrival."


func interact() -> void:
	if terminal() or modal_pending() or stage == Stage.ALERT:
		return
	for key: String in interactions:
		if interactions[key].in_range(player):
			use(key)
			return


func use(key: String) -> void:
	match key:
		"coffee":
			coffee_cups += 1
			if coffee_cups == 1:
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
		objective = "Core saved it; Loans is waiting. Which system never received it? Try again."


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
		for original in active_enemy.visual.find_children("*", "MeshInstance3D", true, false):
			if original.mesh == null or original == active_enemy.tell or original == active_enemy.melee.arc:
				continue
			var mesh: MeshInstance3D = MeshInstance3D.new()
			mesh.mesh = original.mesh
			mesh.transform = active_enemy.visual.global_transform.affine_inverse() * original.global_transform
			mesh.material_override = material
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			copy.add_child(mesh)
		var tag: Label3D = Label3D.new()
		tag.text = "◇  UNVERIFIED COPY\nSUCCESS?"
		tag.position.y = 3.1
		tag.font_size = 32
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		copy.add_child(tag)
	message = "FALSE POSITIVES — two harmless projections.\nFollow the solid ◆. Strike the original when OPEN."


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
	return upgrade_pending or decision_pending


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
