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
#define Clouds
#define Desaturation
#define DesaturationFactor 1.0 //[2.0 1.5 1.0 0.5 0.0]
//#define DisableTexture
#define EmissiveBrightness 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define EmissiveRecolor
#define Fog
#define FogRange 8 //[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 18 20 22 24 26 28 30 32 36 40 44 48 52 56 60 64]
#define Reflection
//#define ReflectionPrevious
#define SunBrightness 2500 //[125 250 500 1000 1500 2000 2500 3000 3500 4000 4500 5000 10000]
#define MoonBrightness 32 //[1 2 4 8 16 32 48 64 80 96 112 128]

#define POMQuality 32 //[4 8 16 32 64 128 256 512]
#define POMDepth 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00]
#define POMDistance 64.0 //[16.0 32.0 48.0 64.0 80.0 96.0 112.0 128.0]
#define POMShadowAngle 2.0 //[0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 5.5 6.0 6.5 7.0 7.5 8.0]
//#define RPSupport
#define RPSFormat 0 //[0 1 2 3]
#define RPSPOM
#define RPSReflection
#define RPSShadow

#define ShadowColor
#define ShadowFilter

#define WaterRefract
#define WaterNormals 1 //[0 1 2]
#define WaterParallax
#define WaterOctave 5 //[2 3 4 5 6 7 8]
#define WaterBump 3.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00 4.25 4.50 4.75 5.00]
#define WaterLacunarity 1.50 //[1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define WaterPersistance 0.80 //[0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90]
#define WaterSize 450.0 //[150.0 200.0 250.0 300.0 350.0 400.0 450.0 500.0 550.0 600.0 650.0 700.0 750.0]
#define WaterSharpness 0.10 //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40]
#define WaterSpeed 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00]

//#define WorldTimeAnimation
#define AnimationSpeed 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00 5.00 6.00 7.00 8.00]

const int shadowMapResolution = 2048; //[1024 2048 3072 4096 8192]
const float shadowDistance = 256.0; //[128.0 144.0 160.0 176.0 192.0 208.0 224.0 240.0 256.0 512.0 1024.0]
const float shadowMapBias = 1.0-25.6/shadowDistance;

varying float dist;
varying float mat;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 binormal;
varying vec3 normal;
varying vec3 sunVec;
varying vec3 tangent;
varying vec3 upVec;
varying vec3 viewVector;
varying vec3 wpos;

varying vec4 color;

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float blindness;
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

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D noisetex;

uniform sampler2DShadow shadowtex0;
#ifdef ShadowColor
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

float eBS = eyeBrightnessSmooth.y/240.0;
//float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.1)/0.1;
//float moonVisibility = clamp(dot(-sunVec,upVec)+0.05,0.0,0.1)/0.1;

float sunVisibility = clamp(dot(sunVec,upVec)+0.05,0.0,0.3)/0.3;
float moonVisibility = clamp(dot(-sunVec,upVec)+0.05,0.0,0.3)/0.3;

vec3 lightVec = sunVec*(1.0-2.0*float(timeAngle > 0.5325 && timeAngle < 0.9675));

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float gradNoise(){
	return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y)+frameCounter/8.0);
}

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

float waterH(vec3 pos, vec3 fpos, float anim) {
	float noise = 0;

	float mult = clamp((-dot(normalize(normal),normalize(fpos)))*8.0,0.0,1.0)/sqrt(sqrt(max(dist,4.0)));
	float lacunarity = 1.0;
	float persistance = 1.0;
	float weight = 0.0;
    float time = frametime * anim;
	
	if (mult > 0.01){
		#if WaterNormals == 1
        noise = sin(length(pos.xz) + time) * (max(texture2D(noisetex,(pos.x+vec2(time)*0.3-pos.y*0.3)/(512.0 * 3)).r, 0.3) - 0.3) * 2.5;
        noise -= sin(length(pos.xz) + time) * (max(texture2D(noisetex,(pos.xz+vec2(time)*0.3+pos.y*0.4)/(512.0 * 2)).r, 0.3) - 0.3) * 2.5;
		noise += texture2D(noisetex,(pos.xz+vec2(time)*0.5-pos.y*0.2)/512.0* 1.1).r*1.0;
		noise -= texture2D(noisetex,(pos.xz+vec2(time)*0.5+pos.y*0.2)/512.0* 2.5).r*0.6;
		noise += texture2D(noisetex,(pos.xz-vec2(time)*0.5-pos.y*0.2)/512.0* 5.0).r*0.4;
		noise -= texture2D(noisetex,(pos.xz+vec2(time)*0.5+pos.y*0.2)/512.0* 8.0).r*0.2;
		noise *= mult;
		#endif
		#if WaterNormals == 2
		for(int i = 0; i < WaterOctave; i++){
			float mult = (mod(i,2))*2.0-1.0;
			noise += texture2D(noisetex,(pos.xz+vec2(time)*WaterSpeed*0.5*mult+pos.y*0.2*mult)/WaterSize * lacunarity).r*persistance*mult;
			if (i==0) noise = -noise;
			weight += persistance;
			lacunarity *= WaterLacunarity;
			persistance *= WaterPersistance;
		}
		noise *= mult * WaterBump / weight * WaterSize / 450.0;
		#endif
	}

	return noise;
}

