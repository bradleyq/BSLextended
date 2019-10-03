#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

void main(){
	//Reset colortex1 to clear state when RPSupport enabled
/*DRAWBUFFERS:1*/
	gl_FragData[0] = vec4(1.0);
}
