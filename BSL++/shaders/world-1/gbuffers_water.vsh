#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]

//#define RPSupport

#define WavingWater

//#define WorldTimeAnimation
#define AnimationSpeed 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00 5.00 6.00 7.00 8.00]

const float PI = 3.1415927;

varying float dist;
varying float mat;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 upVec;
varying vec3 viewVector;
varying vec3 wpos;

varying vec4 color;

#ifdef RPSupport
varying vec4 vtexcoordam;
varying vec4 vtexcoord;
#endif

attribute vec4 at_tangent;
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

#if AA == 2
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "lib/common/jitter.glsl"
#endif

void main(){
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	
	mat = 0.0f;
	
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	vec3 worldpos = position.xyz + cameraPosition;
	wpos = worldpos;
	
	if (mc_Entity.x == 8.0){
		mat = 1.0;
		float fy = fract(worldpos.y + 0.001);
		
		#ifdef WavingWater
		float wave = 0.05 * sin(2 * PI * (frametime*0.7 + worldpos.x * 0.14 + worldpos.z * 0.07))
				   + 0.05 * sin(2 * PI * (frametime*0.5 + worldpos.x * 0.10 + worldpos.z * 0.20));
		float displacement = clamp(wave, -fy, 1.0-fy);
		if (fract(worldpos.y) > 0.01 && fract(worldpos.y) < 0.99) position.y += displacement*0.5;
		#endif
	}
	
	if (mc_Entity.x == 79.0) mat = 2.0;
	
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	if (mat == 0.0) gl_Position.z -= 0.00001;
	
	#if AA == 2
	gl_Position.xy = taaJitter(gl_Position.xy,gl_Position.w);
	#endif
	
	color = gl_Color;
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = clamp((lmcoord - 0.03125) * 1.06667, 0.0, 1.0);

	normal = normalize(gl_NormalMatrix * gl_Normal);
	upVec = normalize(gbufferModelView[1].xyz);
	
	#ifdef RPSupport
	vec2 midcoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texcoordminusmid = texcoord-midcoord;
	vtexcoordam.pq  = abs(texcoordminusmid)*2;
	vtexcoordam.st  = min(texcoord,midcoord-texcoordminusmid);
	vtexcoord.xy    = sign(texcoordminusmid)*0.5+0.5;
	#endif
	
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