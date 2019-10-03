#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

//#define DisableTexture
#define EmissiveRecolor

varying vec2 texcoord;

varying vec4 color;

uniform sampler2D texture;

#include "lib/color/torchColor.glsl"

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord.xy) * color;
	
	#ifdef EmissiveRecolor
	if (dot(color.rgb,vec3(1.0))>2.66){
		vec3 rawtorch_c = Torch*Torch/TorchS;
		float ec = clamp(pow(length(albedo.rgb),1.4),0.0,2.2);
		albedo.rgb = clamp(ec*rawtorch_c*0.45+ec*0.05,vec3(0.0),vec3(2.2))*1.4;
	}
	#endif
	
	//Convert to linear color space
	albedo.rgb = pow(albedo.rgb,vec3(2.2)) * 4.0;
	
	#ifdef DisableTexture
	albedo.rgb = vec3(2.0);
	#endif
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}