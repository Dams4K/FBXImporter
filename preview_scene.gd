@tool
extends Node3D

@export_tool_button("apply") var apply = apply_fct

var scene: Node3D

var rot_x := 0.0
var rot_y := 0.0
var zoom := 1.0

var contents_aabb: AABB

@onready var camera: Camera3D = $Camera3D

func apply_fct():
	pass

func preview_scene(node: Node3D) -> void:
	if scene != null:
		remove_child(scene)
		scene.queue_free()
	scene = node
	
	contents_aabb = calculate_aabb(scene)
	add_child(scene)
	
	rot_x = -PI/4
	rot_y = -PI/4
	zoom = 1
	
	_update_camera()

func save(path: String):
	if scene == null:
		return
	
	add_owner(scene, scene)
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene)
	ResourceSaver.save(packed_scene, path)

func add_owner(s_owner: Node, parent: Node):
	for child in parent.get_children():
		child.owner = s_owner
		add_owner(s_owner, child)

func calculate_aabb(scene: Node3D) -> AABB:
	var mesh_instances: Array[Node] = scene.find_children("*", "MeshInstance3D")
	
	var current_aabb := AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	var first_aabb := true
	
	for instance: MeshInstance3D in mesh_instances:
		if instance.mesh == null:
			continue
		
		var accum_xform := Transform3D()
		var base: Node3D = instance
		while base:
			accum_xform = base.transform * accum_xform
			base = base.get_parent()
		var aabb = accum_xform * instance.mesh.get_aabb()
		if first_aabb:
			current_aabb = aabb
			first_aabb = false
		else:
			current_aabb = current_aabb.merge(aabb)
	
	return current_aabb

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if mouse_motion.button_mask == MOUSE_BUTTON_MASK_LEFT:
			rot_x -= mouse_motion.relative.y * 0.01 * EditorInterface.get_editor_scale()
			rot_y -= mouse_motion.relative.x * 0.01 * EditorInterface.get_editor_scale()
			rot_x = clamp(rot_x, -PI/2, PI/2)
			_update_camera()
	if event as InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = min(zoom * 1.1, 10.0)
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = max(zoom / 1.1, 0.1)
		_update_camera()

func _update_camera():
	var camera_aabb := contents_aabb
	
	var center := camera_aabb.get_center()
	var camera_size = camera_aabb.get_longest_axis_size()
	
	camera.set_orthogonal(camera_size * zoom, 0.0001, camera_size * 2)
	
	var xf = Transform3D(
		Basis(Vector3(0, 1, 0), rot_y) * Basis(Vector3(1, 0, 0), rot_x),
		center
	)
	xf = xf.translated_local(Vector3(0, 0, camera_size))
	camera.transform = xf