vec3 getParallaxWaves(vec3 posxz, vec3 viewVector,vec3 fragpos) {
	vec3 parallaxPos = posxz;
	float waveH = (waterH(posxz,fragpos.xyz, 1.0)-0.5)*0.2;
	
	for(int i = 0; i < 4; i++){
		parallaxPos.xz += waveH*(viewVector.xy)/dist;
		waveH = (waterH(parallaxPos,fragpos.xyz, 1.0)-0.5)*0.2;
	}
	return parallaxPos;
}

const int maxf = 4;				//number of refinements
const float stp = 1.2;			//size of one step for raytracing algorithm
const float ref = 0.1;			//refinement multiplier
const float inc = 1.8;			//increasement factor at each step

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}

vec4 raytrace(vec3 fragpos, vec3 normal, float dither) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector * (dither * 0.125 + 0.9375);
    int sr = 0;
	float border = 0.0;
	vec3 pos = vec3(0.0);
    for(int i=0;i<30;i++){
        pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
		if (pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1) break;
		float depth = texture2D(gaux1, pos.st).r;
		vec3 spos = vec3(pos.st, depth);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = abs(length(fragpos.xyz-spos.xyz));
		if (err < pow(length(vector)*pow(length(tvector),0.11),1.1)*1.5){
                sr++;
                if (sr >= maxf){
                    break;
                }
				tvector -=vector;
                vector *=ref;
		}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
	
	if (pos.z <1.0-1e-5){
		#ifdef ReflectionPrevious
		//Previous frame reprojection from Chocapic13
		vec4 fragpositionPrev = gbufferProjectionInverse * vec4(pos*2.0-1.0,1.);
		fragpositionPrev /= fragpositionPrev.w;
		
		fragpositionPrev = gbufferModelViewInverse * fragpositionPrev;

		vec4 previousPosition = fragpositionPrev + vec4(cameraPosition-previousCameraPosition,0.0);
		previousPosition = gbufferPreviousModelView * previousPosition;
		previousPosition = gbufferPreviousProjection * previousPosition;
		previousPosition.xy = previousPosition.xy/previousPosition.w*0.5+0.5;
		
		color.a = texture2D(gaux2, previousPosition.st).a;
		//color.a = 1.0;
		if (color.a > 0.5){
			color.rgb = texture2D(gaux2, previousPosition.st).rgb;
			color.rgb = pow(color.rgb*2.0,vec3(8.0));
		}
		#else
		color.a = texture2D(gaux2, pos.st).a;
		//color.a = 1.0;
		if (color.a > 0.5){
			color.rgb = texture2D(gaux2, pos.st).rgb;
			color.rgb = pow(color.rgb*2.0,vec3(8.0));
		}
		#endif
		
		border = clamp(1.0 - pow(cdist(pos.st), 200.0), 0.0, 1.0);
		color.a *= border;
	}
	
    return color;
}

vec2 getRefraction(vec3 fragpos, vec3 wnormal) {
	float waterRefractionStrength = 0.015;
	//vec2 waterTexcoord = texcoord.xy;
	waterRefractionStrength *= mix(0.2, 1.0, exp(-pow(length(fragpos.xyz) * 0.04, 1.5)));
    vec2 waterTexcoord = wnormal.xy * waterRefractionStrength;//gl_FragCoord.xy/vec2(viewWidth,viewHeight) + 
    return waterTexcoord;
}

