class_name JsonExporter
extends RefCounted

static func export_to_file(path: String, metadata: Dictionary) -> Error:
	var json_string: String = JSON.stringify(metadata, "  ")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(json_string)
	file.close()
	return OK

static func get_json_string(metadata: Dictionary) -> String:
	return JSON.stringify(metadata, "  ")
