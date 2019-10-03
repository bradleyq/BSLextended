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

#define POMQuality 32 //[4 8 16 32 64 128 256 512]
#define POMDepth 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define POMShadowAngle 2.0 //[0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0]
//#define RPSupport
#define RPSFormat 0 //[0 1 2 3]
#define RPSReflection
#define RPSPOM
#define RPSShadow

#define ShadowColor
#define ShadowFilter

const int shadowMapResolution = 2048; //[1024 2048 3072 4096 8192]
const float shadowDistance = 256.0; //[128.0 144.0 160.0 176.0 192.0 208.0 224.0 240.0 256.0 512.0 1024.0]
const float shadowMapBias = 1.0-25.6/shadowDistance;

varying float isMainHand;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 normal;
varying vec3 upVec;
varying vec3 sunVec;

varying vec4 color;

uniform int frameCounter;
uniform int heldItemId;
uniform int heldItemId2;
uniform int isEyeInWater;
uniform int worldTime;

uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float wetness;
uniform float screenBrightness; 
uniform float shadowFade;
uniform float timeAngle;
uniform float timeBrightness;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;

uniform sampler2DShadow shadowtex0;
#ifdef ShadowColor
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

float eBS = eyeBrightnessSmooth.y/240.0;
float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;
float moonVisibility = clamp(dot(-sunVec,upVec)+0.05,0.0,0.1)/0.1;

vec3 lightVec = sunVec*(1.0-2.0*float(timeAngle > 0.5325 && timeAngle < 0.9675));

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float gradNoise(){
	return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y)+frameCounter/8.0);
}

#include "lib/color/waterColor.glsl"
#include "lib/color/lightColor.glsl"
#include "lib/color/lightColorDynamic.glsl"
#include "lib/color/torchColor.glsl"
#include "lib/common/spaceConversion.glsl"
#include "lib/common/materialDef.glsl"

