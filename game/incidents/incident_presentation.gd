extends CanvasLayer
## Authored Incident 001 beats only. Gameplay owns stages, damage and choices.
const LINES: Dictionary = {
	"friday": ["PEOPLE OPERATIONS", "Happy Friday, team! Enjoy your well-deserved weekend!"],
	"relief": ["ENGINEER", "One minute. No deployments. No surprises."],
	"alert": ["MONITORING / SEV-1", "CRITICAL PRODUCTION INCIDENT\nInconsistent transaction states detected."],
	"eta": ["MANAGEMENT", "Quick question. Can we have an ETA?"],
	"start": ["ENGINEER", "You've got to be fucking kidding me."],
	"enemy": ["ENGINEER", "This was not in the ticket."],
	"investigate": ["INCIDENT CHANNEL", "Can we confirm whether this is a known issue?"],
	"debt": ["ENGINEER", "That's a Monday problem."],
	"contain": ["MANAGEMENT", "Please keep the incident channel updated."],
	"visibility": ["LEADERSHIP", "Leadership needs visibility."],
	"burnout": ["ENGINEER", "I am so done with this. Still fixing it."],
	"boss": ["ENGINEER", "Finally. A reproducible issue."],
	"copies": ["ENGINEER", "Great. Duplicate records."],
	"rca": ["MANAGEMENT", "Do we have an RCA?"],
}
var incident: Node3D
var seen: Dictionary = {}
var queue: Array[String] = []
var current_line: String = ""
var line_left: float = 0
var opening_seen: bool = false
var boss_seen: bool = false
var short_opening: bool = false
var boss_length: float = 6
var camera: Camera3D
var panel: PanelContainer
var caption: Label
var title: Label
var hint: Label
var ambient: AudioStreamPlayer
var cue: AudioStreamPlayer
var fragments: Array[MeshInstance3D] = []
var monitors: Array[MeshInstance3D] = []
var screen_material: StandardMaterial3D

func _ready() -> void:
	incident = get_parent()
	layer = 4
	camera = Camera3D.new()
	camera.fov = 55
	incident.add_child(camera)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -454
	panel.offset_right = -24
	panel.offset_top = -252
	panel.offset_bottom = -132
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(.018, .035, .045, .95)
	style.border_color = Color(.3, .75, .8)
	style.border_width_left = 3
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size", 19)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(caption)
	title = Label.new()
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -450
	title.offset_right = 450
	title.offset_top = 45
	title.offset_bottom = 150
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	hint = Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hint.offset_left = -270
	hint.offset_right = -24
	hint.offset_top = 16
	hint.offset_bottom = 44
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.text = "TAB — skip introduction"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	ambient = AudioStreamPlayer.new()
	ambient.stream = preload("res://assets/audio/office_air.wav")
	ambient.volume_db = -28
	add_child(ambient)
	cue = AudioStreamPlayer.new()
	cue.volume_db = -20
	add_child(cue)
	screen_material = StandardMaterial3D.new()
	screen_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Only workstation screen surfaces; geometry and navigation remain untouched.
	for workstation in incident.room.get_children():
		if "Workstation" in workstation.name:
			for mesh in workstation.find_children("*", "MeshInstance3D", true, false):
				if str(mesh.name).begins_with("Code"):
					monitors.append(mesh)
	for mesh in monitors:
		mesh.material_override = screen_material
	var fragment_material: StandardMaterial3D = StandardMaterial3D.new()
	fragment_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fragment_material.albedo_color = Color(.3, .8, .85)
	for index in range(8):
		var fragment: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(.35, .08, .18)
		fragment.mesh = box
		fragment.material_override = fragment_material
		fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		incident.add_child(fragment)
		fragment.hide()
		fragments.append(fragment)

func reset_story() -> void:
	release_camera()
	short_opening = opening_seen
	seen.clear()
	queue.clear()
	current_line = ""
	line_left = 0
	panel.hide()
	title.hide()
	hint.hide()
	ambient.stop()
	cue.stop()
	for fragment in fragments:
		fragment.hide()
	incident.player.position = Vector3(-1.8, .05, 10.8)
	incident.player.visual.rotation.y = .35
	set_screens(Color(.12, .42, .38))

func set_screens(color: Color) -> void:
	screen_material.albedo_color = color

func say(id: String, priority: bool = false) -> void:
	if seen.has(id):
		return
	seen[id] = true
	if priority:
		queue.push_front(id)
		line_left = 0
	else:
		queue.append(id)
	# Bounded backlog; discarded lines never return later out of context.
	if queue.size() > 3:
		queue.remove_at(1)

func sound(path: String) -> void:
	if DisplayServer.get_name() != "headless":
		cue.stream = load(path)
		cue.play()

func release_camera() -> void:
	incident.player.narrative_hold = false
	incident.player.get_node("Visual/Character").story_pose = 0
	if camera != null and camera.current:
		incident.player.get_node("CameraRig/SpringArm3D/Camera3D").make_current()

func opening_duration() -> float:
	return 3.0 if short_opening else 24.0