#include "lib/color/lightColor.glsl"
#include "lib/color/lightColorDynamic.glsl"
#include "lib/color/skyColor.glsl"
#include "lib/color/torchColor.glsl"
#include "lib/color/waterColor.glsl"
#include "lib/common/clouds.glsl"
#include "lib/common/dither.glsl"
#include "lib/common/fog.glsl"
#include "lib/common/ggx.glsl"
#include "lib/common/sky.glsl"
#include "lib/common/spaceConversion.glsl"
#include "lib/common/materialDef.glsl"

#if AA == 2
#include "lib/common/jitter.glsl"
#endif

void main(){
    //Material Flag
    float water = float(matches(mat, water_mat));
    float translucent = float(matches(mat, trans_mat));

	//Texture
	vec4 albedo = texture2D(texture, texcoord) * vec4(color.rgb,1.0);

    vec4 finalspec = vec4(0.0);

    //NDC Coordinate
    #if AA == 2
    vec3 fragpos = toNDC(vec3(taaJitter(gl_FragCoord.xy/vec2(viewWidth,viewHeight),-0.5),gl_FragCoord.z));
    #else
    vec3 fragpos = toNDC(vec3(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z));
    #endif

    //World Space Coordinate
    vec3 worldpos = toWorld(fragpos);
    
    //Normal Mapping
    vec3 newnormal = normal;
    vec3 normalmap = vec3(0.0,0.0,1.0);
    mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
                            tangent.y, binormal.y, normal.y,
                            tangent.z, binormal.z, normal.z);
                            
    #if WaterNormals == 1 || WaterNormals == 2
    float animated = water > 0.5 ? 1.0 : 0.0;
    vec3 posxz = wpos.xyz;
    #ifdef WaterParallax
    if (water > 0.5) {
        posxz = getParallaxWaves(posxz,viewVector,fragpos.xyz);
    } else {
        posxz /= 5.0;
    }
    #endif
    
    #if WaterNormals == 2
    float deltaPos = WaterSharpness;
    #else
    float deltaPos = 0.1;
    #endif
    #ifdef WaterDistantWave
    deltaPos += 0.3*clamp(dist/64.0-0.25,0.0,1.0);
    #endif
    float h0 = waterH(posxz,fragpos.xyz, animated);
    float h1 = waterH(posxz + vec3(deltaPos,0.0,0.0),fragpos.xyz, animated);
    //float h2 = waterH(posxz + vec3(-deltaPos,0.0,0.0),fragpos.xyz, animated);
    float h3 = waterH(posxz + vec3(0.0,0.0,deltaPos),fragpos.xyz, animated);
    //float h4 = waterH(posxz + vec3(0.0,0.0,-deltaPos),fragpos.xyz, animated);
    
    float xDelta = (h1-h0)/deltaPos * (0.1 + 0.9 * animated);
    float yDelta = (h3-h0)/deltaPos * (0.1 + 0.9 * animated);
    
    normalmap = vec3(xDelta,yDelta,1.0-xDelta*xDelta-yDelta*yDelta);
    
    float bumpmult = 0.07;	
    
    newnormal = normalize((normalmap * vec3(bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult)) * tbnMatrix);
    #endif
    
    //Convert to linear color space
    albedo.rgb = pow(albedo.rgb, vec3(2.2));
    
    #ifdef DisableTexture
    albedo.rgb = vec3(0.5);
    #endif
    
    //Lightmap
    float torchmap = 0.0;//clamp(lmcoord.x, 0.0, 1.0);
    float skymap = 1.0;//clamp(lmcoord.y, 0.0, 1.0);
    
    #ifndef WaterVanilla
    if (water > 0.5){
        albedo = vec4(Water * WaterS, 0.8);
        //albedo.rgb *= albedo.rgb;
    }
    #endif
    
    //Shadows
    float shadow = 0.0;
    vec3 shadowcol = vec3(0.0);
    
    float NdotL = clamp(dot(newnormal,lightVec)*1.05-0.05,0.0,1.0);
    float quarterNdotU = clamp(0.25 * dot(newnormal, upVec) + 0.75,0.5,1.0);
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
    //float lightmult = (4.0-3.0*eBS);
    
    //Lighting Calculation CANCER
    //vec3 scenelight = (mix(ambient, light, fullshading * (shadowFade * (1.0-0.95*rainStrength))) * lightmult)  * skymap * skymap;
    //float newtorchmap = pow(torchmap,10.0)*(EmissiveBrightness+0.5)+(torchmap*0.7);
    
    //vec3 blocklight = (newtorchmap * newtorchmap) * torch_c;
    //float minlight = (0.009*screenBrightness + 0.001)*(1.0-eBS);
    //float ao = color.a;
    
    //vec3 finallight = (scenelight + blocklight + nightVision + minlight) * ao;
    if (translucent > 0.5) albedo.a = pow(albedo.a, 0.25);
    //albedo.rgb *= finallight * quarterNdotU;
    
    #ifdef Desaturation
    float desat = clamp(max(sqrt(sqrt(length(fullshading/3)))*skymap,skymap)*sunVisibility*(1-rainStrength*0.4) + sqrt(torchmap), DesaturationFactor * 0.3, 1.0);
    vec3 desat_c = mix(vec3(0.1),mix(weather*0.5, light_n/(LightNS*LightNS), (1.0 - sunVisibility)*(1.0 - rainStrength)),sqrt(skymap))*(1.0-desat);
    albedo.rgb = mix(luma(albedo.rgb)*desat_c*10.0,albedo.rgb,desat);
    #endif
    
    float fresnel = pow(1.0 + min(0.0,dot(newnormal, normalize(fragpos.xyz))),7.0 - isEyeInWater * 6.0);
    fresnel = (0.9 + 0.05 * water) * fresnel + 0.1 * translucent + 0.05;
    float dither = bayer64(gl_FragCoord.xy);

    finalspec.a = clamp(fresnel,0.0,1.0);

    vec4 reflection = vec4(0.0);
    vec3 skyRef = vec3(0.0);

    //fresnel = (fresnel*0.9 + 0.02) * (1.0-translucent*0.5);  //* max(1.0-isEyeInWater*0.75*water,0.25)
    
    if (isEyeInWater > 0.98 && water > 0.5) {
        reflection = vec4(water_c * max(sunVisibility, 0.01) * WaterS, 1.0);
        albedo.a = 0.1;
    }
    #ifdef Reflection
    else {
        reflection = raytrace(fragpos.xyz,newnormal,dither);
    }
    #endif

    if (reflection.a < 1.0){
        vec3 skyRefPos = reflect(normalize(fragpos.xyz),newnormal);
        skyRef = getSkyColor(skyRefPos,light,ambient);
        
        float sun = GGX(newnormal,normalize(fragpos.xyz),lightVec,0.03,0.02) * (1.0-sqrt(rainStrength)) * shadowFade;
        vec3 light_me = mix(light_m,light_a,mefade);
        vec3 speccol = mix(sqrt(light_n),mix(light_me,sqrt(light_d*light_me),timeBrightness),sunVisibility);
        speccol = (sun / (4.0-3.0*eBS)) * speccol * max(vec3(shadow),shadowcol);
        skyRef += (MoonBrightness + (SunBrightness * 0.5 - MoonBrightness) * max(dot(sunVec,upVec), 0.0)) * speccol * 0.8;
        #ifdef Clouds
        vec4 cloud = drawCloud(skyRefPos*2048.0, dither, skyRef, light, ambient);
        skyRef = mix(skyRef,cloud.rgb,cloud.a);
        #endif
        skyRef *= (4.0-3.0*eBS) * skymap * clamp(1.0-isEyeInWater,0.0,1.0);
    }
    
    reflection.rgb = mix(skyRef,reflection.rgb,reflection.a);
    
    finalspec.rgb = max(reflection.rgb,vec3(0.0));
    
    //Fog
    #ifdef Fog
    //albedo.rgb = calcFog(albedo.rgb,fragpos.xyz, blindness);
    //finalspec.rgb = calcBlindFog(finalspec.rgb,fragpos.xyz, blindness);
    #endif

    //finalspec.a = max(0.1001, finalspec.a);
	
/* DRAWBUFFERS:13 */
	gl_FragData[0] = albedo;
    gl_FragData[1] = finalspec;
    
#ifdef WaterRefract
/* DRAWBUFFERS:132 */
if (water > 0.5) {
    gl_FragData[2] = vec4(getRefraction(fragpos, normalize(normalmap)), water_mat, 1.0);
} else {
    gl_FragData[2] = vec4(0.0,0.0,trans_mat,0.5);
}
#endif
}