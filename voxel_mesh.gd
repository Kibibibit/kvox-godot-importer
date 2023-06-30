extends ArrayMesh
class_name VoxelMesh

const header = [0x4B, 0x56, 0x4F, 0x58, 0x0D, 0x0A, 0x0A]
const chunk_header = [0x43, 0x48, 0x4E, 0x4B]
const chunk_end = [0x45, 0x4E, 0x44, 0x43]
const meta_chunk_header = [0x4D, 0x45, 0x54, 0x41]
const material_chunk_header = [0x4D, 0x41, 0x54, 0x52]
const voxel_chunk_header = [0x56, 0x4F, 0x58, 0x53]
const _meta_chunk_type = 0
const _material_chunk_type = 1
const _voxel_chunk_type = 2
const x_flag = 0b00
const y_flag = 0b01
const z_flag = 0b10

## The size of the model, in voxels
@export var _size: Vector3i = Vector3i(0,0,0)

## Each material that this model uses
@export var _materials: Array[VoxelMaterial] = []

@export var _emission_energy: float = 3.33

@export_group("Raw data")
## Has this model been created with VoxelMesh.create()?
@export var _created: bool = false
## Stores the raw voxel mesh data
@export var _mesh_data: Array[Array] = []

@export var _material: StandardMaterial3D

enum Faces {X, NEG_X, Y, NEG_Y, Z, NEG_Z}

const _dirs = {
	Faces.X:Vector3(1,0,0),
	Faces.Y:Vector3(0,1,0),
	Faces.Z:Vector3(0,0,1),
	Faces.NEG_X:Vector3(-1,0,0),
	Faces.NEG_Y:Vector3(0,-1,0),
	Faces.NEG_Z:Vector3(0,0,-1),
}

const _verts = {
	Faces.X:[Vector3(1,0,0), Vector3(1,0,1), Vector3(1,1,0), Vector3(1,1,1)],
	Faces.NEG_X:[Vector3(0,1,1), Vector3(0,0,1),Vector3(0,1,0), Vector3(0,0,0)],
	Faces.Y:[Vector3(0,1,0), Vector3(1,1,0), Vector3(0,1,1), Vector3(1,1,1)],
	Faces.NEG_Y:[Vector3(1,0,1), Vector3(1,0,0), Vector3(0,0,1), Vector3(0,0,0)],
	Faces.Z:[Vector3(0,0,1), Vector3(0,1,1), Vector3(1,0,1), Vector3(1,1,1)],
	Faces.NEG_Z:[Vector3(1,1,0), Vector3(0,1,0), Vector3(1,0,0), Vector3(0,0,0)],
}
const _uvs = [Vector2(0.8,0.8), Vector2(0.2,0.8),Vector2(0.2,0.8),Vector2(0.2,0.8)]

const _index_offsets = [0,1,2,3,2,1]

const _compare_mode_lt = 0
const _compare_mode_geq = 1

func _compare_values(mode:int, a, b):
	match mode:
		_compare_mode_lt:
			return a < b
		_compare_mode_geq:
			return a >= b
		_:
			return a == b

func _compare_vectors(mode: int, a:Vector3, b:Vector3):
	return (
		_compare_values(mode, a.x, b.x) || 
		_compare_values(mode, a.y, b.y) ||
		_compare_values(mode, a.z, b.z)
	)

func _vector_in_range(x:Vector3, _min:Vector3, _max:Vector3):
	return (
		!_compare_vectors(_compare_mode_lt, x, _min) &&
		!_compare_vectors(_compare_mode_geq, x, _max)
	)


func _can_draw_face(direction: Faces, point: Vector3):
	var dir: Vector3 = _dirs[direction]
	var off = dir+point
	if (!_vector_in_range(off, Vector3(0,0,0), _size)):
		return true
	else:
		return _mesh_data[off.x][off.y][off.z] == 0


func _draw_face(
	direction: Faces, 
	point: Vector3, 
	material_index: int,
	verts: PackedVector3Array,
	uvs:PackedVector2Array,
	normals:PackedVector3Array,
	indices:PackedInt32Array
):
	var index = verts.size()
	var directions = _verts[direction]
	for d in range(directions.size()):
		### Adding the vertex
		var v = directions[d]
		var vert: Vector3 = v+point
		verts.append(vert)
		normals.append(vert.normalized())
		
		### Adding the UVs
		var uv = _uvs[d]
		uv.x += material_index
		uv.x /= _materials.size()
		uvs.append(uv)
		
	for offset in _index_offsets:
		indices.append(index+offset)
		
