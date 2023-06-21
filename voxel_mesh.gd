extends ArrayMesh
class_name VoxelMesh

var _size: Vector3i = Vector3i(0,0,0)
var _created: bool = false
var _albedo_texture: ImageTexture
var _metallic_texture: ImageTexture
var _roughness_texture: ImageTexture

var _mesh_data: Array[Array] = []
var _materials: Array[VoxelMaterial] = []

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
const _uvs = [Vector2(1,1), Vector2(0,1),Vector2(1,0),Vector2(0,0)]

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

func _generate_texture():
	var albedo_img: Image = Image.new().create(_materials.size(), 1, false, Image.FORMAT_RGB8)
	var metallic_img: Image = Image.new().create(_materials.size(), 1, false, Image.FORMAT_R8)
	var roughness_img: Image = Image.new().create(_materials.size(), 1, false, Image.FORMAT_R8)
	for x in range(_materials.size()):
		albedo_img.set_pixel(x,0,_materials[x].color)
		metallic_img.set_pixel(x,0,_materials[x].metal_color())
		roughness_img.set_pixel(x,0,_materials[x].rough_color())
		
	_albedo_texture = ImageTexture.create_from_image(albedo_img)
	_metallic_texture = ImageTexture.create_from_image(metallic_img)
	_roughness_texture = ImageTexture.create_from_image(roughness_img)


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

func create(size: Vector3i, mesh_data: Array[Array], materials: Array[VoxelMaterial]) -> void:
	_size = size
	_mesh_data = mesh_data
	_materials = materials
	_created = true
	_generate_texture()
	remesh()
	_set_material()

func retexture()->void:
	_generate_texture()
	_set_material()

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
	if (get_surface_count() == 0):
		surface_array.resize(Mesh.ARRAY_MAX)
		add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	else:
		surface_array = surface_get_arrays(0)
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_TEX_UV] = uvs


func _set_material():
	var material = StandardMaterial3D.new()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_texture = _albedo_texture
	material.metallic_texture = _metallic_texture
	material.roughness_texture = _roughness_texture
	surface_set_material(0,material)
	
