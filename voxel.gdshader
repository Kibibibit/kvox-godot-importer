shader_type spatial;

uniform sampler3D data;

void vertex() {
	
}

void fragment() {
	ALBEDO = texture(data, vec3(0,0,0)).rgb;
	ALPHA = texture(data, vec3(0,0,0)).a;
	
}
