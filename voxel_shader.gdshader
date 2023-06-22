shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;


// Varyings
varying float roughness;
varying float metallic;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform sampler2D roughness_texture : filter_nearest;
uniform sampler2D metallic_texture: filter_nearest;
uniform sampler2D emission_texture: filter_nearest;


void vertex() {
	roughness=texture(roughness_texture, UV).r;
	ROUGHNESS = roughness;
	COLOR.rgb = texture(albedo_texture, UV).xyz;
	metallic = texture(metallic_texture, UV).x;
}

void fragment() {
	ALBEDO = COLOR.xyz;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	EMISSION = ALBEDO*(texture(emission_texture,UV).x*2.0);
}
