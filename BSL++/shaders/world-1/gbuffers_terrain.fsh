#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

/*
Note : gbuffers_basic, gbuffers_entities, gbuffers_hand, gbuffers_terrain, gbuffers_textured, and gbuffers_water contains mostly the same code. If you edited one of these files, you need to do the same thing for the rest of the file listed.
*/

#define AA 1 //[0 1 2]
#define Desaturation
#define DesaturationFactor 1.0 //[2.0 1.5 1.0 0.5 0.0]
//#define DisableTexture
#define EmissiveBrightness 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define EmissiveRecolor
//#define LightmapBanding

#define POMQuality 32 //[4 8 16 32 64 128 256 512]
#define POMDepth 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define POMDistance 64.0 //[16.0 32.0 48.0 64.0 80.0 96.0 112.0 128.0]
//#define RPSupport
#define RPSFormat 0 //[0 1 2 3]
#define RPSReflection
#define RPSPOM

varying float mat;
varying float recolor;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 normal;
varying vec3 upVec;

varying vec4 color;

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float screenBrightness; 
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}


#include "lib/color/dimensionColor.glsl"
#include "lib/color/torchColor.glsl"
#include "lib/common/spaceConversion.glsl"

#if AA == 2
#include "lib/common/jitter.glsl"
#endif

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord) * vec4(color.rgb,1.0);
	vec3 newnormal = normal;
	
	if (albedo.a > 0.0){
		//NDC Coordinate
		#if AA == 2
		vec3 fragpos = toNDC(vec3(taaJitter(gl_FragCoord.xy/vec2(viewWidth,viewHeight),-0.5),gl_FragCoord.z));
		#else
		vec3 fragpos = toNDC(vec3(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z));
		#endif
		
		//World Space Coordinate
		vec3 worldpos = toWorld(fragpos);
		
		#ifdef EmissiveRecolor
		vec3 rawtorch_c = Torch*Torch/TorchS;
		if (recolor > 0.9){
			float ec = clamp(pow(length(albedo.rgb),1.4),0.0,2.2);
			albedo.rgb = clamp(ec*rawtorch_c*0.25+ec*0.25,vec3(0.0),vec3(2.2));
		}
		if (mat > 2.98 && mat < 3.02){
			float ec = clamp(pow(length(albedo.rgb),1.4),0,2.2);
			albedo.rgb = clamp(ec*rawtorch_c*0.6+ec*0.015,vec3(0),vec3(2.2));
		}
		#else
		if (recolor > 0.9) albedo.rgb *=  0.5 * luma(albedo.rgb) + 0.25;
		#endif
		
		//Convert to linear color space
		albedo.rgb = pow(albedo.rgb, vec3(2.2));
		
		#ifdef DisableTexture
		albedo.rgb = vec3(0.5);
		#endif
		
		//Lightmap
		#ifdef LightmapBanding
		float torchmap = clamp(floor(lmcoord.x*14.999 * (0.75 + 0.25 * color.a)) / 14, 0.0, 1.0);
		float skymap = clamp(floor(lmcoord.y*14.999 * (0.75 + 0.25 * color.a)) / 14, 0.0, 1.0);
		#else
		float torchmap = clamp(lmcoord.x, 0.0, 1.0);
		float skymap = clamp(lmcoord.y, 0.0, 1.0);
		#endif
		
		//Material Flag
		float foliage = float(mat > 0.98 && mat < 1.02);
		float emissive = float(mat > 1.98 && mat < 2.02) * EmissiveBrightness;
		float lava = float(mat > 2.98 && mat < 3.02);
		
		//Shadows
		float quarterNdotU = clamp(0.25 * dot(normal, upVec) + 0.75,0.5,1.0);
		quarterNdotU *= quarterNdotU;
		if (foliage > 0.5) quarterNdotU *= 1.8;
		
		//Lighting Calculation
		vec3 scenelight = nether_c*0.1;
		float newtorchmap = pow(torchmap,10.0)*(EmissiveBrightness+0.5)+(torchmap*0.7);
		
		vec3 blocklight = (newtorchmap * newtorchmap) * torch_c;
		#ifdef LightmapBanding
		scenelight *= floor(color.a*4.0+0.8)/4.0;
		float minlight = (0.009*screenBrightness + 0.001)*floor(color.a*4.0+0.8)/4.0;
		float ao = 1.0;
		#else
		float minlight = (0.009*screenBrightness + 0.001);
		float ao = color.a;
		#endif
		
		#ifdef RPSupport
		#if RPSFormat == 2
		emissive = texture2DGradARB(specular,newcoord.xy,dcdx,dcdy).b;
		#endif
		#endif
		vec3 emissivelight = albedo.rgb * luma(albedo.rgb) * ((emissive + lava) * 4.0 / quarterNdotU);
		
		vec3 finallight = (scenelight + blocklight + nightVision + minlight) * ao + emissivelight;
		albedo.rgb /= sqrt(albedo.rgb * albedo.rgb + 1.0);
		albedo.rgb *= finallight * quarterNdotU;
		
		#ifdef Desaturation
		float desat = clamp(sqrt(torchmap + emissive), DesaturationFactor * 0.4, 1.0);
		vec3 desat_c = nether_c*0.2*(1.0-desat);
		albedo.rgb = mix(luma(albedo.rgb)*desat_c*10.0,albedo.rgb,desat);
		#endif
	}
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}