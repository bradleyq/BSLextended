#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

//#define RPSupport
#define RPSReflection

#define About 0 //[0]

//Buffer Format
const int R11F_G11F_B10F = 0;
const int RGB10_A2 = 1;
const int RGBA32F = 2;
const int RGBA16F = 3;
const int RGB16F = 4;
const int RGBA8 = 5;
const int RGB8 = 6;
const int R32F = 7;

const int colortex0Format = R11F_G11F_B10F; //main image
const int colortex1Format = RGB8; //raw translucent, bloom
const int colortex2Format = RGBA16F; //free
const int colortex3Format = RGBA16F; //reflection information

const int gaux1Format = R32F; //depth
const int gaux2Format = RGB10_A2; //reflection image
const int gaux3Format = RGBA16F; //temporal stuff

const float sunPathRotation = -40.0; //[-60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0]
const int noiseTextureResolution = 512;
const bool shadowHardwareFiltering = true;
const float drynessHalflife = 10.0f;
const float wetnessHalflife = 10.0f;

varying vec2 texcoord;

uniform sampler2D colortex1;

void main(){
	
	vec3 color = texture2D(colortex1,texcoord.xy).rgb;
	
	#ifdef About
	#endif
	
	gl_FragColor = vec4(color,1.0);

}