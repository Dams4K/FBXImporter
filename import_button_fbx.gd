extends EditorContextMenuPlugin

signal open_importer_menu(path: String)
signal quick_import(path: String)

const EXTENSION = "fbx"

func _popup_menu(paths: PackedStringArray) -> void:
	if paths.size() < 0:
		return
	
	if paths.size() == 1:
		for path in paths:
			var ext = path.get_extension()
			if ext.to_lower() != EXTENSION:
				return
		add_context_menu_item("Create Scene", create_scene)
	
	add_context_menu_item("Create Scene (Quick)", create_scene_quick)

func create_scene(files: PackedStringArray) -> void:
	if files.size() < 1:
		push_error("files is empty")
		return
	
	open_importer_menu.emit(files[0])


func create_scene_quick(files: PackedStringArray) -> void:
	for file: String in files:
		var ext = file.get_extension()
		if ext.to_lower() != EXTENSION:
			continue
		
		print("Importing %s" % file)
		quick_import.emit(file)
