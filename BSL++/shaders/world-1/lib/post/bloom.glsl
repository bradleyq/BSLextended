#define BloomStrength 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00]

vec3 expandBloom(vec3 x){
	return x * x * x * x * 128.0;
}

vec3 bloom(vec3 color, vec2 coord){
	vec3 blur1 = expandBloom(texture2D(colortex1,coord/pow(2.0,2.0) + vec2(0.0,0.0)).rgb);
	vec3 blur2 = expandBloom(texture2D(colortex1,coord/pow(2.0,3.0) + vec2(0.0,0.26)).rgb);
	vec3 blur3 = expandBloom(texture2D(colortex1,coord/pow(2.0,4.0) + vec2(0.135,0.26)).rgb);
	vec3 blur4 = expandBloom(texture2D(colortex1,coord/pow(2.0,5.0) + vec2(0.2075,0.26)).rgb);
	vec3 blur5 = expandBloom(texture2D(colortex1,coord/pow(2.0,6.0) + vec2(0.135,0.3325)).rgb);
	vec3 blur6 = expandBloom(texture2D(colortex1,coord/pow(2.0,7.0) + vec2(0.160625,0.3325)).rgb);
	vec3 blur7 = expandBloom(texture2D(colortex1,coord/pow(2.0,8.0) + vec2(0.1784375,0.3325)).rgb);
	
	#ifdef DirtyLens
	float bAR = 1.777777777777778;
	float dirt = texture2D(depthtex2,(coord-0.5)/vec2(max(bAR/aspectRatio,1.0),max(aspectRatio/bAR,1.0))+0.5).r * length(blur6 / (1.0 + blur6));
	blur3 *= dirt + 0.5;
	blur4 *= dirt * 1.0 + 1.0;
	blur5 *= dirt * 2.0 + 1.0;
	blur6 *= dirt * 4.0 + 1.0;
	blur7 *= dirt * 8.0 + 1.0;
	#endif
	
	vec3 blur = (blur1 + blur2 + blur3 + blur4 + blur5 + blur6 + blur7) * 0.06;
	
	return mix(color,blur,0.16 * BloomStrength);
}