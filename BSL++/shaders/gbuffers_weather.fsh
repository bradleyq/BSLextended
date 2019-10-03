#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define Fog
#define FogRange 8 //[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 18 20 22 24 26 28 30 32 36 40 44 48 52 56 60 64]
#define Weather
#define WeatherOpacity 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 upVec;
varying vec3 sunVec;

uniform int isEyeInWater;
uniform int worldTime;

uniform float nightVision;
uniform float rainStrength;
uniform float wetness;
uniform float timeAngle;
uniform float timeBrightness;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D texture;
uniform sampler2D depthtex0;

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;

vec3 toNDC(vec3 pos){
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = pos * 2. - 1.;
    vec4 fragpos = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragpos.xyz / fragpos.w;
}

#include "lib/color/lightColor.glsl"
#include "lib/color/lightColorDynamic.glsl"
#include "lib/color/torchColor.glsl"

void main(){
	vec4 albedo = vec4(0.0);
	
	#ifdef Weather
	//Texture
	albedo.a = texture2D(texture, texcoord.xy).a;
	
	if (albedo.a > 0.001){
		albedo.rgb = texture2D(texture, texcoord.xy).rgb;
		albedo.a *= rainStrength * length(albedo.rgb/3);
		albedo.rgb = sqrt(albedo.rgb);
		albedo.rgb *= (ambient + lmcoord.x * lmcoord.x * torch_c) * WeatherOpacity;
		
		#ifdef Fog
		if (gl_FragCoord.z > 0.991){
			float z = texture2D(depthtex0,gl_FragCoord.xy/vec2(viewWidth,viewHeight)).r;
			if (z < 1.0){
				vec3 fragpos = toNDC(vec3(gl_FragCoord.xy/vec2(viewWidth,viewHeight),z));
				float fog = length(fragpos)/(FogRange*40.0*(sunVisibility*0.5+1.5))*(0.5*rainStrength+0.5)*eBS;
				fog = 1.0-exp(-2.0*fog*sqrt(fog));
				albedo.rgb /= 1.0-fog;
			}
		} 
		#endif
	}
	#endif
	
/* DRAWBUFFERS:3 */
    gl_FragData[0] = albedo;
    //gl_FragData[1] = albedo;
}