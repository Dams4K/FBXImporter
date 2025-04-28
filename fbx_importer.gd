@tool
extends EditorPlugin

const ImportButtonFbx = preload("res://addons/fbximporter/import_button_fbx.gd")
const FBX_IMPORTER_MENU = preload("res://addons/fbximporter/fbx_importer_menu.tscn")


var import_button_fbx
var fbx_importer_menu: Window

func _enter_tree() -> void:
	import_button_fbx = ImportButtonFbx.new()
	import_button_fbx.open_importer_menu.connect(_on_open_importer_menu)
	import_button_fbx.quick_import.connect(_on_quick_import)
	
	fbx_importer_menu = FBX_IMPORTER_MENU.instantiate()
	EditorInterface.get_base_control().add_child(fbx_importer_menu)
	
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, import_button_fbx)
	
func _exit_tree() -> void:
	EditorInterface.get_base_control().remove_child(fbx_importer_menu)
	fbx_importer_menu.queue_free()
	remove_context_menu_plugin(import_button_fbx)

func _on_open_importer_menu(fbx_file: String) -> void:
	if fbx_importer_menu == null:
		push_error("fbx_importer_menu is null")
		return
	fbx_importer_menu.open(fbx_file)

func _on_quick_import(fbx_file: String) -> void:
	if fbx_importer_menu == null:
		push_error("fbx_importer_menu is null")
		return
	fbx_importer_menu.quick_import(fbx_file)
