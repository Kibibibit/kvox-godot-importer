extends ArrayMesh
class_name VoxelMesh

@export var size: Vector3i
@export var scale: Vector3 = Vector3(1,1,1)

var mesh_data

const _points = [
	Vector3(0,0,0), #0
	Vector3(0,0,1), #1
	Vector3(0,1,0), #2
	Vector3(0,1,1), #3
	Vector3(1,0,0), #4
	Vector3(1,0,1), #5
	Vector3(1,1,0), #6
	Vector3(1,1,1), #7
]

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

func _init(_size: Vector3i = Vector3i(1,1,1), data = [[[1]]]):
	mesh_data = data
	size = _size
	remesh()

func remesh():
	var tris = []
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	var count = 0
	var now = Time.get_ticks_usec()
	
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				if (mesh_data[x][y][z] != 0):
					count += 1
					for k in _dirs.keys():
						var dir = _dirs[k]
						var x_off = x+dir.x
						var y_off = y+dir.y
						var z_off = z+dir.z
						var empty_space = false
						if (
							x_off < 0 || 
							x_off >= size.x ||
							y_off < 0 ||
							y_off >= size.y ||
							z_off < 0 ||
							z_off >= size.z
						):
							empty_space = true
						else:
							empty_space = mesh_data[x_off][y_off][z_off] == 0
						if (empty_space):
							var i = verts.size()
							for v in _verts[k]:
								var vert: Vector3 = v+Vector3(x,y,z)
								verts.append(vert)
								normals.append(vert.normalized())
							indices.append_array([
								i+0,
								i+1,
								i+2,
								i+3,
								i+2,
								i+1
							])
						
	for tri in tris:
		indices.append_array([tri.x, tri.y, tri.z])
	var vert_count = verts.size()
	var tri_count = indices.size()/3
	var face_count = tri_count/2
	var verts_per_vox = vert_count/count as float
	var tris_per_vox = tri_count/count as float
	var faces_per_vox = face_count/count as float
	print("=====")
	print("For %s voxels" % count)
	print("%s\tVertices\t(%s per vox)" % [vert_count,verts_per_vox])
	print("%s\tTris\t\t(%s per vox)"% [tri_count, tris_per_vox])
	print("%s\tFaces\t\t(%s per vox)" % [face_count, faces_per_vox])
	print("Meshed in %sms" % ((Time.get_ticks_usec() - now)/1000.0))
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
