extends Resource
class_name VoxelMaterial

var color: Color
var metallic: float
var roughness: float

## Takes in raw bytes for each field and converts them to the relevant datatypes
func create_from_bytes(r:int, g:int, b:int, metal:int, rough:int) -> void:
	color = Color(r/255.0, g/255.0, b/255.0)
	metallic = metal/255.0
	roughness = rough/255.0

func metal_color() -> Color:
	return Color(metallic,metallic,metallic)

func rough_color() -> Color:
	return Color(roughness, roughness, roughness)