func _draw_voxel(
		point: Vector3, 
		material_index: int,
		verts: PackedVector3Array,
		uvs:PackedVector2Array,
		normals:PackedVector3Array,
		indices:PackedInt32Array
	):
		for direction in _dirs.keys():
			if (_can_draw_face(direction,point)):
				_draw_face(direction, point, material_index,verts, uvs, normals, indices)

func voxel_at(pos: Vector3i) -> int:
	if (_vector_in_range(pos, Vector3(0,0,0),_size)):
		return _mesh_data[pos.x][pos.y][pos.z]
	return -1

func get_size():
	return Vector3(_size)

func create(size: Vector3i, mesh_data: Array[Array], materials:Array[VoxelMaterial]) -> void:
	_size = size
	_mesh_data = mesh_data
	_created = true
	_materials = materials
	_generate_textures()
	remesh()
	



func remesh() -> void:
	assert(_created, "Call VoxelMesh.create() before trying to remesh!")
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	for x in range(_size.x):
		for y in range(_size.y):
			for z in range(_size.z):
				var material_index = _mesh_data[x][y][z]-1
				if (material_index != -1):
					_draw_voxel(Vector3(x,y,z), material_index, verts, uvs, normals, indices)
		
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	if (get_surface_count() > 0):
		clear_surfaces()
	if (verts.size() > 0):
		add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
		surface_set_material(0, _material)


func _generate_textures():
	var albedo_img: Image = Image.new().create(_materials.size(), 1, false, Image.FORMAT_RGB8)
	var metallic_img: Image = Image.new().create(_materials.size(), 1, false, Image.FORMAT_RGB8)
	var roughness_img: Image = Image.new().create(_materials.size(), 1, false, Image.FORMAT_RGB8)
	var emission_img: Image = Image.new().create(_materials.size(), 1, false, Image.FORMAT_RGB8)
	for x in range(_materials.size()):
		albedo_img.set_pixel(x,0,_materials[x].color)
		metallic_img.set_pixel(x,0,_materials[x].metal_color())
		roughness_img.set_pixel(x,0,_materials[x].rough_color())
		
		emission_img.set_pixel(x,0,
		Color(
			_materials[x].color.r*_materials[x].emission_energy,
			_materials[x].color.g*_materials[x].emission_energy,
			_materials[x].color.b*_materials[x].emission_energy
		)
		)
	_material = StandardMaterial3D.new()
	
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material.albedo_texture = ImageTexture.create_from_image(albedo_img)
	_material.metallic_texture = ImageTexture.create_from_image(metallic_img)
	_material.roughness_texture = ImageTexture.create_from_image(roughness_img)
	_material.emission_texture = ImageTexture.create_from_image(emission_img)
	
	_material.emission_enabled = true
	_material.emission_energy_multiplier = 3.33




static func load_from_file(path:String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()

	## Check the header is valid
	for byte in header:
		assert(byte == file.get_8(), "Malformed header in %s" % path)
	
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
		x_flag:width,
		y_flag:height,
		z_flag:depth
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
	return mesh

static func _get_chunk_type(file:FileAccess) -> int:
	for byte in chunk_header:
		assert(file.get_8() == byte, "Malformed chunk header!")
	var chunk_type = [file.get_8(), file.get_8(), file.get_8(), file.get_8()]
	var out = -1
	if (chunk_type == meta_chunk_header):
		out = _meta_chunk_type
	elif (chunk_type == material_chunk_header):
		out = _material_chunk_type
	elif (chunk_type == voxel_chunk_header):
		out = _voxel_chunk_type
	assert(out != -1, "Unrecognised chunk!")
	return out

static func _end_chunk(file: FileAccess):
	for byte in chunk_end:
		assert(file.get_8() == byte, "Chunk did not end when expected!")
	
static func _get_flag(a,b,c,a_flag,b_flag,c_flag,dim):
	if (a_flag == dim):
		return a
	elif (b_flag == dim):
		return b
	elif (c_flag == dim):
		return c

static func _get_pos(a,b,c,a_flag,b_flag,c_flag):
	var x = _get_flag(a,b,c,a_flag,b_flag,c_flag,x_flag)
	var y = _get_flag(a,b,c,a_flag,b_flag,c_flag,y_flag)
	var z = _get_flag(a,b,c,a_flag,b_flag,c_flag,z_flag)
	return Vector3i(x,y,z)
