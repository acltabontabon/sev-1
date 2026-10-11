extends AudioStreamPlayer3D
## Local ambient breathing. Hero distance controls gain; the camera only pans it.

@export_range(1.0, 10.0) var audible_range: float = 5.0
@export_range(0.0, 2.0) var close_range: float = 1.2
@export_range(-30.0, 0.0) var close_volume_db: float = -16.0
var hero: Node3D
var sleep_hint: Label3D


func _ready() -> void:
	hero = get_tree().get_first_node_in_group("players") as Node3D
	var breath: AudioStreamWAV = preload("res://assets/audio/sfx/sleeper_snore.wav").duplicate()
	breath.loop_mode = AudioStreamWAV.LOOP_FORWARD
	breath.loop_begin = 0
	breath.loop_end = int(round(breath.get_length() * breath.mix_rate))
	stream = breath
	bus = &"Effects"
	attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	attenuation_filter_cutoff_hz = 20500.0
	panning_strength = .7
	position.y = 1.65 # The body is scaled to .62; this puts the sound at desk/head height.
	volume_db = -80.0
	sleep_hint = Label3D.new()
	sleep_hint.text = "zZ"
	sleep_hint.font = preload("res://assets/fonts/inter_variable.ttf")
	sleep_hint.font_size = 26
	sleep_hint.pixel_size = .005
	sleep_hint.outline_size = 4
	sleep_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sleep_hint.modulate = Color(.78, .82, .9, 0)
	sleep_hint.position = Vector3(.12, .72, 0)
	sleep_hint.hide()
	add_child(sleep_hint)


func _process(_delta: float) -> void:
	var body: Node3D = get_parent() as Node3D
	if not is_instance_valid(hero) or not body.is_visible_in_tree() or hero.get("narrative_hold") == true or hero.get("health") == 0:
		stop()
		volume_db = -80.0
		sleep_hint.hide()
		return
	var distance: float = hero.global_position.distance_to(body.global_position)
	var gain: float = 1.0 - smoothstep(minf(close_range, audible_range - .01), audible_range, distance)
	if gain <= .0001:
		stop()
		volume_db = -80.0
		sleep_hint.hide()
		return
	volume_db = close_volume_db + linear_to_db(gain)
	if not playing:
		play()
	# A faint rising breath mark identifies GARY without becoming another prompt.
	var cycle: float = fmod(get_playback_position(), 4.0)
	var breath_alpha: float = sin(PI * clampf(cycle / 1.85, 0.0, 1.0))
	sleep_hint.position.y = .72 + .16 * clampf(cycle / 1.85, 0.0, 1.0)
	sleep_hint.modulate.a = .38 * gain * breath_alpha
	sleep_hint.outline_modulate.a = sleep_hint.modulate.a
	sleep_hint.visible = sleep_hint.modulate.a > .01
