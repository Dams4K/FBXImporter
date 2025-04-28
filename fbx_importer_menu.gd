@tool
extends ConfirmationDialog

@onready var preview_scene: Node3D = %PreviewScene
@onready var preview_viewport: SubViewport = %PreviewViewport

@onready var import_settings_inspector: InspectorContainer = $Control/HBoxContainer/TabContainer/ImportSettingsInspector

@onready var import_settings: ImportSettings

var material_retriever: MaterialRetriever

var current_fbx_path: String = ""

func _ready() -> void:
	hide()
	import_settings = import_settings_inspector.object as ImportSettings
	material_retriever = MaterialRetriever.new(import_settings)
	
	import_settings.want_refresh.connect(_on_want_refresh)

func _on_want_refresh():
	preview(current_fbx_path)

func open(fbx_path: String) -> void:
	if not FileAccess.file_exists(fbx_path):
		push_error("FBX file don't exist")
		return
	current_fbx_path = fbx_path
	preview(fbx_path)
	
	popup_centered_ratio()

func quick_import(fbx_path: String) -> void:
	if not FileAccess.file_exists(fbx_path):
		push_error("FBX file don't exist")
		return
	current_fbx_path = fbx_path
	preview(fbx_path)
	_on_confirmed()

func preview(fbx_path: String) -> void:
	var scene: Node3D = material_retriever.retrieve_for(fbx_path)
	preview_scene.preview_scene(scene)


func _on_confirmed() -> void:
	if current_fbx_path.is_empty():
		return
	
	import_settings.save_config()
	var scene_path = import_settings.save_folder.path_join(current_fbx_path.get_file().replace(current_fbx_path.get_extension(), "tscn"))
	preview_scene.save(scene_path)
