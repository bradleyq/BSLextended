float distx(float dist){
	return (far * (dist - near)) / (dist * (far - near));
}

float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

vec4 distortShadow(vec4 shadowpos, float distortFactor) {
shadowpos.xy *= 1.0f / distortFactor;
shadowpos.z = shadowpos.z*0.2;
shadowpos = shadowpos * 0.5f + 0.5f;

return shadowpos;
}

vec4 getShadowSpace(float shadowdepth, vec2 texcoord){
	vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.xy,shadowdepth,1.0)*2.0-1.0);
	fragpos /= fragpos.w;

	vec4 wpos = gbufferModelViewInverse * fragpos;
	wpos = shadowModelView * wpos;
	wpos = shadowProjection * wpos;
	wpos /= wpos.w;
	
	float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
	float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
	wpos = distortShadow(wpos,distortFactor);
	
	return wpos;
}

//Volumetric light from Robobo1221 (modified)
vec3 getVolumetricRays(float pixeldepth0, float pixeldepth1, vec3 color, float dither) {
	vec3 vl = vec3(0.0);

	#if AA == 2
	dither = fract(dither + frameCounter/64.0);
	#endif
	
	vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, pixeldepth0, 1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;
	
	float cosS = dot(normalize(fragpos.xyz),sunVec*(1.0-2.0*float(timeAngle > 0.5325 && timeAngle < 0.9675)));
	float visfactor = 0.05*(1.0-0.8*timeBrightness)*(3.0*rainStrength+1.0);
	float invvisfactor = 1.0-visfactor;

	float visibility = clamp(cosS*0.5+0.5,0.0,1.0);
	visibility = clamp((visfactor/(1.0-invvisfactor*visibility)-visfactor)*1.015/invvisfactor - 0.015,0.0,1.0);
	visibility = mix(1.0,visibility,0.25*eBS+0.75);

	if (visibility > 0.0){
		float sl = 1.0;
		float maxDist = 128.0;
		float minDist = 0.05;
		float samplemult = -0.5*dither+1.25;
		float slmult = 2.0;
		float w = 8.0;
		
		float depth0 = getDepth(pixeldepth0);
		float depth1 = getDepth(pixeldepth1);
		vec4 worldposition = vec4(0.0);
		
		vec3 watercol = water_c*water_c*sqrt(cmult);// /sqrt(water_a)
		
		for (minDist; minDist < maxDist; ) {
			minDist = dither*sl+minDist;
			if (depth1 < minDist || (depth0 < minDist && color == vec3(0.0))){
				break;
			}
			worldposition = getShadowSpace(distx(minDist),texcoord.st);
			if (length(worldposition.xy*2.0-1.0)<1.0){
				vec3 sample = vec3(shadow2D(shadowtex0, vec3(worldposition.xy, worldposition.z+0.00002)).z);
				vec3 colsample = vec3(0.0);
				#ifdef ShadowColor
				if (sample.r < 0.9){
					float testsample = shadow2D(shadowtex1, vec3(worldposition.xy, worldposition.z+0.00002)).z;
					if (testsample > 0.9) colsample = texture2D(shadowcolor0, worldposition.xy).rgb;
					sample = max(sample,colsample*colsample);
				}
				#endif
				if (depth0 < minDist) sample *= color;
				else if (isEyeInWater == 1.0) sample *= watercol;
				vl += sample*samplemult;
			}
			else{
				vl += 1.0;
			}
			minDist += sl*(1.0-dither);
			sl *= slmult;
			w += 1.0;
		}
		vl = sqrt(vl*visibility/w);
	};
	return vl;
}