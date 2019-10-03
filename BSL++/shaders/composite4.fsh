#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

const bool colortex0MipmapEnabled = true;

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float pi = 3.1415927;

vec3 bloomTile(float lod, vec2 offset){
	vec3 bloom = vec3(0.0);
	vec3 temp = vec3(0.0);
	float scale = pow(2.0,lod);
	vec2 coord = (texcoord.xy-offset)*scale;
	float padding = 0.005*scale;

	if (coord.x > -padding && coord.y > -padding && coord.x < 1.0+padding && coord.y < 1.0+padding){
		for (int i = 0; i < 7; i++) {
			for (int j = 0; j < 7; j++) {
			float wg = clamp(1.0-length(vec2(i-3,j-3))*0.28,0.0,1.0);
			wg = wg*wg*20.0;
			vec2 bcoord = (texcoord.xy-offset+vec2(i-3,j-3)*pw*vec2(1.0,aspectRatio))*scale;
			if (wg > 0){
				temp = texture2D(colortex0,bcoord).rgb;
				bloom += temp*wg;
				}
			}
		}
		bloom /= 49;
	}

	return pow(bloom/128.0,vec3(0.25));
}

void main(){
	//Bloom
	vec3 blur = vec3(0);
	blur += bloomTile(2,vec2(0.0,0.0));
	blur += bloomTile(3,vec2(0.0,0.26));
	blur += bloomTile(4,vec2(0.135,0.26));
	blur += bloomTile(5,vec2(0.2075,0.26));
	blur += bloomTile(6,vec2(0.135,0.3325));
	blur += bloomTile(7,vec2(0.160625,0.3325));
	blur += bloomTile(8,vec2(0.1784375,0.3325));

/* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(blur, 1.0);
}
