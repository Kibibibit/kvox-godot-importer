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
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()

	## Check the header is valid
	for byte in _header:
		assert(byte == file.get_8(), "Malformed header in %s" % source_file)
	
	var version: int
	var width: int
	var height: int 
	var depth: int
	var material_count: int
	var data_layout: int
	var materials: Array[VoxelMaterial] = []
	var voxel_bytes: Array[int] = []
	
	while(file.get_position() < file.get_length()):
		var chunk_type = _get_chunk_type(file)
		
		if (chunk_type == _meta_chunk_type):
			version = file.get_8()
			assert(version == 1, "This is a kvox v%s file, which is not yet supported" % version)
			width = file.get_16()
			height = file.get_16()
			depth = file.get_16()
			material_count = file.get_8()
			data_layout = file.get_8()
			_end_chunk(file)
			continue
		elif (chunk_type == _material_chunk_type):
			var index = file.get_8()
			assert(index > 0 && index <= material_count, "Material not valid!")
			var r = file.get_8()
			var g = file.get_8()
			var b = file.get_8()
			var metallic = file.get_8()
			var roughness = file.get_8()
			var emission = file.get_8()
			
			var material = VoxelMaterial.new()
			material.create_from_bytes(
				r,g,b,
				metallic,
				roughness,
				emission
			)
			materials.append(material)
			_end_chunk(file)
			continue
		elif(chunk_type == _voxel_chunk_type):
			
			var voxel_count = file.get_32()
			for v in range(voxel_count):
				voxel_bytes.append(file.get_8())
				assert(file.get_position() < file.get_length(), "WENT OFF THE END!")
					
			_end_chunk(file)
		
	file.close()
	var data: Array[Array] = []
	
	for x in range(width):
		var slice_vert: Array[Array] = []
		for y in range(height):
			var slice_hori: Array[int] = []
			for z in range(depth):
				slice_hori.append(0)
			slice_vert.append(slice_hori)
		data.append(slice_vert)
				
	
	var compression = data_layout & 0b1000000 > 0
	if (compression):
		var uncompressed_voxel_bytes: Array[int] = []
		for i in range(voxel_bytes.size()/2):
			var count = voxel_bytes[2*i]
			var value = voxel_bytes[2*i+1]
			for c in range(count):
				uncompressed_voxel_bytes.append(value)
		voxel_bytes = uncompressed_voxel_bytes
	
	var all_zeros: bool = true
	
	var a_flag:int = (data_layout & 0b00110000) >> 4
	var b_flag:int = (data_layout & 0b00001100) >> 2
	var c_flag:int = (data_layout & 0b00000011)
	var flag_mapping = {
		_x_flag:width,
		_y_flag:height,
		_z_flag:depth
	}
	var i = 0
	for a in range(flag_mapping[a_flag]):
		for b in range(flag_mapping[b_flag]):
			for c in range(flag_mapping[c_flag]):
				var pos: Vector3i = _get_pos(a,b,c,a_flag,b_flag,c_flag)
				var byte = voxel_bytes[i]
				if (byte != 0):
					all_zeros = false
				data[pos.x][pos.y][pos.z] = byte
				i+=1
	
	
	assert(!all_zeros, "Mesh has no voxels!")
	var mesh: VoxelMesh = VoxelMesh.new()
	mesh.create(Vector3i(width,height,depth),
		data,
		materials
	)
	
	return ResourceSaver.save(mesh, "%s.%s" % [save_path, _get_save_extension()])


func _get_chunk_type(file:FileAccess) -> int:
	for byte in _chunk_header:
		assert(file.get_8() == byte, "Malformed chunk header!")
	var chunk_type = [file.get_8(), file.get_8(), file.get_8(), file.get_8()]
	var out = -1
	if (chunk_type == _meta_chunk_header):
		out = _meta_chunk_type
	elif (chunk_type == _material_chunk_header):
		out = _material_chunk_type
	elif (chunk_type == _voxel_chunk_header):
		out = _voxel_chunk_type
	assert(out != -1, "Unrecognised chunk!")
	return out

func _end_chunk(file: FileAccess):
	for byte in _chunk_end:
		assert(file.get_8() == byte, "Chunk did not end when expected!")
	
func _get_flag(a,b,c,a_flag,b_flag,c_flag,dim):
	if (a_flag == dim):
		return a
	elif (b_flag == dim):
		return b
	elif (c_flag == dim):
		return c

func _get_pos(a,b,c,a_flag,b_flag,c_flag):
	var x = _get_flag(a,b,c,a_flag,b_flag,c_flag,_x_flag)
	var y = _get_flag(a,b,c,a_flag,b_flag,c_flag,_y_flag)
	var z = _get_flag(a,b,c,a_flag,b_flag,c_flag,_z_flag)
	return Vector3i(x,y,z)
