#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]

//#define RPSupport

const float sunPathRotation = -40.0; //[-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

varying float isMainHand;

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
attribute vec4 mc_midTexCoord;
#endif

uniform int worldTime;

uniform vec3 cameraPosition;
uniform vec3 upPosition;
uniform vec3 sunPosition;

uniform mat4 gbufferModelView;

#if AA == 2
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "lib/common/jitter.glsl"
#endif

void main(){
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	
	gl_Position = ftransform();
	
	#if AA == 2
	gl_Position.xy = taaJitter(gl_Position.xy,gl_Position.w);
	#endif
	
	color = gl_Color;
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = clamp((lmcoord - 0.03125) * 1.06667, 0.0, 1.0);

	normal = normalize(gl_NormalMatrix * gl_Normal);
	
	//Sun position fix from Builderb0y
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = 0.0;
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	upVec = normalize(gbufferModelView[1].xyz);
	//sunVec = normalize(sunPosition);
	
	isMainHand = float(gl_ModelViewMatrix[3][0] > 0.0);
	
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