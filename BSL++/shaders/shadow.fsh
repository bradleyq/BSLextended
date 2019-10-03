#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define ShadowColor

#include "lib/common/materialDef.glsl"

varying float mat;
varying vec2 texcoord;
varying vec4 color;

uniform int blockEntityId;

uniform sampler2D tex;

void main(){
	#if MC_VERSION >= 11300
	if (blockEntityId == 138) discard;
	#endif

	vec4 albedo = texture2D(tex,texcoord.xy)*color;

	bool premult = matches(mat, trans_mat);
	float disable = float(matches(mat, water_mat) || matches(mat, fire_mat));
	
	#ifdef ShadowColor
	//if ((checkalpha > 0.9 && albedo.a > 0.98) || checkalpha < 0.9) albedo.rgb *= 0.0;
	albedo.rgb = mix(vec3(1),albedo.rgb,pow(albedo.a,(1.0-albedo.a)*0.5)*1.05);
	albedo.rgb *= 1.0-pow(albedo.a,64.0);
	#else
	if ((premult && albedo.a < 0.98)) albedo.a *= 0.0;
	#endif
	albedo.a *= 1.0 - disable;
	
	gl_FragData[0] = albedo;
	
}