shader_type canvas_item;

uniform vec4 picker_color;

void fragment(){
	vec3 hue = picker_color.rgb;
	hue.r = hue.r + ((1.0 - hue.r) / 1.0) * (1.0 - UV.x);
	hue.g = hue.g + ((1.0 - hue.g) / 1.0) * (1.0 - UV.x);
	hue.b = hue.b + ((1.0 - hue.b) / 1.0) * (1.0 - UV.x);
	hue = hue * (1.0 - UV.y);
	COLOR = vec4(hue, 1.0);
	}