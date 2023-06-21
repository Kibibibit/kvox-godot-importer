@tool
extends EditorImportPlugin

const _file_header = "KVOX"


func _get_preset_count():
	return 0

func _get_preset_name(preset_index):
	return "Unknown"

## No options so the presets array is empty
func _get_import_options(path, preset_index):
	return []

## No options so all visible
func _get_option_visibility(path, option_name, options):
	return false

func _get_importer_name():
	return "kibi.kvox"

func _get_visible_name():
	return "VoxelMesh"

func _get_recognized_extensions():
	return ["kvox"]

func _get_priority():
	return 1.0

func _get_import_order():
	return 0

func _get_save_extension():
	return "tres"

func _get_resource_type():
	return "Mesh"

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	
	## Check the header is valid
	for letter in _file_header:
		var byte = PackedByteArray([file.get_8()]).get_string_from_ascii()
		assert(byte == letter, "Malformed header in %s" % source_file)
	
	## Get the dimensions of the model
	var width: int = file.get_16()
	var height: int = file.get_16()
	var depth: int = file.get_16()
	
	var color_depth: int = file.get_8()
	
	var materials: Array[VoxelMaterial] = []
	
	for c in range(color_depth):
		var r = file.get_8()
		var g = file.get_8()
		var b = file.get_8()
		var metallic = file.get_8()
		var roughness = file.get_8()
		var material = VoxelMaterial.new()
		material.create_from_bytes(r,g,b,metallic,roughness)
		materials.append(material)
	
	
	
	var data: Array[Array] = []
	
	for x in range(width):
		var slice_vert: Array[Array] = []
		for y in range(height):
			var slice_hori: Array[int] = []
			for z in range(depth):
				slice_hori.append(file.get_8())
			slice_vert.append(slice_hori)
		data.append(slice_vert)
	file.close()
		
	var mesh: VoxelMesh = VoxelMesh.new()
	mesh.create(
		Vector3i(width,height,depth),
		data,
		materials
	)
	
	return ResourceSaver.save(mesh, "%s.%s" % [save_path, _get_save_extension()])
