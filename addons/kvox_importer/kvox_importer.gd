@tool
extends EditorImportPlugin



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
		
	var color_depth: int = file.get_8()
	
	var colors = []
	
	for c in range(color_depth):
		var b = file.get_8()
		var g = file.get_8()
		var r = file.get_8()
		colors.append(Color(r/255.0,g/255.0,b/255.0))
	
	var width: int = file.get_16()
	var height: int = file.get_16()
	var depth: int = file.get_16()
	
	var data = []
	
	for x in range(width):
		var slice_vert = []
		for y in range(height):
			var slice_hori = []
			for z in range(depth):
				slice_hori.append(file.get_8())
			slice_vert.append(slice_hori)
		data.append(slice_vert)
	file.close()
		
	var mesh: VoxelMesh = VoxelMesh.new(
		Vector3i(width,height,depth),
		data,
		colors
	)
	
	return ResourceSaver.save(mesh, "%s.%s" % [save_path, _get_save_extension()])
