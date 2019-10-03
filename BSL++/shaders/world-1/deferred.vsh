#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

varying vec2 texcoord;

void main(){
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0.xy;
}
