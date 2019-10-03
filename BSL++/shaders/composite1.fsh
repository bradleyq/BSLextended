#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define LightShaft
#define LightShaftStrength 1.00	//[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]

const bool colortex1MipmapEnabled = true;

varying vec3 upVec;
varying vec3 sunVec;

varying vec2 texcoord;

uniform int isEyeInWater;
uniform int worldTime;

uniform float blindness;
uniform float rainStrength;
uniform float wetness;
uniform float shadowFade;
uniform float timeAngle;
uniform float timeBrightness;
uniform float frameTimeCounter;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;

#include "lib/color/lightColor.glsl"
#include "lib/color/lightColorDynamic.glsl"

void main(){
	vec3 color = texture2D(colortex0,texcoord.xy).rgb;
	
	//Light Shafts
	#ifdef LightShaft
	vec3 vl = texture2DLod(colortex1,texcoord.xy,1.5).rgb;
	float z = texture2D(depthtex0,texcoord.xy).r;
	
	float b = clamp(blindness*2.0-1.0,0.0,1.0);
	b = b*b;
	
	color += vl * vl * light * LightShaftStrength * (0.5 * (1.0-rainStrength*eBS*0.875) * shadowFade * (1.0-b));
	//color = vl * vl;
	#endif
	
/*DRAWBUFFERS:0*/
	gl_FragData[0] = vec4(color, 1.0);
}
