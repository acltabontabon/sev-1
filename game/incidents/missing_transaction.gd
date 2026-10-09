extends Node3D
## One episode, owned locally. No asynchronous timers survive a reset.

enum Stage { ALERT, ENCOUNTER_ONE, INVESTIGATION, ENCOUNTER_TWO, BOSS, RESOLVED, FAILED }
const RECORD: PackedScene = preload("res://game/enemies/incident.tscn")
const VARIANCE: Script = preload("res://game/incidents/variance.gd")
const CONSOLE_POSITION: Vector3 = Vector3(-1.7, 0, -12.5)

@export var first_records: int = 2
@export var second_records: int = 3
@export var boss_health: int = 700
var stage: Stage = Stage.ALERT
var elapsed: float = 0.0
var stage_time: float = 0.0
var spawn_delay: float = 0.0
var remaining: int = 0
var mistakes: int = 0
var inspected: bool = false
var objective: String = ""
var message: String = ""
var report: String = ""
var active_enemy: CharacterBody3D
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
	reset_incident()


func reset_incident() -> void:
	_cleanup()
	stage = Stage.ALERT
	elapsed = 0
	stage_time = 0
	spawn_delay = 0
	remaining = 0
	mistakes = 0
	inspected = false
	report = ""
	objective = "Friday, 4:59 PM. Head into the office."
	message = "One payment. Three answers.\nCore: SUCCESS   /   Loans: FAILED   /   Payments: NOT FOUND\n“Quick question. Can we have an ETA?”"
	console_marker.text = ""
	light_target = .6
	room.get_node("IncidentSpill").light_energy = .6
	_dashboard("THREE SYSTEMS\nDISAGREE", "INCIDENT DECLARED")


func terminal() -> bool:
	return stage == Stage.RESOLVED or stage == Stage.FAILED


func _cleanup() -> void:
	active_enemy = null
	for actor in actors:
		if is_instance_valid(actor):
			actor.process_mode = Node.PROCESS_MODE_DISABLED
			actor.remove_from_group("enemies")
			actor.hide()
			actor.queue_free()
	actors.clear()
	copies.clear()


func _enter(next: Stage) -> void:
	if terminal():
		return
	var valid: bool = next == Stage.FAILED or int(next) == int(stage) + 1
	if not valid:
		return
	stage = next
	stage_time = 0
	spawn_delay = 2.0
	match stage:
		Stage.ENCOUNTER_ONE:
			remaining = first_records
			objective = "1 / 3 — The Discrepancy: eliminate corrupted records."
			message = "Orange arc: an attack is coming. Dodge aside, then counter."
			light_target = 2.3
		Stage.INVESTIGATION:
			objective = "Follow the cyan OPERATIONS marker to the far wall. Press E nearby."
			message = "DISCREPANCY CONFIRMED • RECONCILIATION FAILED\nINVESTIGATION REQUIRED"
			console_marker.text = "↓ OPERATIONS\nE — INSPECT"
			_dashboard("RECONCILIATION\nFAILED", "INVESTIGATION REQUIRED")
		Stage.ENCOUNTER_TWO:
			remaining = second_records
			objective = "2 / 3 — Contain the failed delivery. Clear the aggressive records."
			message = "Payment Processing is missing the delivered record.\nCore saved it. Delivery stopped downstream. These records pursue faster."
			console_marker.text = ""
			light_target = 3.2
			_dashboard("DELIVERY\nFAILED", "MISSING: PAYMENT RECORD")
		Stage.BOSS:
			objective = "3 / 3 — The Variance: evade while shielded; strike during OPEN."
			message = "The original always carries a solid ◆ and VERIFIED ORIGINAL.\nFalse copies have broken ◇ markers. Trust the steady shape."
			_dashboard("FALSE\nPOSITIVES", "VERIFY BEFORE RESOLVING")
		Stage.RESOLVED, Stage.FAILED:
			_finish()


func _process(delta: float) -> void:
	var spill: OmniLight3D = room.get_node("IncidentSpill")
	spill.light_energy = move_toward(spill.light_energy, light_target, delta * 1.2)
	if terminal() or get_tree().paused:
		return
	elapsed += delta
	stage_time += delta
	if stage == Stage.ALERT and stage_time >= 7:
		_enter(Stage.ENCOUNTER_ONE)
	if stage in [Stage.ENCOUNTER_ONE, Stage.ENCOUNTER_TWO, Stage.BOSS] and not is_instance_valid(active_enemy):
		spawn_delay -= delta
		if spawn_delay <= 0:
			_spawn()


