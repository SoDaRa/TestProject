shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float color_to_out_border = 0.485;
uniform float outer_black_boundry = 0.489;
uniform float inner_black_boundry = 0.405;
uniform float color_to_in_border = 0.415;
void fragment()
{
	vec2 relative_pos = UV - center;					// Figure out position relative to the center
	if (length(relative_pos) < 0.4 || length(relative_pos) > 0.5) {discard;} // Bounds of ring
	if (length(relative_pos) > inner_black_boundry && length(relative_pos) < outer_black_boundry) // Inner ring
	{
		float red, green, blue;	//Our RGB values
		float relative_angle = degrees(atan(relative_pos.y, relative_pos.x));// Get the angle relative to the x-axis
		if (relative_angle < 0.0) { relative_angle += 360.0;}				 // Make the angle positive
		
		//Hue calculation
		float hue = relative_angle / 360.0;						// Start our hue as a value between 0 and 1
		
		hue *= 6.0;						// Whole number determines case, fractional part determines ratio
		int my_case = int(floor(hue)); 
		float inc_ratio = fract(hue); 		// increasing ratio - When a value is ascending to 1.0
		float dec_ratio = 1.0 - inc_ratio; 	// decreasing ratio - When a value is descending to 0.0
		if (my_case == 0) // Red > Green > Blue - 0 to 60 (degrees)
		{
			red = 1.0;
			green = inc_ratio;
			blue = 0.0;
		}
		else if(my_case == 1) // Green > Red > Blue - 60 to 120
		{
			red = dec_ratio;
			green = 1.0;
			blue = 0.0;
		}
		else if(my_case == 2) // Green > Blue > Red - 120 to 180
		{
			red = 0.0;
			green = 1.0;
			blue = inc_ratio;
		}
		else if(my_case == 3) // Blue > Green > Red - 180 to 240
		{
			red = 0.0;
			green = dec_ratio;
			blue = 1.0;
		}
		else if(my_case == 4) // Blue > Red > Green - 240 to 300
		{
			red = inc_ratio;
			green = 0.0;
			blue = 1.0;
		}
		else // Red > Blue > Green - 300 to 360
		{
			red = 1.0;
			green = 0.0;
			blue = dec_ratio;
		}
		COLOR = vec4(red, green, blue, 1.0);
	}
	// Outer Border
	else if (length(relative_pos) >= outer_black_boundry && length(relative_pos) < 0.5) 
	{
		float my_length = length(relative_pos) - outer_black_boundry;
		float fade_out_coeff = 1.0 - my_length / (0.5 - outer_black_boundry);
		COLOR = vec4(0.0,0.0,0.0, fade_out_coeff);
	}
	// Inner Border
	else if (length(relative_pos) <= inner_black_boundry && length(relative_pos) > 0.4) 
	{
		float my_length = length(relative_pos) - inner_black_boundry;
		float fade_out_coeff = 1.0 - my_length / (0.4 - inner_black_boundry);
		COLOR = vec4(0.0,0.0,0.0, fade_out_coeff);
	}
	// Transition into outer border
	if (length(relative_pos) >= color_to_out_border && length(relative_pos) < outer_black_boundry) 
	{
		float my_length = length(relative_pos) - color_to_out_border;
		float fade_color_coeff = my_length / (outer_black_boundry - color_to_out_border);
		COLOR = mix(COLOR, vec4(0.0,0.0,0.0,1.0), fade_color_coeff);
	}
	// Transition into inner border
	else if (length(relative_pos) <= color_to_in_border && length(relative_pos) > inner_black_boundry) 
	{
		float my_length = length(relative_pos) - color_to_in_border;
		float fade_color_coeff = my_length / (inner_black_boundry - color_to_in_border);
		COLOR = mix(COLOR, vec4(0.0,0.0,0.0,1.0), fade_color_coeff);
	}
	
}