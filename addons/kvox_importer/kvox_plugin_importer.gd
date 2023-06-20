@tool
extends EditorPlugin

var import_plugin

func _enter_tree():
	add_custom_type("VoxelMesh", "ArrayMesh", preload("voxel_mesh.gd"),preload("icon.png"))
	import_plugin = preload("kvox_importer.gd").new()
	add_import_plugin(import_plugin)


func _exit_tree():
	remove_import_plugin(import_plugin)
	import_plugin = null
