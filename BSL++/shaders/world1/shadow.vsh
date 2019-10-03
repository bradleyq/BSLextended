#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define WavingCrops
#define WavingFire
#define WavingPlant
#define WavingGrass
#define WavingLava
#define WavingLeaves
#define WavingLilypad
#define WavingTallPlant
#define WavingVines

//#define WorldTimeAnimation
#define AnimationSpeed 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00 5.00 6.00 7.00 8.00]

const float shadowDistance = 256.0; //[128.0 256.0 512.0 1024.0]
const int shadowMapResolution = 2048; //[128.0 144.0 160.0 176.0 192.0 208.0 224.0 240.0 256.0 512.0 1024.0]

const float shadowMapBias = 1.0-25.6/shadowDistance;
const float PI = 3.1415927;

varying float mat;
varying vec2 texcoord;
varying vec4 color;

attribute vec4 mc_midTexCoord;
attribute vec4 mc_Entity;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

float pi2wt = PI*2*(frametime*24);

vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5) {
    vec3 ret;
    float magnitude,d0,d1,d2,d3;
    magnitude = sin(pi2wt*fm + pos.x*0.5 + pos.z*0.5 + pos.y*0.5) * mm + ma;
    d0 = sin(pi2wt*f0);
    d1 = sin(pi2wt*f1);
    d2 = sin(pi2wt*f2);
    ret.x = sin(pi2wt*f3 + d0 + d1 - pos.x + pos.z + pos.y) * magnitude;
    ret.z = sin(pi2wt*f4 + d1 + d2 + pos.x - pos.z + pos.y) * magnitude;
	ret.y = sin(pi2wt*f5 + d2 + d0 + pos.z + pos.y - pos.y) * magnitude;
    return ret;
}

vec3 calcMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    vec3 move1 = calcWave(pos      , 0.0027, 0.0400, 0.0400, 0.0127, 0.0089, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
	vec3 move2 = calcWave(pos+move1, 0.0348, 0.0400, 0.0400, f0, f1, f2, f3, f4, f5) * amp2;
    return move1+move2;
}

float calcLilypadMove(vec3 pos){
	return 0.05 * sin(2 * PI * (frametime*0.7 + pos.x * 0.14 + pos.z * 0.07))
		 + 0.05 * sin(2 * PI * (frametime*0.5 + pos.x * 0.10 + pos.z * 0.20));
}

float calcLavaMove(in vec3 pos)
{
	float fy = fract(pos.y + 0.001);
	if (fy > 0.002)
	{
		float wave = 0.025 * sin(2 * PI * (frametime*0.3 + pos.x * 0.07 + pos.z * 0.03))
				   + 0.025 * sin(2 * PI * (frametime*0.2 + pos.x * 0.05 + pos.z * 0.10));
		return clamp(wave, -fy, 1.0-fy);
	}
	else
	{
		return 0.0;
	}
}

void main(){
	
	gl_Position = ftransform();
	mat = 0.0;
	float istopv = 0.0;
	if (gl_MultiTexCoord0.t < mc_midTexCoord.t) istopv = 1.0;
	vec4 position = gl_Position;
	position = shadowProjectionInverse * position;
	position = shadowModelViewInverse * position;
	position.xyz += cameraPosition.xyz;
	
	if (istopv > 0.9) {
	#ifdef WavingGrass
		if (mc_Entity.x == 31.0)
			position.xyz += calcMove(position.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif
	
	#ifdef WavingPlant
		if (mc_Entity.x == 6.0)
			position.xyz += calcMove(position.xyz, 0.0041, 0.005, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif
	#ifdef WavingCrops
		if (mc_Entity.x == 59.0)
			position.xyz += calcMove(position.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif
	#ifdef WavingFire
		if (mc_Entity.x == 12030.0)
			position.xyz += calcMove(position.xyz, 0.0105, 0.0096, 0.0087, 0.0063, 0.0097, 0.0156, vec3(1.2,0.4,1.2), vec3(0.8,0.8,0.8));
	#endif
	}
	
	#ifdef WavingTallPlant
	if (mc_Entity.x == 175.0 || (mc_Entity.x == 176.0 && istopv > 0.9))
		position.xyz += calcMove(position.xyz, 0.0041, 0.005, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.1,0.8), vec3(0.4,0.0,0.4));
	#endif
	#ifdef WavingLeaves
	if (mc_Entity.x == 18.0)
		position.xyz += calcMove(position.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(0.5,0.5,0.5), vec3(0.25,0.25,0.25));
	#endif
	#ifdef WavingVines
	if (mc_Entity.x == 106.0)
		position.xyz += calcMove(position.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(0.05,0.4,0.05), vec3(0.05,0.3,0.05));
	#endif
	#ifdef WavingLilypad
	if (mc_Entity.x == 111.0)
		position.y += calcLilypadMove(position.xyz);
	#endif
	#ifdef WavingLava
	if (mc_Entity.x == 12020.0)
		position.y += calcLavaMove(position.xyz);
	#endif
	
	position.xyz -= cameraPosition.xyz;
	
	if (mc_Entity.x == 79.0) mat = 1.0;
	if (mc_Entity.x == 8.0) mat = 2.0;
	if (mc_Entity.x == 51.0) mat = 3.0;
	
	gl_Position = shadowProjection *  shadowModelView * position;

	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = (1.0f - shadowMapBias) + dist * shadowMapBias;
	
	gl_Position.xy *= (1.0f / distortFactor);
	gl_Position.z = gl_Position.z*0.2;
	
	texcoord = gl_MultiTexCoord0.xy;
	
	color = gl_Color;
}
