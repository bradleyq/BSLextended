#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

//#define DisableTexture

varying vec2 texcoord;

uniform sampler2D texture;

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord.xy);
	
	//Convert to linear color space
	albedo.rgb = pow(albedo.rgb,vec3(2.2)) * 4.0;
	
	#ifdef DisableTexture
	albedo.rgb = vec3(2.0);
	#endif
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}