#if AA == 2
#include "lib/common/jitter.glsl"
#endif

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord) * color;
	vec3 newnormal = normal;
	
	if (albedo.a > 0.0){
		//NDC Coordinate
		#if AA == 2
		vec3 fragpos = toNDC(vec3(taaJitter(gl_FragCoord.xy/vec2(viewWidth,viewHeight),-0.5),gl_FragCoord.z+0.38));
		#else
		vec3 fragpos = toNDC(vec3(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z+0.38));
		#endif

		//World Space Coordinate
		vec3 worldpos = toWorld(fragpos);
		
		float doRecolor = float((heldItemId  == 89.0 || heldItemId  == 138.0 || heldItemId  == 169.0 || heldItemId  == 213.0) && isMainHand > 0.5);
			  doRecolor+= float((heldItemId2  == 89.0 || heldItemId2  == 138.0 || heldItemId2  == 169.0 || heldItemId2 == 213.0) && isMainHand < 0.5);
		#ifdef EmissiveRecolor
		vec3 rawtorch_c = Torch*Torch/TorchS;
		if (doRecolor > 0.5){
			float ec = clamp(pow(length(albedo.rgb),1.4),0.0,2.2);
			albedo.rgb = clamp(ec*rawtorch_c*0.25+ec*0.25,vec3(0.0),vec3(2.2));
		}
		#else
		if (doRecolor > 0.5) albedo.rgb *= 0.5 * luma(albedo.rgb) + 0.25;
		#endif
		
		//Convert to linear color space
		albedo.rgb = pow(albedo.rgb, vec3(2.2));
		
		#ifdef DisableTexture
		albedo.rgb = vec3(0.5);
		#endif
		
		//Lightmap
		float torchmap = clamp(lmcoord.x, 0.0, 1.0);
		float skymap = clamp(lmcoord.y, 0.0, 1.0);
		
		torchmap = max(torchmap,float(heldItemId == 213));
		
		//Shadows
		float shadow = 0.0;
		vec3 shadowcol = vec3(0.0);
		
		float NdotL = clamp(dot(newnormal,lightVec)*1.05-0.05,0.0,1.0);
		float quarterNdotU = clamp(0.25 * dot(normal, upVec) + 0.75,0.5,1.0);
		quarterNdotU *= quarterNdotU;
		
		worldpos = toShadow(worldpos);
		
		float distb = sqrt(worldpos.x * worldpos.x + worldpos.y * worldpos.y);
		float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
		
		worldpos.xy /= distortFactor;
		worldpos.z *= 0.2;
		worldpos = worldpos*0.5+0.5;
		
		if (NdotL > 0.0 && skymap > 0.001){
			float NdotLm = NdotL * 0.9524 + 0.0476;
			float diffthresh = (8.0 * distortFactor * distortFactor * sqrt(1.0 - NdotLm *NdotLm) / NdotLm * pow(shadowDistance/256.0, 2.0) + 0.05) / shadowMapResolution;
			float step = 1.0/shadowMapResolution;

			worldpos.z -= diffthresh;
			
			#if AA == 2
			float noise = gradNoise()*3.14;
			vec2 rot = vec2(cos(noise),sin(noise))*step;
			#endif
			
			#ifdef ShadowFilter
			#if AA == 2
			shadow = shadow2D(shadowtex0,vec3(worldpos.st+rot, worldpos.z)).x;
			shadow+= shadow2D(shadowtex0,vec3(worldpos.st-rot, worldpos.z)).x;
			shadow+= shadow2D(shadowtex0,vec3(worldpos.st, worldpos.z)).x*0.5;
			shadow*= 0.4;
			#else
			shadow = shadow2D(shadowtex0,vec3(worldpos.st, worldpos.z)).x*2.0;
			shadow+= shadow2D(shadowtex0,vec3(worldpos.st+vec2(step,0), worldpos.z)).x;
			shadow+= shadow2D(shadowtex0,vec3(worldpos.st+vec2(-step,0), worldpos.z)).x;
			shadow+= shadow2D(shadowtex0,vec3(worldpos.st+vec2(0,step), worldpos.z)).x;
			shadow+= shadow2D(shadowtex0,vec3(worldpos.st+vec2(0,-step), worldpos.z)).x;
			shadow+= shadow2D(shadowtex0,vec3(worldpos.st+vec2(step,step)*0.7, worldpos.z)).x;
			shadow+= shadow2D(shadowtex0,vec3(worldpos.st+vec2(step,-step)*0.7, worldpos.z)).x;
			shadow+= shadow2D(shadowtex0,vec3(worldpos.st+vec2(-step,step)*0.7, worldpos.z)).x;
			shadow+= shadow2D(shadowtex0,vec3(worldpos.st+vec2(-step,-step)*0.7, worldpos.z)).x;
			shadow*= 0.1;
			#endif
			#else
			shadow = shadow2D(shadowtex0,vec3(worldpos.st, worldpos.z)).x;
			#endif
			
			if (shadow < 0.999){
				#ifdef ShadowColor
					#ifdef ShadowFilter
					#if AA == 2
					shadowcol = texture2D(shadowcolor0,worldpos.st+rot).rgb*shadow2D(shadowtex1,vec3(worldpos.st+rot, worldpos.z)).x;
					shadowcol+= texture2D(shadowcolor0,worldpos.st-rot).rgb*shadow2D(shadowtex1,vec3(worldpos.st-rot, worldpos.z)).x;
					shadowcol+= texture2D(shadowcolor0,worldpos.st).rgb*shadow2D(shadowtex1,vec3(worldpos.st, worldpos.z)).x*0.5;
					shadowcol*= 0.4;
					#else
					shadowcol = texture2D(shadowcolor0,worldpos.st).rgb*shadow2D(shadowtex1,vec3(worldpos.st, worldpos.z)).x;
					shadowcol+= texture2D(shadowcolor0,worldpos.st+vec2(step,0)).rgb*shadow2D(shadowtex1,vec3(worldpos.st+vec2(step,0), worldpos.z)).x;
					shadowcol+= texture2D(shadowcolor0,worldpos.st+vec2(-step,0)).rgb*shadow2D(shadowtex1,vec3(worldpos.st+vec2(-step,0), worldpos.z)).x;
					shadowcol+= texture2D(shadowcolor0,worldpos.st+vec2(0,step)).rgb*shadow2D(shadowtex1,vec3(worldpos.st+vec2(0,step), worldpos.z)).x;
					shadowcol+= texture2D(shadowcolor0,worldpos.st+vec2(0,-step)).rgb*shadow2D(shadowtex1,vec3(worldpos.st+vec2(0,-step), worldpos.z)).x;
					shadowcol+= texture2D(shadowcolor0,worldpos.st+vec2(step,step)*0.7).rgb*shadow2D(shadowtex1,vec3(worldpos.st+vec2(step,step)*0.7, worldpos.z)).x;
					shadowcol+= texture2D(shadowcolor0,worldpos.st+vec2(step,-step)*0.7).rgb*shadow2D(shadowtex1,vec3(worldpos.st+vec2(step,step)*0.7, worldpos.z)).x;
					shadowcol+= texture2D(shadowcolor0,worldpos.st+vec2(-step,step)*0.7).rgb*shadow2D(shadowtex1,vec3(worldpos.st+vec2(step,step)*0.7, worldpos.z)).x;
					shadowcol+= texture2D(shadowcolor0,worldpos.st+vec2(-step,-step)*0.7).rgb*shadow2D(shadowtex1,vec3(worldpos.st+vec2(step,step)*0.7, worldpos.z)).x;
					shadowcol*=0.1;
					#endif
					#else
					shadowcol = texture2D(shadowcolor0,worldpos.st).rgb*shadow2D(shadowtex1,vec3(worldpos.st, worldpos.z)).x;
					#endif
				#endif
			}
		}
		
		vec3 fullshading = max(vec3(shadow), shadowcol) * NdotL;
		float lightmult = (4.0-3.0*eBS);
		
		//Lighting Calculation
		vec3 scenelight = (mix(ambient, light, fullshading * (shadowFade * (1.0-0.95*rainStrength))) * lightmult)  * skymap * skymap;
		float newtorchmap = pow(torchmap,10.0)*(EmissiveBrightness+0.5)+(torchmap*0.7);
		
		vec3 blocklight = (newtorchmap * newtorchmap) * torch_c;
		float minlight = (0.009*screenBrightness + 0.001)*(1.0-eBS);
		
		float emissive = 0.0;
		vec3 emissivelight = albedo.rgb * luma(albedo.rgb) * (emissive * 4.0 / quarterNdotU);
		
		vec3 finallight = scenelight + blocklight + emissivelight + nightVision + minlight;
		albedo.rgb /= sqrt(albedo.rgb * albedo.rgb + 1.0);
		albedo.rgb *= finallight * quarterNdotU;
		
		#ifdef Desaturation
		float desat = clamp(max(sqrt(sqrt(length(fullshading/3)))*skymap,skymap)*sunVisibility*(1-rainStrength*0.4) + sqrt(torchmap) + emissive, DesaturationFactor * 0.3, 1.0);
		vec3 desat_c = mix(vec3(0.1),mix(weather*0.5, light_n/(LightNS*LightNS), (1.0 - sunVisibility)*(1.0 - rainStrength)),sqrt(skymap))*(1.0-desat);
		albedo.rgb = mix(luma(albedo.rgb)*desat_c*10.0,albedo.rgb,desat);
		#endif
        albedo.a = mix(albedo.a, 1.0, 0.6);
        if (isEyeInWater == 1.0) {
            albedo.rgb = mix(Water * albedo.rgb, albedo.rgb, min(0.8,eBS * 0.1));
        }
	}
	
/* DRAWBUFFERS:023 */
    gl_FragData[0] = albedo;
    gl_FragData[1] = vec4(0.0, 0.0, trans_mat, 0.5);
    gl_FragData[2] = vec4(albedo.rgb,albedo.a);
}