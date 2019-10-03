#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define SkyboxBrightness 2.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define SkyDesaturation

varying vec2 texcoord;

varying vec3 upVec;
varying vec3 sunVec;

varying vec4 color;

uniform int isEyeInWater;
uniform int worldTime;

uniform float nightVision;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D texture;

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord.xy);
	
	//Convert to linear color space
	albedo.rgb = pow(albedo.rgb,vec3(2.2)) * SkyboxBrightness * 0.01;
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}