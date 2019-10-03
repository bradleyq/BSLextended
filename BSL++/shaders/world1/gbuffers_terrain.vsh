#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]

//#define RPSupport

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

const float sunPathRotation = -40.0; //[-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

const float PI = 3.1415927;

varying float mat;
varying float recolor;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 normal;
varying vec3 upVec;
varying vec3 sunVec;

varying vec4 color;

#ifdef RPSupport
varying float dist;
varying vec3 binormal;
varying vec3 tangent;
varying vec3 viewVector;
varying vec4 vtexcoordam;
varying vec4 vtexcoord;
attribute vec4 at_tangent;
#endif

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform int worldTime;

uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;

uniform vec3 cameraPosition;
uniform vec3 upPosition;
uniform vec3 sunPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;


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
    vec3 move1 = calcWave(pos      , 0.0027, 0.0400, 0.0400, 0.0127, 0.0169, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
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

#if AA == 2
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "lib/common/jitter.glsl"
#endif

void main(){
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	
	mat = 0.0;
	recolor = 0.0;
	
	float istopv = 0.0;
	if (gl_MultiTexCoord0.t < mc_midTexCoord.t) istopv = 1.0;
	
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec3 worldpos = position.xyz + cameraPosition;
	
	if (istopv > 0.9) {
	#ifdef WavingGrass
		if (mc_Entity.x == 31.0){
			if (length(position.xyz) < 2.0) position.xz *= 1+max(5.0/pow(max(length(position.xyz*vec3(8.0,2.0,8.0)-vec3(0.0,2.0,0.0)),2.0),1.0)-0.625,0.0);
			position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
		}
	#endif
	#ifdef WavingPlant
		if (mc_Entity.x == 6.0)
			position.xyz += calcMove(worldpos.xyz, 0.0041, 0.005, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif
	#ifdef WavingCrops
		if (mc_Entity.x == 59.0){
			if (length(position.xyz) < 2.0) position.xz *= 1+max(5.0/pow(max(length(position.xyz*vec3(8.0,2.0,8.0)-vec3(0.0,2.0,0.0)),2.0),1.0)-0.625,0.0);
			position.xyz += calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
		}
	#endif
	#ifdef WavingFire
		if (mc_Entity.x == 12030.0)
			position.xyz += calcMove(worldpos.xyz, 0.0105, 0.0096, 0.0167, 0.0063, 0.0097, 0.0156, vec3(1.2,0.4,1.2), vec3(0.8,0.8,0.8));
	#endif
	}
	
	#ifdef WavingTallPlant
	if (mc_Entity.x == 175.0 || (mc_Entity.x == 176.0 && istopv > 0.9))
		position.xyz += calcMove(worldpos.xyz, 0.0041, 0.005, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.1,0.8), vec3(0.4,0.0,0.4));
	#endif
	#ifdef WavingLeaves
	if (mc_Entity.x == 18.0)
		position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(0.5,0.5,0.5), vec3(0.25,0.25,0.25));
	#endif
	#ifdef WavingVines
	if (mc_Entity.x == 106.0)
		position.xyz += calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(0.05,0.4,0.05), vec3(0.05,0.3,0.05));
	#endif
	#ifdef WavingLilypad
	if (mc_Entity.x == 111.0)
		position.y += calcLilypadMove(worldpos.xyz);
	#endif
	#ifdef WavingLava
	if (mc_Entity.x == 12020.0)
		position.y += calcLavaMove(worldpos.xyz);
	#endif
	
	//Foliage
	if (mc_Entity.x == 31.0 || mc_Entity.x == 6.0 || mc_Entity.x == 59.0 || mc_Entity.x == 175.0 || mc_Entity.x == 176.0 || mc_Entity.x == 18.0 || mc_Entity.x == 106.0 || mc_Entity.x == 111.0 || mc_Entity.x == 83.0)
	mat = 1.0;
	//Emissive
	if (mc_Entity.x == 55.0 || mc_Entity.x == 213.0 || mc_Entity.x == 76.0 ||  mc_Entity.x == 62.0 || mc_Entity.x == 50.0 || mc_Entity.x == 91.0 || mc_Entity.x == 89.0 || mc_Entity.x == 51.0) mat = 2.0;
	//Lava
	if (mc_Entity.x == 10.0) mat = 3.0;
	//Metals	
	if (mc_Entity.x == 42.0) mat = 4.0;
	//Recolor
	if (mc_Entity.x == 213.0 || mc_Entity.x == 89.0 || mc_Entity.x == 138.0) recolor = 1.0;
	
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	
	#if AA == 2
	gl_Position.xy = taaJitter(gl_Position.xy,gl_Position.w);
	#endif
	
	color = gl_Color;
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = clamp((lmcoord - 0.03125) * 1.06667, 0.0, 1.0);
	
	//Fix Lightmap
	if (mc_Entity.x == 62.0) lmcoord.x = 0.8666;
	if (mc_Entity.x == 50.0) lmcoord.x = 0.9333;
	if (mc_Entity.x == 91.0 || mc_Entity.x == 89.0 || mc_Entity.x == 10.0 || mc_Entity.x == 51.0) lmcoord.x = 1.0;

	normal = normalize(gl_NormalMatrix * gl_Normal);
	//Sun position fix from Builderb0y
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = 0.0;
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	upVec = normalize(gbufferModelView[1].xyz);
	//sunVec = normalize(sunPosition);
	
	#ifdef RPSupport
	vec2 midcoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texcoordminusmid = texcoord-midcoord;
	vtexcoordam.pq  = abs(texcoordminusmid)*2;
	vtexcoordam.st  = min(texcoord,midcoord-texcoordminusmid);
	vtexcoord.xy    = sign(texcoordminusmid)*0.5+0.5;
	
	tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								  tangent.y, binormal.y, normal.y,
						     	  tangent.z, binormal.z, normal.z);
								  
	viewVector = ( gl_ModelViewMatrix * gl_Vertex).xyz;
	viewVector = (tbnMatrix * viewVector);
	
	dist = length(gl_ModelViewMatrix * gl_Vertex);
	#endif
}