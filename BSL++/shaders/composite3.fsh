#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

//#define DOF

const bool colortex0MipmapEnabled = true;

varying vec2 texcoord;

uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float centerDepthSmooth;

uniform sampler2D colortex0;
uniform sampler2D depthtex1;

#include "lib/common/dither.glsl"
#include "lib/post/depthOfField.glsl"

void main(){
	vec3 color = texture2D(colortex0,texcoord.xy).rgb;
	
	//Depth of Field
	#ifdef DOF
	color = depthOfField(color);
	#endif
	
	
/*DRAWBUFFERS:0*/
	gl_FragData[0] = vec4(color,1.0);
}
