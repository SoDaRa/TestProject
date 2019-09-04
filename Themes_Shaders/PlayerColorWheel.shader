shader_type canvas_item;

// Colors used for each of the slices. (Note: Godot 3.1 doesn't have any arrays in it's shader language. So can only work with a hard coded in amount.)
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

vec4 slice_shading(float my_slice, vec4 slice_color, vec4 prev_color, vec4 next_color)
{
	vec4 new_color;
	float mix_low_coeff = 0.5 - (fract(my_slice) / min_gradient) / 2.0;				// coefficent for mixing when approaching previous slice
	float mix_high_coeff = ((fract(my_slice) - max_gradient) / min_gradient) / 2.0;	// coefficent for mixing when approaching next slice
	
	if (fract(my_slice) < min_gradient) { new_color = mix(slice_color, prev_color, mix_low_coeff);}
	else if (fract(my_slice) > max_gradient) {new_color = mix(slice_color, next_color, mix_high_coeff);}
	else {new_color = slice_color;}
	return new_color;
}

void fragment()
{
	vec2 relative_pos = UV - center;					// Figure out position relative to the center
	
	float slice_degrees = 360.0 / float(colors_in_use); 	// Get how large each slice is
	
	float relative_angle = degrees(atan(relative_pos.y, relative_pos.x)); // Get the angle relative to the x-axis
	if (relative_angle < 0.0) { relative_angle += 360.0;}	// Make the angle positive
	relative_angle = 360.0 - relative_angle;				// Flip it upside down with slice 0 in upper right
	
	float my_slice = relative_angle / slice_degrees;		// Which slice this fragment falls into
	
	if (length(relative_pos) < 0.45)
	{
		if (floor(my_slice) == 0.0)	//Slice 1
		{
			if (colors_in_use == 1) {COLOR = color0;}
			else if(colors_in_use == 2) {COLOR = slice_shading(my_slice, color0, color1, color1);} 
			else if(colors_in_use == 3) {COLOR = slice_shading(my_slice, color0, color2, color1);}
			else if(colors_in_use == 4) {COLOR = slice_shading(my_slice, color0, color3, color1);} 
			else if(colors_in_use == 5) {COLOR = slice_shading(my_slice, color0, color4, color1);} 
			else if(colors_in_use == 6) {COLOR = slice_shading(my_slice, color0, color5, color1);} 
			else if(colors_in_use == 7) {COLOR = slice_shading(my_slice, color0, color6, color1);} 
			else if(colors_in_use == 8) {COLOR = slice_shading(my_slice, color0, color7, color1);} 
			else if(colors_in_use == 9) {COLOR = slice_shading(my_slice, color0, color8, color1);}  
		}
		else if (floor(my_slice) == 1.0) //Slice 2
		{
			if (colors_in_use == 2) {COLOR = slice_shading(my_slice, color1, color0, color0);}
			else if (colors_in_use > 2) {COLOR = slice_shading(my_slice, color1, color0, color2);}
		}
		else if (floor(my_slice) == 2.0) //Slice 3
		{
			if (colors_in_use == 3) {COLOR = slice_shading(my_slice, color2, color1, color0);}
			else if (colors_in_use > 3) {COLOR = slice_shading(my_slice, color2, color1, color3);}
		}
		else if (floor(my_slice) == 3.0) //Slice 4
		{
			if (colors_in_use == 4) {COLOR = slice_shading(my_slice, color3, color2, color0);}
			else if (colors_in_use > 4) {COLOR = slice_shading(my_slice, color3, color2, color4);}
		}
		else if (floor(my_slice) == 4.0) //Slice 5
		{
			if (colors_in_use == 5) {COLOR = slice_shading(my_slice, color4, color3, color0);}
			else if (colors_in_use > 5) {COLOR = slice_shading(my_slice, color4, color3, color5);}
		}
		else if (floor(my_slice) == 5.0) //Slice 6
		{
			if (colors_in_use == 6) {COLOR = slice_shading(my_slice, color5, color4, color0);}
			else if (colors_in_use > 6) {COLOR = slice_shading(my_slice, color5, color4, color6);}
		}
		else if (floor(my_slice) == 6.0) //Slice 7
		{
			if (colors_in_use == 7) {COLOR = slice_shading(my_slice, color6, color5, color0);}
			else if (colors_in_use > 7) {COLOR = slice_shading(my_slice, color6, color5, color7);}
		}
		else if (floor(my_slice) == 7.0) //Slice 8
		{
			if (colors_in_use == 8) {COLOR = slice_shading(my_slice, color7, color6, color0);}
			else if (colors_in_use > 8) {COLOR = slice_shading(my_slice, color7, color6, color8);}
		}
		else if (floor(my_slice) == 8.0) //Slice 9
		{
			COLOR = slice_shading(my_slice, color8, color7, color0);
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

