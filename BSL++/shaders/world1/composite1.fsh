#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define LightShaft

const bool colortex1MipmapEnabled = true;

varying vec3 upVec;
varying vec3 sunVec;

varying vec2 texcoord;

uniform int isEyeInWater;
uniform int worldTime;

uniform float blindness;
uniform float rainStrength;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

#include "lib/color/dimensionColor.glsl"

void main(){
	vec4 color = texture2D(colortex0,texcoord.xy);
	
	//Light Shafts
	#ifdef LightShaft
	vec3 vl = texture2DLod(colortex1,texcoord.xy,1.5).rgb;
	
	float b = clamp(blindness*2.0-1.0,0.0,1.0);
	b = b*b;
	
	color.rgb += vl * vl * 0.05 * end_c * (1.0-b);
	//color.rgb = vl * vl;
	#endif
	
/*DRAWBUFFERS:0*/
	gl_FragData[0] = color;
}
