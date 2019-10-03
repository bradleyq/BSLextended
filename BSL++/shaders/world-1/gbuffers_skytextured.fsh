#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define SkyboxBrightness 2.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define SkyDesaturation

varying vec2 texcoord;

varying vec4 color;

uniform sampler2D texture;

#include "lib/color/lightColor.glsl"
#include "lib/color/lightColorDynamic.glsl"

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord.xy) * color;
	
	//Convert to linear color space
	albedo.rgb = pow(albedo.rgb,vec3(2.2)) * SkyboxBrightness * albedo.a;
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}