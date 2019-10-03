#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

varying vec3 upVec;
varying vec3 sunVec;

uniform int isEyeInWater;
uniform int worldTime;

uniform float nightVision;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;

void main(){
	
	//Render Sky
	vec3 albedo = vec3(0.0);
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo,1.0);
}