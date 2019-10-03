#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]
#define AO
//#define BumpyEdge
#define Fog
#define FogRange 8 //[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 18 20 22 24 26 28 30 32 36 40 44 48 52 56 60 64]
#define LightShaft
//#define ReflectionPrevious
#define ShadowColor
#define WaterRefract

const int shadowMapResolution = 2048; //[1024 2048 3072 4096 8192]
const float shadowDistance = 256.0; //[128.0 144.0 160.0 176.0 192.0 208.0 224.0 240.0 256.0 512.0 1024.0]
const float shadowMapBias = 1.0-25.6/shadowDistance;

const bool colortex5Clear = false;

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
uniform float rainStrength;
uniform float wetness;
uniform float timeAngle;
uniform float timeBrightness;
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
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#ifdef WaterRefract
uniform sampler2D colortex2;
#endif


uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.3)/0.3;
float z = texture2D(depthtex0,texcoord.xy).r;
float z1 = texture2D(depthtex1,texcoord.xy).r;

float ld(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

bool isTmixU(float mat, float mat_1, float mat_2){
    return (mat > mat_1 + 0.01) && (mat < mat_2 + 0.01);
}

bool isTmixL(float mat, float mat_1, float mat_2){
    return (mat > mat_1 - 0.01) && (mat < mat_2 - 0.01);
}

#include "lib/color/lightColor.glsl"
#include "lib/color/lightColorDynamic.glsl"
#include "lib/color/skyColor.glsl"
#include "lib/color/waterColor.glsl"
#include "lib/color/torchColor.glsl"
#include "lib/common/ambientOcclusion.glsl"
#include "lib/common/dither.glsl"
#include "lib/common/volumetricLight.glsl"
#include "lib/common/waterFog.glsl"
#include "lib/common/fog.glsl"
#include "lib/common/materialDef.glsl"

void main(){
    vec2 albedo_texcoord = texcoord.xy;
    vec2 rt_texcoord = texcoord.xy;
    #ifdef WaterRefract
    vec3 roff = texture2D(colortex2, texcoord.xy).rgb;
    bool water = matches(roff.b,water_mat);
    float candidate = texture2D(colortex2,roff.xy + texcoord.xy).b;
    if ((water && matches(candidate, water_mat)) || (isTmixU(roff.b, water_mat, trans_mat) && isTmixU(candidate, water_mat, trans_mat))) {
        albedo_texcoord.xy += roff.xy;
    }
    if (water) {
        rt_texcoord.xy = albedo_texcoord.xy;
    }

    z = texture2D(depthtex0,albedo_texcoord.xy).r;
    z1 = texture2D(depthtex1,albedo_texcoord.xy).r;
    #endif
    vec3 color = texture2D(colortex0,albedo_texcoord.xy).rgb;
    vec4 rawtranslucent = texture2D(colortex1,rt_texcoord.xy);
    vec4 rawspec = texture2D(colortex3,rt_texcoord.xy);
    
	
	//Dither
	#if defined AO || defined LightShaft
	float dither = bayer64(gl_FragCoord.xy);
	#endif
	
	//Ambient Occlusion
	#ifdef AO
	if (z1-z > 0 && ld(z)*far < 32.0){
		if (dot(rawtranslucent.rgb,rawtranslucent.rgb) < 0.02) color *= mix(dbao(depthtex0, dither),1.0,clamp(0.03125*ld(z)*far,0.0,1.0));
		}
	#endif
	
	//Underwater fog
	#ifdef Fog

    vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0);
    fragpos /= fragpos.w;

	if (isEyeInWater == 1.0){
		//Blindness
		float b = clamp(blindness*2.0-1.0,0.0,1.0);
		b = 1.0-b*b;
		
		color = calcWaterFog(color.rgb, fragpos.xyz, water_c, WaterS, wfogrange);
        color = calcBlindFog(color.rgb, fragpos.xyz, blindness);
	} else if (isTmixL(roff.b, water_mat, trans_mat)) {
        float bigd = length(fragpos.xyz * ld(z1) / ld(z) - fragpos.xyz) / wfogrange;
        vec3 coolcolor = mix(water_c, water_c * 0.1, clamp(pow(bigd / 8, 0.1),0.0,1.0));
        color = mix(color, coolcolor * max(sunVisibility, 0.01), clamp(pow( bigd, 0.25), 0.0, 0.9));
        //color = mix(color, water_c * 0.1 * max(sunVisibility, 0.01), clamp(pow( bigd * 0.1 / wfogrange, 0.1), 0.0, 1.0));
    }
	#endif
	
	//Bumpy Edge
	#ifdef BumpyEdge
	if (z1-z > 0) color *= bumpyedge(depthtex0);
	#endif
	
	//Prepare light shafts
	#ifdef LightShaft
	vec3 vl = getVolumetricRays(z, z1, rawtranslucent.rgb * 0.1, dither);
	#else
	vec3 vl = vec3(0.0);
	#endif

    color *= rawtranslucent.rgb;

    color  = mix(color.rgb, rawspec.rgb, rawspec.a);

    #ifdef Fog
    if (isEyeInWater == 0.0 && z < 1.0) {
        color = calcFog(color.rgb,fragpos.xyz, blindness);
    }
    #endif
	
/*DRAWBUFFERS:01*/
	gl_FragData[0] = vec4(color, 1.0);
	gl_FragData[1] = vec4(vl,1.0);
	#ifdef ReflectionPrevious
/*DRAWBUFFERS:015*/
	gl_FragData[2] = vec4(pow(color.rgb, vec3(0.125)) * 0.5, float(z < 1.0));
	#endif
}
