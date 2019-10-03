#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

//#define DisableTexture
#define EmissiveRecolor
#define EmissiveBrightness 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]


varying vec2 texcoord;

varying vec3 sunVec;
varying vec3 upVec;

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
    albedo.rgb = albedo.rgb * (1.0 + max(0.0,dot(sunVec, upVec)) * 20 * EmissiveBrightness);
	
	#ifdef DisableTexture
	albedo.rgb = vec3(2.0);
	#endif
    
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}