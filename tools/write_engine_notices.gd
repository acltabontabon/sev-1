extends SceneTree
## Export the actual pinned engine's license notices, including bundled libraries.
func _initialize() -> void:
	var file: FileAccess = FileAccess.open("res://THIRD_PARTY_NOTICES.txt", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write engine notices")
		quit(1)
		return
	file.store_string("SEV-1 Friday Deployment — engine notices\n\nGodot Engine\n" + Engine.get_license_text() + "\n\n")
	for entry: Dictionary in Engine.get_copyright_info():
		file.store_string(str(entry) + "\n\n")
	var licenses: Dictionary = Engine.get_license_info()
	for title: String in licenses:
		file.store_string(title + "\n" + str(licenses[title]) + "\n\n")
	file.store_string(FileAccess.get_file_as_string("res://assets/audio/voices/NOTICE.txt"))
	file.close()
	quit()
