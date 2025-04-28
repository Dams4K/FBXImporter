extends Object
class_name MaterialRetriever

enum TextureType {
	ALBEDO,
	METALLIC,
	ROUGHNESS,
	NORMAL,
	AO
}

var import_settings: ImportSettings

func _init(import_settings: ImportSettings) -> void:
	self.import_settings = import_settings

func meshs_use_one_material(mesh_instances: Array) -> bool:
	var number_of_materials := 0
	var first_material: StandardMaterial3D = null
	var same_material := true
	for instance: MeshInstance3D in mesh_instances:
		var mesh: Mesh = instance.mesh
		var surface_count := mesh.get_surface_count()
		for surface_idx in range(surface_count):
			var mat = mesh.surface_get_material(surface_idx)
			if first_material == null:
				first_material = mat
				continue
			if first_material.get_instance_id() != mat.get_instance_id():
				return false
	
	return true

func retrieve_for(fbx_path: String) -> Node3D:
	var packed_scene: PackedScene = load(fbx_path)
	var scene: Node3D = packed_scene.instantiate()
	
	var mis = scene.find_children("*", "MeshInstance3D")
	var mesh_instances: Array = []
	if import_settings.mesh_ignore_begin_with.is_empty():
		mesh_instances = mis
	else:
		for inst: MeshInstance3D in mis:
			if inst == null:
				continue
			if inst.name.begins_with(import_settings.mesh_ignore_begin_with):
				inst.get_parent().remove_child(inst)
				inst.queue_free()
				continue
			mesh_instances.append(inst)
	
	if mesh_instances.size() == 0:
		push_error("No mesh")
		return Node3D.new()
	if mesh_instances.size() == 1:
		retrieve_single_mesh(fbx_path, mesh_instances[0])
	elif meshs_use_one_material(mesh_instances):
		# no need to iterate over each meshs, because it is one material, just one modification is needed
		retrieve_single_mesh_single_mat(fbx_path, mesh_instances[0].mesh.surface_get_material(0))
	
	return scene

func retrieve_single_mesh(fbx_path: String, mesh_instance: MeshInstance3D):
	var mesh: Mesh = mesh_instance.mesh
	# Search in current folder
	if import_settings.search_same_folder:
		if mesh.get_surface_count() == 1:
			retrieve_single_mesh_single_mat(fbx_path, mesh.surface_get_material(0))

func retrieve_single_mesh_single_mat(fbx_path: String, material: StandardMaterial3D):
	if material == null:
		return
	
	var fbx_name: String = fbx_path.get_file().get_basename()
	var fbx_dir: String = fbx_path.get_base_dir()
	var images: PackedStringArray = get_dir_content(fbx_dir, false, is_file_image)
	
	var albedo_texture_path: String = get_image_path_by_fbx_name(fbx_name, TextureType.ALBEDO, images)
	if albedo_texture_path.is_empty():
		if import_settings.is_albedo_critical:
			push_error("albedo_texture_path is empty")
			return
	else:
		var albedo_texture: Texture2D = get_texture(albedo_texture_path)
		material.albedo_texture = albedo_texture
		material.metallic_texture
	
	
	var metallic_texture_path: String = get_image_path_by_fbx_name(fbx_name, TextureType.METALLIC, images)
	if metallic_texture_path.is_empty():
		if import_settings.is_metallic_critical:
			push_error("metallic_texture_path is empty")
			return
	else:
		var metallic_texture: Texture2D = get_texture(metallic_texture_path)
		material.metallic_texture = metallic_texture
		material.metallic_texture_channel = import_settings.metallic_channel
	
	
	var roughness_texture_path: String = get_image_path_by_fbx_name(fbx_name, TextureType.ROUGHNESS, images)
	if roughness_texture_path.is_empty():
		if import_settings.is_metallic_critical:
			push_error("roughness_texture_path is empty")
			return
	else:
		var roughness_texture: Texture2D = get_texture(roughness_texture_path)
		material.roughness_texture = roughness_texture
		material.roughness_texture_channel = import_settings.roughness_channel
	
	
	var normal_texture_path: String = get_image_path_by_fbx_name(fbx_name, TextureType.NORMAL, images)
	if normal_texture_path.is_empty():
		if import_settings.is_normal_critical:
			push_error("normal_texture_path is empty")
			return
	else:
		var normal_texture: Texture2D = get_texture(normal_texture_path)
		material.normal_enabled = normal_texture != null
		material.normal_texture = normal_texture
	
	var ao_texture_path: String = get_image_path_by_fbx_name(fbx_name, TextureType.AO, images)
	if ao_texture_path.is_empty():
		if import_settings.is_ao_critical:
			push_error("ao_texture_path is empty")
			return
	else:
		var ao_texture: Texture2D = get_texture(ao_texture_path)
		material.ao_enabled = ao_texture != null
		material.ao_texture = ao_texture


func get_image_path_by_fbx_name(fbx_name: String, texture_type: TextureType, images: PackedStringArray) -> String:
	var lowered_texture_name = _get_texture_name(texture_type).to_lower()
	var formatted_fbx_name = import_settings.format_fbx_name(fbx_name)
	var lowered_fbx_name = formatted_fbx_name.to_lower()
	
	for path: String in images:
		var lowered_path = path.to_lower()
		if lowered_path.contains(lowered_texture_name) and lowered_path.contains(lowered_fbx_name):
			return path
	return ""

func get_texture(path: String) -> Texture2D:
	return load(path)

func _get_texture_name(texture_type: TextureType) -> String:
	match texture_type:
		TextureType.ALBEDO:
			return import_settings.albedo_name
		TextureType.METALLIC:
			return import_settings.metallic_name
		TextureType.ROUGHNESS:
			return import_settings.roughness_name
		TextureType.NORMAL:
			return import_settings.normal_name
		TextureType.AO:
			return import_settings.ao_name
	return ""

func is_file_image(path: String) -> bool:
	return path.get_extension().to_lower() in import_settings.formats

func get_dir_content(path: String, recursive := false, filter := func(path): true) -> PackedStringArray:
	var dir = DirAccess.open(path)
	var files: PackedStringArray = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var file_path = path.path_join(file_name)
			if dir.current_is_dir() and recursive:
				files.append_array(get_dir_content(file_path))
			elif filter.call(file_path):
				files.append(file_path)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	
	return files
