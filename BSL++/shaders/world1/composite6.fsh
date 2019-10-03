#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define AA 1 //[0 1 2]
#define LightShaft
#define Vignette

#ifdef LightShaft
const bool colortex1MipmapEnabled = true;
#endif

varying vec2 texcoord;

uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;

uniform sampler2D colortex1;

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

#if AA == 1
#include "lib/post/fxaa.glsl"
#endif

#if AA == 2
#include "lib/post/taa.glsl"
#endif

void main(){
	vec3 color = texture2DLod(colortex1,texcoord.xy,0).rgb;

	#if AA == 1
	color = fxaa311(color);
	#endif

	#if AA == 2
	float temp = texture2DLod(gaux3,texcoord.xy,0).r;
	
	vec2 prvcoord = reprojection(vec3(texcoord.xy,texture2DLod(depthtex1,texcoord.xy,0).r));
	vec2 view = vec2(viewWidth,viewHeight);
	vec3 tempcolor = neighbourhoodClamping(color,texture2DLod(gaux3,prvcoord.xy,0).gba,1.0/view);
	
	vec2 velocity = (texcoord.xy-prvcoord.xy)*view;
	float blendfactor = float(prvcoord.x > 0.0 && prvcoord.x < 1.0 && prvcoord.y > 0.0 && prvcoord.y < 1.0);
	blendfactor *= clamp(1.0-sqrt(length(velocity))/1.999,0.0,1.0)*0.3+0.6;
	
	color = mix(color,tempcolor,blendfactor);
	tempcolor = color;
	#endif

	//Vignette
	#ifdef Vignette
	color = sqrt(color*color*(1.0-length(texcoord.xy-0.5)*(1-luma(color*color))));
	#endif

/*DRAWBUFFERS:1*/
	gl_FragData[0] = vec4(color,1.0);
	#if AA == 2
/*DRAWBUFFERS:16*/
	gl_FragData[1] = vec4(temp,tempcolor);
	#endif
}