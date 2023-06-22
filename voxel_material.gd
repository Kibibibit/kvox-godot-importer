extends Resource
class_name VoxelMaterial

@export
var color: Color
@export_range(0,1.0)
var metallic: float
@export_range(0,1.0)
var roughness: float
@export
var emission_energy: float

## Takes in raw bytes for each field and converts them to the relevant datatypes
func create_from_bytes(r:int, g:int, b:int, metal:int, rough:int, emission:int) -> void:
	color = Color(r/255.0, g/255.0, b/255.0)
	metallic = metal/255.0
	roughness = rough/255.0
	emission_energy = emission/255.0

func metal_color() -> Color:
	return Color(metallic,metallic,metallic)

func rough_color() -> Color:
	return Color(roughness, roughness, roughness)

func emission_energy_color() -> Color:
	return Color(emission_energy, emission_energy, emission_energy)


