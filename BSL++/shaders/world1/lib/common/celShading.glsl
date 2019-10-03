const vec2 celshadeoffset[12] = vec2[12](vec2(-2.0,2.0),vec2(-1.0,2.0),vec2(0.0,2.0),vec2(1.0,2.0),vec2(2.0,2.0),vec2(-2.0,1.0),vec2(-1.0,1.0),vec2(0.0,1.0),vec2(1.0,1.0),vec2(2.0,1.0),vec2(1.0,0.0),vec2(2.0,0.0));

float celshade(sampler2D depth, float forcefull){
	float ph = 1.0/1080.0;
	float pw = ph/aspectRatio;

	float outline = 1.0;
	float z = ld(texture2D(depth,texcoord.xy).r)*far*2.0;
	float minz = far;
	float sampleza = 0.0;
	float samplezb = 0.0;

	#ifdef Fog
	float dist = FogRange*32.0;
	if (isEyeInWater > 0.5) dist = wfogrange*1.5;
	#else
	float dist = 4096.0;
	#endif

	for (int i = 0; i < 12; i++){
		sampleza = ld(texture2D(depth,texcoord.xy+vec2(pw,ph)*celshadeoffset[i]).r)*far;
		samplezb = ld(texture2D(depth,texcoord.xy-vec2(pw,ph)*celshadeoffset[i]).r)*far;
		outline *= clamp(1.0-(z-(sampleza+samplezb))*0.5,0.0,1.0);
		minz = min(minz,min(sampleza,samplezb));
	}
	outline = mix(outline,1.0,min(minz/dist,clamp(0.8+0.2*isEyeInWater,0.0,1.0))*(1.0-forcefull));

	return outline;
}

float celshademask(sampler2D depth0, sampler2D depth1){
	float ph = 1.0/540.0;
	float pw = ph/aspectRatio;

	float mask = 0.0;
	for (int i = 0; i < 12; i++){
		mask += float(texture2D(depth0,texcoord.xy+vec2(pw,ph)*celshadeoffset[i]).r < texture2D(depth1,texcoord.xy+vec2(pw,ph)*celshadeoffset[i]).r);
		mask += float(texture2D(depth0,texcoord.xy-vec2(pw,ph)*celshadeoffset[i]).r < texture2D(depth1,texcoord.xy-vec2(pw,ph)*celshadeoffset[i]).r);
	}

	return clamp(mask,0.0,1.0);
}

float bumpyedge(sampler2D depth) {
	//edge detect
	float ph = 1.0/540.0;
	float pw = ph/aspectRatio;
	float d = texture2D(depth,texcoord.xy).r;
	float dtresh = 1/(far-near)/120.0;
	vec4 dc = vec4(d,d,d,d);
	vec4 sa;
	vec4 sb;
	float dist = ld(texture2D(depth,texcoord.xy).r);
	sa.x = texture2D(depth,texcoord.xy + vec2(-pw,-ph)).r;
	sa.y = texture2D(depth,texcoord.xy + vec2(pw,-ph)).r;
	sa.z = texture2D(depth,texcoord.xy + vec2(-pw,0.0)).r;
	sa.w = texture2D(depth,texcoord.xy + vec2(0.0,ph)).r;

	//opposite side samples
	sb.x = texture2D(depth,texcoord.xy + vec2(pw,ph)).r;
	sb.y = texture2D(depth,texcoord.xy + vec2(-pw,ph)).r;
	sb.z = texture2D(depth,texcoord.xy + vec2(pw,0.0)).r;
	sb.w = texture2D(depth,texcoord.xy + vec2(0.0,-ph)).r;

	vec4 dda = (2.0* dc - sa - sb) - dtresh;
	vec4 ddb = abs(2.0* dc - sa - sb) - (2.0* dc - sa - sb) - dtresh;
	dda = vec4(step(dda.x,0.0),step(dda.y,0.0),step(dda.z,0.0),step(dda.w,0.0));
	ddb = vec4(step(ddb.x,0.0),step(ddb.y,0.0),step(ddb.z,0.0),step(ddb.w,0.0));

	float ea = (clamp(dot(dda,vec4(0.25)),0.0,1.0));
	float eb = (clamp(dot(ddb,vec4(0.25)),0.0,1.0));
	return (0.63+0.37*ea)*(1.37-0.37*eb);
}