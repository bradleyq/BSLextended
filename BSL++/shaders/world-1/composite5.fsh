#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]
//#define AutoExposure
#define Bloom
//#define Celshade
//#define ColorGrading
//#define DirtyLens

#ifdef AutoExposure
const bool colortex0MipmapEnabled = true;
#endif
const bool colortex6Clear = false;

varying vec2 texcoord;

uniform int isEyeInWater;
uniform int worldTime;

uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D gaux3;
uniform sampler2D noisetex;
uniform sampler2D depthtex1;

#ifdef DirtyLens
uniform sampler2D depthtex2;
#endif

float pw = 1.0/viewWidth;
float ph = 1.0/viewHeight;

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float temporalMix(float temporal, float fade, float x){
	return temporal * (1.0-fade) + fade * x;
}

vec2 uwDistort(){
	vec2 distort = vec2(cos(texcoord.y*32.0+frameTimeCounter*3.0),sin(texcoord.x*32.0+frameTimeCounter*1.7))*0.0005;
	vec2 coord = texcoord.xy + distort;
	float mask = float(coord.x > 0.0 && coord.x < 1.0 && coord.y > 0.0 && coord.y < 1.0);
	if (mask > 0.5) return coord;
	else return texcoord.xy;
}

#ifdef Bloom
#include "lib/post/bloom.glsl"
#endif
#ifdef ColorGrading
#include "lib/post/colorGrading.glsl"
#endif
#include "lib/post/tonemap.glsl"

void main(){
	vec2 newcoord = texcoord.xy;
	if (isEyeInWater == 1.0) newcoord = uwDistort();
	
	vec3 color = texture2D(colortex0,newcoord).rgb;
	
	//Temporal Stuffs
	#ifdef AutoExposure
	float tempexposure = texture2D(gaux3,vec2(pw,ph)).r;
	#endif
	vec3 tempcolor = vec3(0.0);
	
	#if AA == 2
	tempcolor = texture2D(gaux3,texcoord.xy).gba;
	#endif
	
	//Bloom
	#ifdef Bloom
	color = bloom(color,newcoord);
	#endif
	
	//Auto Exposure
	#ifdef AutoExposure
	float exposure = clamp(length(texture2DLod(colortex0,vec2(0.5),log2(viewWidth*0.4)).rgb),0.0001,10.0);
	color.rgb /= 2.0*clamp(tempexposure,0.001,10.0)+0.25;
	#endif
	
	//Color Grading
	#ifdef ColorGrading
	color = colorGrading(color);
	#endif
	
	//Tonemap
	color = BSLTonemap(color);
	
	//Store Temporal Values;
	float temporal = 0.0;
	#ifdef AutoExposure
	if (texcoord.x < 2*pw && texcoord.y < 2*ph) temporal = temporalMix(tempexposure,0.016,sqrt(exposure));
	#endif
	
	color = pow(color,vec3(1.0/2.2));
	
	//Saturation
	color = colorSaturation(color);
	
	//Film Grain
	color += (texture2D(noisetex,texcoord.xy*vec2(viewWidth,viewHeight)/512.0).rgb-0.25)/128.0;
	
/*DRAWBUFFERS:16*/
	gl_FragData[0] = vec4(color,1.0);
	gl_FragData[1] = vec4(temporal,tempcolor);
}