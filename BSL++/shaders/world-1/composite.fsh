#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]
#define AO
//#define BumpyEdge
//#define Celshade
#define Fog
#define FogRange 8 //[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 18 20 22 24 26 28 30 32 36 40 44 48 52 56 60 64]
#define LightShaft
//#define ReflectionPrevious

const bool colortex5Clear = false;

varying vec2 texcoord;

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float aspectRatio;
uniform float blindness;
uniform float far;
uniform float frameTimeCounter;
uniform float near;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

float ld(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

#include "lib/color/waterColor.glsl"
#include "lib/common/ambientOcclusion.glsl"
#include "lib/common/celShading.glsl"
#include "lib/common/dither.glsl"
#include "lib/common/waterFog.glsl"

void main(){
	vec4 color = texture2D(colortex0,texcoord.xy);
	float z = texture2D(depthtex0,texcoord.xy).r;
	float z1 = texture2D(depthtex1,texcoord.xy).r;
	
	//Dither
	#if defined AO || defined LightShaft
	float dither = bayer64(gl_FragCoord.xy);
	#endif
	
	//Ambient Occlusion
	#ifdef AO
	if (z1-z > 0 && ld(z)*far < 32.0){
		vec3 rawtranslucent = texture2D(colortex1,texcoord.xy).rgb;
		if (dot(rawtranslucent,rawtranslucent) < 0.02) color.rgb *= mix(dbao(depthtex0, dither),1.0,clamp(0.03125*ld(z)*far,0.0,1.0));
		}
	#endif
	
	//Underwater fog
	#ifdef Fog
	if (isEyeInWater == 1.0){
		vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0);
		fragpos /= fragpos.w;
		
		//Blindness
		float b = clamp(blindness*2.0-1.0,0.0,1.0);
		b = 1.0-b*b;
		
		color.rgb = calcWaterFog(color.rgb, fragpos.xyz, water_c*b, cmult, wfogrange);
	}
	#endif
	
	//Black Outline
	#ifdef Celshade
	if (celshademask(depthtex0,depthtex1) > 0.5 || isEyeInWater > 0.5) color.rgb *= celshade(depthtex0, 0.0);
	#endif
	
	//Bumpy Edge
	#ifdef BumpyEdge
	if (z1-z > 0) color.rgb *= bumpyedge(depthtex0);
	#endif
	
/*DRAWBUFFERS:0*/
	gl_FragData[0] = color;
	#ifdef ReflectionPrevious
/*DRAWBUFFERS:05*/
	gl_FragData[1] = vec4(pow(color.rgb, vec3(0.125)) * 0.5, float(z < 1.0));
	#endif
}
