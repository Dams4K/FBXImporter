@tool
extends Control
class_name InspectorContainer

var inspector: EditorInspector

@export_file("*.gd") var object_path : set = set_object_path
var object: Object

func _ready() -> void:
	inspector = EditorInspector.new()
	if inspector == null:
		return
	
	add_child(inspector)
	inspector.set_anchors_preset(Control.PRESET_FULL_RECT)
	set_object_path(object_path)
	
	if object != null:
		object.notify_property_list_changed()

func set_object_path(value) -> void:
	object_path = value
	if object_path != null:
		object = load(object_path).new()
	if inspector != null:
		inspector.edit(object)
