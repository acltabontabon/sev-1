extends RefCounted
## Device preferences only; never serialize incident state or run modifiers.
## Exception: opening_seen records that this device watched the opening once, which
## unlocks skipping it. It carries no run progress.
const DEFAULTS: Dictionary = {"master": 0.8, "effects": 0.8, "voice": 0.8, "subtitles": true, "sensitivity": 1.0, "shake": 1.0, "flash": true, "fullscreen": false, "quality": 1, "opening_seen": false}
var values: Dictionary = DEFAULTS.duplicate()
var path: String = "user://settings.cfg"


func load_settings() -> void:
	values = DEFAULTS.duplicate()
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		return
	for key: String in DEFAULTS:
		var value: Variant = config.get_value("preferences", key, DEFAULTS[key])
		if key in ["flash", "fullscreen", "subtitles", "opening_seen"]:
			if value is bool:
				values[key] = value
		elif value is float or value is int:
			if is_finite(float(value)):
				match key:
					"sensitivity": values[key] = clampf(float(value), 0.2, 3.0)
					"quality": values[key] = clampi(int(value), 0, 1)
					_: values[key] = clampf(float(value), 0.0, 1.0)


func save_settings() -> Error:
	var config: ConfigFile = ConfigFile.new()
	for key: String in DEFAULTS:
		config.set_value("preferences", key, values[key])
	return config.save(path)


func apply(scene: Node = null) -> void:
	for bus_name: String in ["Master", "Effects", "Voice"]:
		var index: int = AudioServer.get_bus_index(bus_name)
		if index >= 0:
			var gain: float = values[bus_name.to_lower()]
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(gain, .0001)))
			AudioServer.set_bus_mute(index, gain <= 0)
	if DisplayServer.get_name() != "headless":
		var mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	if scene == null:
		return
	if scene.has_node("Incident/Voice"):
		scene.get_node("Incident/Voice").subtitles_enabled = values.subtitles
	var camera: Node3D = scene.get_node("Player/CameraRig")
	camera.mouse_sensitivity = .0025 * float(values.sensitivity)
	camera.impulse_degrees = .8 * float(values.shake)
	scene.get_node("HUD").damage_flash_enabled = values.flash
	var environment: Environment = scene.get_node("WorldEnvironment").environment
	environment.ssao_enabled = values.quality == 1
	environment.glow_enabled = values.quality == 1
	scene.get_viewport().msaa_3d = Viewport.MSAA_2X if values.quality == 1 else Viewport.MSAA_DISABLED
