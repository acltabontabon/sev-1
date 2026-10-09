extends Node
## Local, bounded authored speech. Never owns gameplay time or progression.
signal subtitle_changed(text: String)
const MANIFEST: String = "res://assets/audio/voices/dialogue.json"
var lines: Dictionary = {}
var seen: Dictionary = {}
var queue: Array[String] = []
var current_line: String = ""
var line_left: float = 0.0
var subtitle: String = ""
var subtitles_enabled: bool = true
var application_page: String = ""
var optional_cooldown: float = 0.0
var suspended: bool = false
var using_audio: bool = false
var flat: AudioStreamPlayer
var positional: AudioStreamPlayer3D
var cache: Dictionary = {}
var cache_order: Array[String] = []
var incident: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	incident = get_parent()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for entry: Dictionary in data.lines:
		lines[entry.id] = entry
	flat = AudioStreamPlayer.new()
	flat.bus = &"Voice"
	flat.volume_db = -3
	add_child(flat)
	flat.finished.connect(_finish_line)
	positional = AudioStreamPlayer3D.new()
	positional.bus = &"Voice"
	positional.volume_db = -3
	positional.unit_size = 12
	positional.max_distance = 45
	positional.max_db = -3
	positional.panning_strength = .7
	add_child(positional)
	positional.finished.connect(_finish_line)


func request(id: String) -> void:
	if not lines.has(id) or seen.has(id):
		return
	seen[id] = true
	var entry: Dictionary = lines[id]
	if entry.optional and optional_cooldown > 0:
		return
	if not current_line.is_empty() and int(entry.priority) > int(lines[current_line].priority):
		_stop_line()
	var index: int = 0
	while index < queue.size() and int(lines[queue[index]].priority) >= int(entry.priority):
		index += 1
	queue.insert(index, id)
	if queue.size() > 3:
		queue.pop_back()


func clear(reset_seen: bool = false) -> void:
	queue.clear()
	_stop_line()
	if reset_seen:
		seen.clear()
		optional_cooldown = 0


func set_presentation_state(page: String, captions_enabled: bool) -> void:
	application_page = page
	subtitles_enabled = captions_enabled
	_refresh_subtitle()


func _stop_line() -> void:
	flat.stop()
	positional.stop()
	flat.stream = null
	positional.stream = null
	current_line = ""
	line_left = 0
	using_audio = false
	_refresh_subtitle()


func _finish_line() -> void:
	_stop_line()


func _stream(path: String) -> AudioStream:
	if cache.has(path):
		return cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path) as AudioStream
	if stream != null:
		if cache_order.size() >= 4:
			cache.erase(cache_order.pop_front())
		cache[path] = stream
		cache_order.append(path)
	return stream


func _refresh_subtitle() -> void:
	var next: String = ""
	if subtitles_enabled and not suspended and not current_line.is_empty():
		var entry: Dictionary = lines[current_line]
		next = tr(entry.character) + "\n" + tr(entry.subtitle)
	if next != subtitle:
		subtitle = next
		subtitle_changed.emit(subtitle)


func _process(delta: float) -> void:
	var terminal: bool = incident.terminal()
	suspended = (not application_page.is_empty() and application_page != "report") or (not terminal and (get_tree().paused or incident.modal_pending()))
	flat.stream_paused = suspended
	positional.stream_paused = suspended
	_refresh_subtitle()
	if suspended:
		return
	optional_cooldown = maxf(0, optional_cooldown - delta)
	if not current_line.is_empty():
		if lines[current_line].voice_profile == "variance":
			positional.global_position = (incident.active_enemy.global_position if is_instance_valid(incident.active_enemy) else incident.arrival_site()) + Vector3.UP * 1.5
		if using_audio:
			var position: float = positional.get_playback_position() if lines[current_line].voice_profile == "variance" else flat.get_playback_position()
			var stream: AudioStream = positional.stream if lines[current_line].voice_profile == "variance" else flat.stream
			line_left = maxf(0, stream.get_length() - position)
		else:
			line_left = maxf(0, line_left - delta)
			if line_left <= 0:
				_finish_line()
	while not queue.is_empty() and lines[queue[0]].optional and optional_cooldown > 0:
		queue.pop_front()
	if current_line.is_empty() and not queue.is_empty():
		current_line = queue.pop_front()
		var entry: Dictionary = lines[current_line]
		if entry.optional:
			optional_cooldown = 8.0
		var stream: AudioStream = _stream(entry.audio)
		line_left = stream.get_length() if stream != null else float(entry.fallback_duration)
		using_audio = stream != null and DisplayServer.get_name() != "headless"
		if using_audio:
			if entry.voice_profile == "variance":
				positional.global_position = (incident.active_enemy.global_position if is_instance_valid(incident.active_enemy) else incident.arrival_site()) + Vector3.UP * 1.5
				positional.stream = stream
				positional.play()
			else:
				flat.stream = stream
				flat.play()
		_refresh_subtitle()