func declare_incident() -> void:
	if incident.alert_played:
		return
	incident.alert_played = true
	incident.light_target = 2.3
	incident._dashboard("THREE SYSTEMS\nDISAGREE", "CRITICAL INCIDENT / SEV-1")
	set_screens(Color(.55, .08, .035))
	if DisplayServer.get_name() != "headless":
		incident.get_node("AlertSound").play()

func skip() -> void:
	if incident.terminal() or incident.modal_pending():
		return
	if incident.stage == incident.Stage.ALERT:
		opening_seen = true
		declare_incident()
		incident._enter(incident.Stage.ENCOUNTER_ONE)
	elif incident.stage == incident.Stage.BOSS and not is_instance_valid(incident.active_enemy):
		boss_seen = true
		incident.spawn_delay = 0
		incident._spawn()

func stage_changed() -> void:
	release_camera()
	queue.clear()
	line_left = 0
	current_line = ""
	match incident.stage:
		incident.Stage.ENCOUNTER_ONE:
			opening_seen = true
			declare_incident()
		incident.Stage.INVESTIGATION:
			say("investigate")
		incident.Stage.ENCOUNTER_TWO:
			say("contain")
			set_screens(Color(.65, .12, .04))
		incident.Stage.BOSS:
			boss_length = 1.5 if boss_seen else 6.0
			incident.spawn_delay = boss_length
			incident.light_target = 3.7
			set_screens(Color(.45, .12, .3))
			sound("res://assets/audio/boss_arrival.wav")
		incident.Stage.RESOLVED, incident.Stage.FAILED:
			ambient.stop()
			set_screens(Color(.12, .42, .38) if incident.stage == incident.Stage.RESOLVED else Color(.25, .05, .025))
			sound("res://assets/audio/resolved.wav" if incident.stage == incident.Stage.RESOLVED else "res://assets/audio/boss_arrival.wav")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB and not get_tree().paused:
		skip()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	for fragment in fragments:
		fragment.visible = false
	var visible_play: bool = not get_tree().paused and not incident.terminal() and not incident.modal_pending()
	panel.visible = visible_play and line_left > 0
	title.visible = false
	hint.visible = false
	if not visible_play:
		return
	if not ambient.playing and DisplayServer.get_name() != "headless":
		ambient.play()
	var time: float = incident.stage_time
	if incident.stage == incident.Stage.ALERT:
		hint.show()
		title.show()
		title.text = "FRIDAY, 4:59 PM\nOFFICE AFTER HOURS" if time < 10 and not short_opening else "SEV—1\nTHE MISSING TRANSACTION"
		if short_opening:
			declare_incident()
			say("start")
		else:
			if time < 9:
				incident.player.narrative_hold = true
				incident.player.get_node("Visual/Character").story_pose = 1 if time < 5 else 2
				camera.position = Vector3(.5, 2.2, 8.2).lerp(Vector3(.1, 2.0, 8.5), minf(1, time / 8))
				camera.look_at(Vector3(-1.9, 1.25, 10.7))
				if time > 8:
					var target: Camera3D = incident.player.get_node("CameraRig/SpringArm3D/Camera3D")
					camera.global_transform = camera.global_transform.interpolate_with(target.global_transform, smoothstep(8, 9, time))
				camera.make_current()
			else:
				release_camera()
			say("friday")
			if time >= 5: say("relief")
			if time >= 10:
				declare_incident()
				say("alert", true)
			if time >= 15: say("eta")
			if time >= 20: say("start", true)
		# One gentle power sag, restricted to the emergency spill.
		if time >= 10 and time < 12:
			incident.light_target = 1.5 + .8 * absf(cos((time - 10) * PI))
	elif incident.stage == incident.Stage.BOSS and time < boss_length + 2:
		title.show()
		title.text = "DISCREPANCY CONVERGING" if time < boss_length - 2 else "THE VARIANCE\nDifference detected. Explanation unavailable."
		hint.visible = not is_instance_valid(incident.active_enemy)
		if hint.visible:
			var center: Vector3 = incident.arrival_site() + Vector3.UP * 1.5
			for index in range(fragments.size()):
				var angle: float = index * TAU / 8 + time
				var radius: float = lerpf(2.0, .15, clampf(time / boss_length, 0, 1))
				fragments[index].position = center + Vector3(cos(angle) * radius, sin(angle * 2) * .6, sin(angle) * radius)
				fragments[index].rotation = Vector3(time, angle, 0)
				fragments[index].show()
		if is_instance_valid(incident.active_enemy):
			boss_seen = true
			title.text += "\n%d / %d" % [incident.active_enemy.health, incident.active_enemy.max_health]
			say("boss", true)
	if incident.stage == incident.Stage.ENCOUNTER_TWO and time > 18: say("visibility")
	if incident.stage == incident.Stage.BOSS and time > 22: say("rca")
	line_left = maxf(0, line_left - delta)
	if line_left == 0 and not queue.is_empty():
		current_line = queue.pop_front()
		var line: Array = LINES[current_line]
		caption.text = tr(line[0]) + "\n" + tr(line[1])
		line_left = 4.5
		if line[0] != "ENGINEER": sound("res://assets/audio/notification.wav")
	panel.visible = line_left > 0
