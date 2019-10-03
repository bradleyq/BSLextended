#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 normal;
varying vec3 upVec;

varying vec4 color;

uniform int worldTime;

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
	upVec = normalize(gbufferModelView[1].xyz);
}