#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

//#define DisableTexture

varying vec2 texcoord;

varying vec4 color;

uniform sampler2D texture;

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord.xy) * color;
	
	//Convert to linear color space
	albedo.rgb = pow(albedo.rgb,vec3(2.2)) * 2.0;
	
	#ifdef DisableTexture
	albedo.rgb = vec3(2.0);
	#endif
	
	albedo.a *= 0.25;
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}