#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]
#define Clouds
#define LightShaft
//#define RoundSunMoon
#define Stars

//#define WorldTimeAnimation
#define AnimationSpeed 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00 5.00 6.00 7.00 8.00]
#define SunBrightness 2500 //[125 250 500 1000 1500 2000 2500 3000 3500 4000 4500 5000 10000]
#define MoonBrightness 32 //[1 2 4 8 16 32 48 64 80 96 112 128]

varying vec3 upVec;
varying vec3 sunVec;
varying vec3 wpos;

uniform int isEyeInWater;
uniform int worldTime;

uniform float blindness;
uniform float frameTimeCounter;
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

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform sampler2D noisetex;

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.3)/0.3;
float moonVisibility = clamp(dot(-sunVec,upVec)+0.05,0.0,0.3)/0.3;

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

#include "lib/color/lightColor.glsl"
#include "lib/color/lightColorDynamic.glsl"
#include "lib/color/waterColor.glsl"
#include "lib/color/skyColor.glsl"
#include "lib/common/clouds.glsl"
#include "lib/common/dither.glsl"
#include "lib/common/sky.glsl"

void main(){
	//NDC Coordinate
	vec4 fragpos = gbufferProjectionInverse*(vec4(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z,1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;
	
	//Render Sky
    float cosSn = dot(normalize(fragpos.xyz),sunVec);
	vec3 albedo = getSkyColor(fragpos.xyz,light,ambient) * (1.0 + 2.0 * pow(max(0.0, cosSn), 5));
	
	//Round Sun & Moon
	#ifdef RoundSunMoon
	float isMoon = float(cosSn < 0.0);
	float sun = clamp(pow(abs(cosSn),800.0*isMoon+ (1.0 - wetness) * 1000.0 + 3000.0),0.0,1.0);
    //float sun = clamp( 1.0 / abs(cosSn));
	vec3 light_me = mix(light_m,light_a,mefade);
	vec3 suncol = mix(light_me,sqrt(light_d*light_me),timeBrightness);
    suncol = mix(sqrt(light_n)*moonVisibility,suncol*sunVisibility,float(cosSn > 0.0));
    suncol = mix(suncol, light, rainStrength);
    if (isEyeInWater < 1.02 && isEyeInWater > 0.98) {
        suncol *= Water;
    }
    float sb = SunBrightness * (1.0 - (0.9995) * pow(wetness,0.5));
	albedo += (sun * (sb - (sb - MoonBrightness) * isMoon)) * suncol;
	#endif
	
	albedo *= 1.0+nightVision;

	//Dither
	float dither = bayer64(gl_FragCoord.xy);

	//Stars
	#ifdef Stars
	if (moonVisibility > 0.0) albedo.rgb = drawStars(fragpos.xyz,albedo.rgb,light_n);
	#endif
	//Clouds
	#ifdef Clouds
	vec4 cloud = drawCloud(fragpos.xyz, dither, albedo.rgb, light, ambient);
	albedo.rgb = mix(albedo.rgb,cloud.rgb,cloud.a);
	#endif

	//Brighten sky when Light Shaft is disabled
	float cosS = dot(normalize(fragpos.xyz),sunVec*(1.0-2.0*float(timeAngle > 0.5325 && timeAngle < 0.9675)));
	float visfactor = 0.05*(1.0-0.8*timeBrightness)*(3.0*rainStrength+1.0);
	float invvisfactor = 1.0-visfactor;

	float visibility = clamp(cosS*0.5+0.5,0.0,1.0);
	visibility = clamp((visfactor/(1.0-invvisfactor*visibility)-visfactor)*1.015/invvisfactor - 0.015,0.0,1.0);
	visibility = mix(1.0,visibility,0.25*eBS+0.75) * (1.0-rainStrength*eBS*0.875);

	#ifdef LightShaft
	if (isEyeInWater == 1) albedo.rgb += 0.225 * light * visibility * shadowFade;
	#else
	albedo.rgb += 0.225 * light * visibility * shadowFade;
	#endif

	//Sky Exposure
	albedo.rgb *= 4.0-3.0*eBS;
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo,1.0);
#ifdef Clouds
/* DRAWBUFFERS:04 */
	gl_FragData[1] = vec4(cloud.a,0.0,0.0,0.0);
#endif
}