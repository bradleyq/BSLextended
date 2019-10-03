#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

//#define Celshade
//#define MotionBlur

varying vec2 texcoord;

uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;

uniform sampler2D colortex0;
uniform sampler2D depthtex1;

#include "lib/common/dither.glsl"
#include "lib/post/motionBlur.glsl"

void main(){
	vec3 color = texture2D(colortex0,texcoord.xy).rgb;
	
	//Material Flag
	float hand = float(texture2D(depthtex1,texcoord.xy).r < 0.56);

	#ifdef Celshade
	const vec2 celshadeoffset[24] = vec2[24](vec2(-2.0,2.0),vec2(-1.0,2.0),vec2(0.0,2.0),vec2(1.0,2.0),vec2(2.0,2.0),vec2(-2.0,1.0),vec2(-1.0,1.0),vec2(0.0,1.0),vec2(1.0,1.0),vec2(2.0,1.0),vec2(-2.0,0.0),vec2(-1.0,0.0),vec2(1.0,0.0),vec2(2.0,0.0),vec2(-2.0,-1.0),vec2(-1.0,-1.0),vec2(0.0,-1.0),vec2(1.0,-1.0),vec2(2.0,-1.0),vec2(-2.0,-2.0),vec2(-1.0,-2.0),vec2(0.0,-2.0),vec2(1.0,-2.0),vec2(2.0,-2.0));
	float cph = 1.0/1080.0;
	float cpw = cph/aspectRatio;
	for (int i = 0; i < 24; i++){
		hand = max(hand,float(texture2D(depthtex1,texcoord.xy+vec2(cpw,cph)*celshadeoffset[i]).r < 0.56));
	}
	#endif
	
	//Motion Blur
	#ifdef MotionBlur
	color = motionBlur(color,hand);
	#endif
	
	
/*DRAWBUFFERS:0*/
	gl_FragData[0] = vec4(color,1.0);
}
