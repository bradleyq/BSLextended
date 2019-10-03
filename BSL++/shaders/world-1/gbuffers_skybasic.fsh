#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

void main(){
	
	//Render Sky
	vec3 albedo = vec3(0.0);
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo,1.0);
}