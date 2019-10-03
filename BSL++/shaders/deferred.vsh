#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

const float sunPathRotation = -40.0; //[-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]

varying vec3 upVec;
varying vec3 sunVec;

varying vec2 texcoord;

uniform float timeAngle;

uniform vec3 upPosition;
uniform vec3 sunPosition;

uniform mat4 gbufferModelView;

void main(){
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0.xy;
	
	//Sun position fix from Builderb0y
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	upVec = normalize(gbufferModelView[1].xyz);
    //timeVec = normalize(sunPosition);
}
