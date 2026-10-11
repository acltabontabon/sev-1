extends RefCounted
## Chapter boundary only. Keep the user data directory and chapter IDs stable in updates.
const SCHEMA_VERSION: int = 1
const STAGE_ONE: String = "incident_001"
const STAGE_TWO: String = "stage_two"
var path: String = "user://chapter_progress.json"
var stage_one_completed: bool = false
var load_notice: String = ""
var compatible: bool = true


func load_progress() -> void:
	stage_one_completed = false
	load_notice = ""
	compatible = true
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		compatible = false
		load_notice = "Could not read chapter progress. Your save has been preserved."
		return
	var parser: JSON = JSON.new()
	var parsed: Error = parser.parse(file.get_as_text())
	var data: Variant = parser.data if parsed == OK else null
	if not data is Dictionary or data.get("schema_version") != SCHEMA_VERSION:
		compatible = false
		load_notice = "Chapter save is damaged or from another version. Your save has been preserved."
		return
	var completed: Variant = data.get("completed_chapters")
	if not completed is Array or not data.get("next_chapter") is String:
		compatible = false
		load_notice = "Chapter save could not be read. Your save has been preserved."
		return
	stage_one_completed = completed.has(STAGE_ONE)


func complete_stage_one() -> Error:
	if stage_one_completed:
		return OK
	if not compatible:
		return ERR_FILE_UNRECOGNIZED
	var data: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"completed_chapters": [STAGE_ONE],
		"next_chapter": STAGE_TWO,
	}
	# Replace only after a successful write, keeping an existing save on failure.
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t") + "\n")
	file.flush()
	var result: Error = file.get_error()
	file.close()
	if result == OK:
		result = DirAccess.rename_absolute(temporary, path)
	if result != OK:
		DirAccess.remove_absolute(temporary)
		return result
	stage_one_completed = true
	return OK
