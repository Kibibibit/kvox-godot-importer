extends Resource
class_name VoxelMaterial

@export
var color: Color
@export_range(0,255)
var metallic: int
@export_range(0,255)
var roughness: int
@export_range(0,255)
var emission_energy: int

## Takes in raw bytes for each field and converts them to the relevant datatypes
func create_from_bytes(r:int, g:int, b:int, metal:int, rough:int, emission:int) -> void:
	color = Color8(r,g,b)
	metallic = metal
	roughness = rough
	emission_energy = emission

func metal_color() -> Color:
	return Color8(metallic,0,0)

func rough_color() -> Color:
	return Color8(roughness, 0,0)

func to_standard_material():
	var out: StandardMaterial3D = StandardMaterial3D.new()
	out.albedo_color = color
	out.metallic = metallic/255.0
	out.roughness = roughness/255.0
	out.emission_enabled = true
	out.emission_energy_multiplier = 3.33
	var e: float = emission_energy/255.0
	out.emission = Color(
			color.r*e,
			color.g*e,
			color.b*e
		)
	return out

