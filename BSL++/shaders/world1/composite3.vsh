#version 120

varying vec3 upVec;
varying vec3 sunVec;

varying vec2 texcoord;

uniform vec3 upPosition;
uniform vec3 sunPosition;

uniform mat4 gbufferModelView;

void main(){
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0.xy;
	
	upVec = normalize(gbufferModelView[1].xyz);
	sunVec = normalize(sunPosition);
}
