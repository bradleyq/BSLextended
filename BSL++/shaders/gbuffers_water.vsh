#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]

//#define RPSupport

#define WavingWater

//#define WorldCurvature

//#define WorldTimeAnimation
#define AnimationSpeed 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00 5.00 6.00 7.00 8.00]

const float sunPathRotation = -40.0; //[-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

const float PI = 3.1415927;

varying float dist;
varying float mat;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 binormal;
varying vec3 normal;
varying vec3 sunVec;
varying vec3 tangent;
varying vec3 upVec;
varying vec3 viewVector;
varying vec3 wpos;

varying vec4 color;

attribute vec4 at_tangent;
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform int worldTime;

uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float timeAngle;

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

#if AA == 2
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "lib/common/jitter.glsl"
#endif

#ifdef WorldCurvature
#include "lib/common/worldCurvature.glsl"
#endif
#include "lib/common/materialDef.glsl"

void main(){
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	
	mat = none_mat;
	
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec3 worldpos = position.xyz + cameraPosition;
	wpos = worldpos;
	
	if (mc_Entity.x == 8.0){
		mat = water_mat;
		float fy = fract(worldpos.y + 0.001);
		
		#ifdef WavingWater
		float wave = 0.05 * sin(2 * PI * (frametime*0.7 + worldpos.x * 0.14 + worldpos.z * 0.07))
				   + 0.05 * sin(2 * PI * (frametime*0.5 + worldpos.x * 0.10 + worldpos.z * 0.20));
		float displacement = clamp(wave, -fy, 1.0-fy);
		if (fract(worldpos.y) > 0.01 && fract(worldpos.y) < 0.99) position.y += displacement*0.5;
		#endif
	}
	
	if (mc_Entity.x == 79.0) mat = trans_mat;

	#ifdef WorldCurvature
	position.y -= worldCurvature(position.xz);
	#endif
	
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	if (mat == none_mat) gl_Position.z -= 0.00001;
	
	#if AA == 2
	gl_Position.xy = taaJitter(gl_Position.xy,gl_Position.w);
	#endif
	
	color = gl_Color;
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = clamp((lmcoord - 0.03125) * 1.06667, 0.0, 1.0);

	normal = normalize(gl_NormalMatrix * gl_Normal);
	//Sun position fix from Builderb0y
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	upVec = normalize(gbufferModelView[1].xyz);
	//timeVec = normalize(sunPosition);
	
	tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	normal = normalize(gl_NormalMatrix * normalize(gl_Normal));
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
								  tangent.y, binormal.y, normal.y,
						     	  tangent.z, binormal.z, normal.z);
								  
	viewVector = ( gl_ModelViewMatrix * gl_Vertex).xyz;
	viewVector = (tbnMatrix * viewVector);
	
	dist = length(gl_ModelViewMatrix * gl_Vertex);
}