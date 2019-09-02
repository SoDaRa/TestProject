shader_type canvas_item;

// Colors used for each of the arcs. (Note: Godot 3.1 doesn't have any arrays in it's shader language.)
uniform vec4 color0;
uniform vec4 color1;
uniform vec4 color2;
uniform vec4 color3;
uniform vec4 color4;
uniform vec4 color5;
uniform vec4 color6;
uniform vec4 color7;
uniform vec4 color8;
// How many colors to use. 
uniform int colors_in_use;

uniform vec2 center = vec2(0.5, 0.5);
uniform float min_gradient = 0.025;
uniform float max_gradient = 0.975;

void fragment(){
	vec2 relative_pos = UV - center;						// Figure out position relative to the center
	
	float arc_degrees = 360.0 / float(colors_in_use); 	// Get how large each arc is
	
	float relative_angle = degrees(atan(relative_pos.y, relative_pos.x)); // Get the angle relative to the x-axis
	if (relative_angle < 0.0) { relative_angle += 360.0;}	// Make the angle positive
	relative_angle = 360.0 - relative_angle;				// Flip it upside down
	
	float my_arc = relative_angle / arc_degrees;		// Which arc this fragment falls into
	float mix_low_coeff = 0.5 - (fract(my_arc) / min_gradient) / 2.0;	// coefficent to use approaching previous arc
	float mix_high_coeff = ((fract(my_arc) - max_gradient) / min_gradient) / 2.0;	// coefficent to use if approaching next arc
	if (length(relative_pos) < 0.45)
	{
		if (my_arc >= 0.0 && my_arc <= 1.0)	//Arc 1
		{
			COLOR = color0; // Default
			if (my_arc < min_gradient) // low end of arc
			{
				if (colors_in_use == 2 ) {COLOR = mix(color0, color1, mix_low_coeff);}
				else if (colors_in_use == 3 ) {COLOR = mix(color0, color2, mix_low_coeff);}
				else if (colors_in_use == 4 ) {COLOR = mix(color0, color3, mix_low_coeff);}
				else if (colors_in_use == 5 ) {COLOR = mix(color0, color4, mix_low_coeff);}
				else if (colors_in_use == 6 ) {COLOR = mix(color0, color5, mix_low_coeff);}
				else if (colors_in_use == 7 ) {COLOR = mix(color0, color6, mix_low_coeff);}
				else if (colors_in_use == 8 ) {COLOR = mix(color0, color7, mix_low_coeff);}
				else if (colors_in_use == 9 ) {COLOR = mix(color0, color8, mix_low_coeff);}
			}
			else if (my_arc > max_gradient && colors_in_use > 1) {COLOR = mix(color0, color1, mix_high_coeff);} // high end of arc
		}
		else if (my_arc >= 1.0 && my_arc <= 2.0) //Arc 2
		{
			COLOR = color1;
			if (fract(my_arc) < min_gradient) { COLOR = mix(color1, color0, mix_low_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use == 2) {COLOR = mix(color1, color0, mix_high_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use > 2) {COLOR = mix(color1, color2, mix_high_coeff);}
		}
		else if (my_arc > 2.0 && my_arc <= 3.0) //Arc 3
		{
			COLOR = color2;
			if (fract(my_arc) < min_gradient) { COLOR = mix(color2, color1, mix_low_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use == 3) {COLOR = mix(color2, color0, mix_high_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use > 3) {COLOR = mix(color2, color3, mix_high_coeff);}
		}
		else if (my_arc > 3.0 && my_arc <= 4.0) //Arc 4
		{
			COLOR = color3;
			if (fract(my_arc) < min_gradient) { COLOR = mix(color3, color2, mix_low_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use == 4) {COLOR = mix(color3, color0, mix_high_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use > 4) {COLOR = mix(color3, color4, mix_high_coeff);}
		}
		else if (my_arc > 4.0 && my_arc <= 5.0) //Arc 5
		{
			COLOR = color4;
			if (fract(my_arc) < min_gradient) { COLOR = mix(color4, color3, mix_low_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use == 5) {COLOR = mix(color4, color0, mix_high_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use > 5) {COLOR = mix(color4, color5, mix_high_coeff);}
		}
		else if (my_arc > 5.0 && my_arc <= 6.0) //Arc 6
		{
			COLOR = color5;
			if (fract(my_arc) < min_gradient) { COLOR = mix(color5, color4, mix_low_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use == 6) {COLOR = mix(color5, color0, mix_high_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use > 6) {COLOR = mix(color5, color6, mix_high_coeff);}
		}
		else if (my_arc > 6.0 && my_arc <= 7.0) //Arc 7
		{
			COLOR = color6;
			if (fract(my_arc) < min_gradient) { COLOR = mix(color6, color5, mix_low_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use == 7) {COLOR = mix(color6, color0, mix_high_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use > 7) {COLOR = mix(color6, color7, mix_high_coeff);}
		}
		else if (my_arc > 7.0 && my_arc <= 8.0) //Arc 8
		{
			COLOR = color7;
			if (fract(my_arc) < min_gradient) { COLOR = mix(color7, color6, mix_low_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use == 8) {COLOR = mix(color7, color0, mix_high_coeff);}
			else if (fract(my_arc) > max_gradient && colors_in_use > 8) {COLOR = mix(color7, color8, mix_high_coeff);}
		}
		else if (my_arc > 8.0 && my_arc <= 9.0) //Arc 9
		{
			COLOR = color8;
			if (fract(my_arc) < min_gradient) { COLOR = mix(color8, color7, mix_low_coeff);}
			else if (fract(my_arc) > max_gradient) {COLOR = mix(color8, color0, mix_high_coeff);}
		}
	}
	if (length(relative_pos) < 0.45 && length(relative_pos) > 0.44)
	{
		float my_length = length(relative_pos) - 0.44;
		float fade_color_coeff = my_length / 0.01;
		COLOR = mix(COLOR, vec4(0.0,0.0,0.0,1.0), fade_color_coeff);
	}
	if (length(relative_pos) >= 0.45 && length(relative_pos) < 0.5) 
	{
		float my_length = length(relative_pos) - 0.45;
		float fade_out_coeff = 1.0 - my_length / 0.05;
		COLOR = vec4(0.0,0.0,0.0, fade_out_coeff);
	}
	else if(length(relative_pos) >= 0.5) {discard;}
}