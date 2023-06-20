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

const _tris = [
	Vector3(2,1,0),
	Vector3(1,2,3),
	Vector3(0,1,4),
	Vector3(5,4,1),
	Vector3(4,6,2),
	Vector3(0,4,2),
	Vector3(5,7,6),
	Vector3(4,5,6),
	Vector3(5,1,3),
	Vector3(3,7,5),
	Vector3(6,7,3),
	Vector3(3,2,6)
]

func _init(_size: Vector3i = Vector3i(1,1,1), data = [[[1]]]):
	mesh_data = data
	size = _size
	remesh()

func remesh():
	var mapping_dict = {
		
	}
	var tris = []
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var point = 0
	
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				if (mesh_data[x][y][z] != 0):
					var i: float = 0
					for p in _points:
						var vert: Vector3 = p+Vector3(x,y,z)
						var index = verts.find(vert)
						if (index == -1):
							verts.append(vert)
							normals.append(vert.normalized())
							index = verts.size()-1
						mapping_dict[point+i] = index
						i+=1
					for tri in _tris:
						var p1 = mapping_dict[point+tri.x]
						var p2 = mapping_dict[point+tri.y]
						var p3 = mapping_dict[point+tri.z]
						var t =   Vector3(p1, p2, p3)
						var ts = [
							t,
							Vector3(p2, p1, p3),
							Vector3(p1, p3, p2), 
							Vector3(p2, p3, p1), 
							Vector3(p3, p1, p2),
							Vector3(p3,p2, p1),
							]
						var include = true
						for _t in ts:
							if (tris.find(_t) != -1):
								include = false
								break
						if (include):
							tris.append(t)
							
					point += _points.size()
	for tri in tris:
		indices.append_array([tri.x, tri.y, tri.z])
	print(verts.size())
	print(indices.size()/3)
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
