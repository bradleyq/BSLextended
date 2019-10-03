#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

varying vec2 texcoord;

varying vec3 normal;
varying vec3 upVec;
varying vec3 sunVec;

varying vec4 color;

uniform int isEyeInWater;
uniform int worldTime;

uniform float rainStrength;
uniform float wetness;
uniform float timeAngle;
uniform float timeBrightness;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D texture;

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;
float moonVisibility = clamp(dot(-sunVec,upVec)+0.05,0.0,0.1)/0.1;

#include "lib/color/lightColor.glsl"
#include "lib/color/lightColorDynamic.glsl"

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord.xy);
	
	//Convert to linear color space
	albedo.rgb = pow(albedo.rgb,vec3(2.2));
	
	float quarterNdotU = clamp(0.25 * dot(normal, upVec) + 0.75,0.5,1.0);
	
	albedo.rgb *= light * (quarterNdotU * (0.35 * sunVisibility + 0.15));
	
	albedo.a *= 0.5 * color.a;
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}