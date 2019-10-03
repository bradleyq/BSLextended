#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]
#define AO
//#define BumpyEdge
#define Clouds
#define EmissiveRecolor
#define Fog
#define FogRange 8 //[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 18 20 22 24 26 28 30 32 36 40 44 48 52 56 60 64]
//#define ReflectionPrevious
//#define RPSupport
#define RPSFormat 0 //[0 1 2 3]
#define RPSReflection

//#define WorldTimeAnimation
#define AnimationSpeed 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00 5.00 6.00 7.00 8.00]

varying vec3 upVec;
varying vec3 sunVec;

varying vec2 texcoord;

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float aspectRatio;
uniform float blindness;
uniform float far;
uniform float frameTimeCounter;
uniform float near;
uniform float nightVision;
uniform float rainStrength;
uniform float wetness;
uniform float shadowFade;
uniform float timeAngle;
uniform float timeBrightness;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;
float moonVisibility = clamp(dot(-sunVec,upVec)+0.05,0.0,0.1)/0.1;

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float ld(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

#include "lib/color/lightColor.glsl"
#include "lib/color/lightColorDynamic.glsl"
#include "lib/color/skyColor.glsl"
#include "lib/color/torchColor.glsl"
#include "lib/color/waterColor.glsl"
#include "lib/common/ambientOcclusion.glsl"
#include "lib/common/clouds.glsl"
#include "lib/common/dither.glsl"
#include "lib/common/fog.glsl"
#include "lib/common/sky.glsl"

void main(){
	vec4 color = texture2D(colortex0,texcoord.xy);
	float z = texture2D(depthtex0,texcoord.xy).r;
	
	//Dither
	float dither = bayer64(gl_FragCoord.xy);
	
	//NDC Coordinate
	vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;
	
	if (z < 1.0){
		//Ambient Occlusion
		#ifdef AO
		color.rgb *= dbao(depthtex0, dither);
		#endif
		
		//Fog
		#ifdef Fog
		// color.rgb = calcFog(color.rgb, fragpos.xyz, blindness);
		#endif
	}else{
		//Lava Fog
		if (isEyeInWater == 2){
			#ifdef EmissiveRecolor
			color.rgb = pow(Torch/TorchS,vec3(4.0))*2.0;
			#else
			color.rgb = vec3(1.0,0.3,0.01);
			#endif
		}

		//Blindness
		float b = clamp(blindness*2.0-1.0,0.0,1.0);
		b = b*b;
		if (blindness > 0.0) color.rgb *= 1.0-b;
	}

	//Bumpy Edge
	#ifdef BumpyEdge
	color.rgb *= bumpyedge(depthtex0);
	#endif
	
/*DRAWBUFFERS:04*/
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(z,0.0,0.0,0.0);
	#ifndef ReflectionPrevious
/*DRAWBUFFERS:045*/
	gl_FragData[2] = vec4(pow(color.rgb,vec3(0.125))*0.5,float(z < 1.0));
	#endif
}
