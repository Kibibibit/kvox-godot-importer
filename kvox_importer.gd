@tool
extends EditorImportPlugin

const _header = [0x4B, 0x56, 0x4F, 0x58, 0x0D, 0x0A, 0x0A]
const _chunk_header = [0x43, 0x48, 0x4E, 0x4B]
const _chunk_end = [0x45, 0x4E, 0x44, 0x43]
const _meta_chunk_header = [0x4D, 0x45, 0x54, 0x41]
const _material_chunk_header = [0x4D, 0x41, 0x54, 0x52]
const _voxel_chunk_header = [0x56, 0x4F, 0x58, 0x53]
const _meta_chunk_type = 0
const _material_chunk_type = 1
const _voxel_chunk_type = 2
const _x_flag = 0b00
const _y_flag = 0b01
const _z_flag = 0b10

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
	var mesh: VoxelMesh = VoxelMesh.load_from_file(source_file)
	return ResourceSaver.save(mesh, "%s.%s" % [save_path, _get_save_extension()])