func _spawn() -> void:
	var actor: CharacterBody3D = RECORD.instantiate()
	if stage == Stage.BOSS:
		actor.set_script(VARIANCE)
		actor.max_health = boss_health
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	# Fixed clear floor lanes; choose the farthest site so arrivals never hit immediately.
	var sites: Array[Vector3] = [Vector3(-2, .05, -8), Vector3(2, .05, 1), Vector3(-2, .05, 5)]
	var site: Vector3 = sites[0]
	for candidate in sites:
		if candidate.distance_to(player.position) > site.distance_to(player.position):
			site = candidate
	actor.position = site
	actor.detection_distance = 50
	if stage == Stage.ENCOUNTER_TWO:
		actor.move_speed = 3.4
	add_child(actor)
	actors.append(actor)
	active_enemy = actor
	actor.died.connect(_on_record_died.bind(actor), CONNECT_ONE_SHOT)
	if stage == Stage.BOSS:
		actor.false_positives.connect(_make_copies, CONNECT_ONE_SHOT)
	else:
		var tag: Label3D = Label3D.new()
		tag.name = "RecordMarker"
		tag.text = "TX–001  /  CORRUPTED\nSUCCESS ≠ FAILED ≠ NOT FOUND"
		tag.position.y = 2.8
		tag.font_size = 30
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		actor.add_child(tag)
	actor.show_impact(Color(.4, 1, 1))


func _on_record_died(actor: CharacterBody3D) -> void:
	if terminal() or actor != active_enemy:
		return
	active_enemy = null
	actor.label.text = "RECORD RECONCILED"
	if actor.has_node("RecordMarker"):
		actor.get_node("RecordMarker").hide()
	# A brief corpse pose remains until the next spawn; bounded to this episode.
	if stage == Stage.BOSS:
		_enter(Stage.RESOLVED)
	else:
		remaining -= 1
		if remaining == 0:
			_enter(Stage.INVESTIGATION if stage == Stage.ENCOUNTER_ONE else Stage.BOSS)
		else:
			spawn_delay = 2.5


func near_console() -> bool:
	return player.position.distance_to(CONSOLE_POSITION) < 4.0


func inspect_console() -> void:
	if stage != Stage.INVESTIGATION or not near_console():
		return
	inspected = true
	console_marker.text = "EVIDENCE OPEN\nChoose 1 / 2 / 3"
	objective = "Which system is missing the record? Press 1, 2, or 3."
	message = "1  Core Ledger: SUCCESS — signed receipt confirms money was saved.\n2  Loan Management: FAILED — waiting for payment confirmation.\n3  Payment Processing: NOT FOUND — delivery log stops before arrival."


func choose_system(choice: int) -> void:
	if stage != Stage.INVESTIGATION or not inspected or not near_console():
		return
	if choice == 3:
		_enter(Stage.ENCOUNTER_TWO)
	elif choice in [1, 2]:
		mistakes += 1
		objective = "Core saved it; Loans is waiting. Which system never received it? Try again."


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or event.is_echo():
		return
	if event.is_action_pressed("inspect_record"):
		inspect_console()
		get_viewport().set_input_as_handled()
	for index in range(1, 4):
		if event.is_action_pressed("choose_record_" + str(index)):
			choose_system(index)
			get_viewport().set_input_as_handled()


func _make_copies() -> void:
	if stage != Stage.BOSS or not is_instance_valid(active_enemy) or not copies.is_empty():
		return
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
		for part_name in ["Body", "LeftArm", "RightArm", "Eye"]:
			var original: MeshInstance3D = active_enemy.get_node("Visual/" + part_name)
			var mesh: MeshInstance3D = MeshInstance3D.new()
			mesh.mesh = original.mesh
			mesh.transform = original.transform
			mesh.material_override = material
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
	var won: bool = stage == Stage.RESOLVED
	console_marker.text = ""
	message = "Friday, 17:00. You may now leave. Subject to availability." if won else "Friday, 16:59. The incident has been reassigned to you."
	for actor in actors:
		if is_instance_valid(actor) and actor is CharacterBody3D:
			actor.melee.cancel()
	for copy in copies:
		copy.hide()
		copy.queue_free()
	copies.clear()
	light_target = .35 if won else 1.2
	_dashboard("PRODUCTION\nRECOVERED" if won else "INCIDENT\nUNRESOLVED", "FRIDAY / 17:00" if won else "OWNER: YOU")
	objective = "R — return to Friday, 4:59 PM"
	report = "INCIDENT 001 — RESOLVED\n\nRoot cause: downstream transaction delivery failed.\nResolution: missing record identified; discrepancy eliminated.\n\nManagement: Great collaborative effort.\nSpecial thanks to leadership for driving the resolution.\nActual engineering contributors: 1" if won else "INCIDENT 001 — UNRESOLVED\n\nRoot cause: engineer failed to anticipate undocumented behavior.\nCorrective action: Improve anticipation.\nAssigned owner: You.    Due date: Yesterday.\n\nField note: evade the orange arc; counter during recovery.\nThe Variance takes damage only while marked OPEN."
	report += "\n\nTime: %d:%02d    Investigation retries: %d\nR — restart incident" % [int(elapsed) / 60, int(elapsed) % 60, mistakes]
	player.melee.cancel()
	player.camera_rig.set_capture(false)


func _dashboard(title: String, detail: String) -> void:
	var recovered: bool = stage == Stage.RESOLVED
	var color: Color = Color(.3, .9, .75) if recovered else Color(1, .3, .12)
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
