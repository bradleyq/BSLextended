#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]

//#define WorldCurvature

varying vec2 texcoord;

#if AA == 2
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "lib/common/jitter.glsl"
#endif

#ifdef WorldCurvature
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
#include "lib/common/worldCurvature.glsl"
#endif

void main(){
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	
	#ifdef WorldCurvature
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	position.y -= worldCurvature(position.xz);
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	#else
	gl_Position = ftransform();
	#endif
	
	#if AA == 2
	gl_Position.xy = taaJitter(gl_Position.xy,gl_Position.w);
	#endif
}