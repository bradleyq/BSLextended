#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]
#define AO
//#define BumpyEdge
//#define Celshade
#define Clouds
#define EmissiveRecolor
#define Fog
#define FogRange 8 //[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 18 20 22 24 26 28 30 32 36 40 44 48 52 56 60 64]
#define LightShaft
//#define ReflectionPrevious
//#define RPSupport
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
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

float ld(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

#ifdef RPSupport
const int maxf = 4;				//number of refinements
const float stp = 1.2;			//size of one step for raytracing algorithm
const float ref = 0.25;			//refinement multiplier
const float inc = 2.0;			//increasement factor at each step

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}

vec4 raytrace(vec3 fragpos, vec3 normal, float dither) {
    vec4 color = vec4(0.0);
	#if AA == 2
	dither = fract(dither + frameCounter/8.0);
	#endif
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector * (dither * 0.125 + 0.9375);
    int sr = 0;
	float border = 0.0;
	vec3 pos = vec3(0.0);
    for(int i=0;i<30;i++){
        pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
		if (pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1) break;
		float depth = texture2D(depthtex0,pos.xy).r;
		vec3 spos = vec3(pos.st, depth);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = abs(length(fragpos.xyz-spos.xyz));
		if (err < pow(length(vector)*pow(length(tvector),0.11),1.1)*1.1){

                sr++;
                if (sr >= maxf){
                    break;
                }
				tvector -=vector;
                vector *=ref;
		}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
	
	if (pos.z <1.0-1e-5){
		border = clamp(1.0 - pow(cdist(pos.st), 200.0), 0.0, 1.0);
		color.a = float(texture2D(depthtex0,pos.xy).r < 1.0);
		if (color.a > 0.5) color.rgb = texture2D(colortex0, pos.st).rgb;
		color.rgb = clamp(color.rgb,vec3(0.0),vec3(8.0));
		color.a *= border;
	}
	
    return color;
}
#endif

#include "lib/color/dimensionColor.glsl"
#include "lib/color/torchColor.glsl"
#include "lib/color/waterColor.glsl"
#include "lib/common/ambientOcclusion.glsl"
#include "lib/common/celShading.glsl"
#include "lib/common/dither.glsl"
#include "lib/common/fog.glsl"

void main(){
	vec4 color = texture2D(colortex0,texcoord.xy);
	float z = texture2D(depthtex0,texcoord.xy).r;
	
	//Dither
	#if defined AO || defined Clouds
	float dither = bayer64(gl_FragCoord.xy);
	#endif
	
	//NDC Coordinate
	vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;
	
	if (z >= 1.0){
		//Brighten sky when Light Shaft is disabled
		#ifndef LightShaft
		color.rgb += 0.025 * end_c;
		#endif

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
	else{
		//Specular Reflection
		#ifdef RPSupport
		#ifdef RPSReflection
		float smoothness = texture2D(colortex3,texcoord.xy).r;
		smoothness = smoothness*sqrt(smoothness);
		float f0 = texture2D(colortex3,texcoord.xy).g;
		vec3 normal = texture2D(gaux3,texcoord.xy).xyz*2.0-1.0;
		
		float fresnel = clamp(1.0 + dot(normal, normalize(fragpos.xyz)),0.0,1.0);
		fresnel = pow(fresnel, 5.0);
		
		vec2 noisecoord = (fragpos.xy)/fragpos.z*4.0;
		#if AA == 2
		noisecoord += frameTimeCounter*4.0;
		#endif

		fresnel = mix(f0, 1.0, fresnel) * smoothness * smoothness * sqrt(smoothness);
		
		if (fresnel > 0.001){
			vec4 reflection = vec4(0.0);
			vec3 skyRef = end_c*0.03;

			reflection = raytrace(fragpos.xyz,normal,dither);
			
			reflection.rgb = mix(skyRef,reflection.rgb,reflection.a);
			if (f0 >= 0.8) reflection.rgb *= color.rgb*2.0;

			vec3 spec = texture2D(colortex7,texcoord.xy).rgb;
			spec = 4.0*spec/(1.0-spec)*fresnel;
			
			color.rgb = mix(color.rgb, reflection.rgb, fresnel)+spec;
		}
		#endif
		#endif
		
		//Ambient Occlusion
		#ifdef AO
		color.rgb *= dbao(depthtex0, dither);
		#endif
		
		//Fog
		#ifdef Fog
		color.rgb = calcFog(color.rgb,fragpos.xyz, blindness);
		#endif
	}
	
	//Bumpy Edge
	#ifdef BumpyEdge
	color.rgb *= bumpyedge(depthtex0);
	#endif
	
	//Black Outline
	#ifdef Celshade
	color.rgb *= celshade(depthtex0, float(z >= 1.0));
	#endif
	
/*DRAWBUFFERS:04*/
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(z,0.0,0.0,0.0);
	#ifndef ReflectionPrevious
/*DRAWBUFFERS:045*/
	gl_FragData[2] = vec4(pow(color.rgb,vec3(0.125))*0.5,float(z < 1.0));
	#endif
	#ifdef RPSupport
	#ifdef RPSReflection
/*DRAWBUFFERS:0451*/
	gl_FragData[3] = vec4(1.0);
	#endif
	#endif
}
