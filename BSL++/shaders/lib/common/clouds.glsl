#define CloudQuality 4	//[4 8]
#define CloudThickness 4 //[1 2 4 8 16]
#define CloudAmount 11.0 //[13.0 12.0 11.0 10.0 9.0]
#define CloudHeight 15.0 //[5.0 10.0 15.0 20.0 25.0]
#define CloudOpacity 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define CloudSpeed 1.00 //[0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00 2.50 3.00 3.50 4.00]
#define CloudBrightness 1.00 //[0.25 0.50 1.00 1.50 2.00 2.50 3.00 3.50 4.00 4.50 5.00 5.50 6.00 6.50 7.00 7.50 8.00 8.50 9.00 9.50 10.00]

float cloudNoise(vec2 coord, vec2 wind){
	float noise = texture2D(noisetex,coord*0.5+wind*0.55).x;
		  noise+= texture2D(noisetex,coord*0.25+wind*0.45).x*2;
		  noise+= texture2D(noisetex,coord*0.125+wind*0.35).x*3;
		  noise+= texture2D(noisetex,coord*0.0625+wind*0.25).x*4;
		  noise+= texture2D(noisetex,coord*0.03125+wind*0.15).x*5;
		  noise+= texture2D(noisetex,coord*0.016125+wind*0.05).x*6;
	return noise;
}

float cloudCoverage(float noise, float cosT, float step){
	return max(mix(noise, 21.0, 0.33 * rainStrength) * clamp(sqrt(cosT * 10.0), 0.0, 1.0) - ((step * step) + CloudAmount), 0.0) * (1.0 - 0.5 * rainStrength);
}

vec4 drawCloud(vec3 fragpos, float dither, vec3 color, vec3 light, vec3 ambient) {
	float cosT = dot(normalize(fragpos),upVec);
	float cosS = dot(normalize(fragpos),sunVec);
	const float pi = 3.1415927;

	#if AA == 2
	dither = fract(dither + frameTimeCounter);
	#endif
	
	vec2 wind = vec2(frametime*CloudSpeed*0.001,sin(frametime*CloudSpeed*0.1)*0.002) * CloudHeight / 15.0;

	float cloud = 0.0;
	vec3 cloudcolor = vec3(0.0);
	float cloudgradient = 0.0;
	float colmix = dither/CloudQuality;
	float colmult = CloudBrightness*(0.5-0.25*(1.0-sunVisibility));
		  colmult*= 0.45/SkyBrightness;
	float scattering = pow(cosS*0.5*(2.0*sunVisibility-1.0)+0.5,6.0);

	if (cosT > 0.1){
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(fragpos,1.0)).xyz);
		for (int i = 0; i < CloudQuality; i++) {
			vec3 intersection = wpos*((CloudHeight+(i+dither)*4.0/CloudQuality)/wpos.y) * 0.004;
			vec2 coord = cameraPosition.xz * 0.00025 + intersection.xz;
			float noise = 0.0;
			
			if (cloud < 0.999){
				noise = cloudNoise(coord,wind);
				noise = cloudCoverage(noise, cosT, float(i-0.5*CloudQuality+dither)*4.0/CloudQuality) * (CloudThickness / 4.0) * sqrt(sqrt(8.0 / CloudQuality));
				noise = noise/sqrt(sqrt((noise*noise)*(noise*noise)+1.0));
			}
			cloudgradient = mix(cloudgradient,mix(colmix * colmix, 1.0-noise, 0.25),noise*(1.0-cloud*cloud));
			cloud = max(cloud,noise);
			colmix += 1.0/CloudQuality;
		}
		cloudcolor = mix(ambient*(0.5*sunVisibility+0.5),light*(1.0+scattering),cloudgradient*cloud);
		cloudcolor*= (1.0+nightVision)*(1.0-0.6*rainStrength);
		cloud *= sqrt(sqrt(clamp(cosT*10.0-1.0,0.0,1.0)))*(1.0-0.6*rainStrength);
	}
	return vec4(cloudcolor*colmult,cloud*cloud*CloudOpacity);
}

float getnoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

vec3 drawStars(vec3 fragpos, vec3 color, vec3 light){
	vec3 wpos = vec3(gbufferModelViewInverse * vec4(fragpos,1.0));
	vec3 intersection = wpos/(wpos.y+length(wpos.xz));
	vec2 wind = vec2(frametime,0.0);
	vec2 coord = floor((intersection.xz*0.4+cameraPosition.xz*0.0001+wind*0.00125)*1024.0)/1024.0;
	
	float NdotU = sqrt(sqrt(max(dot(normalize(fragpos),normalize(upVec)),0.0)));
	
	float star = 1.0;
	if (NdotU > 0.0){
		star *= getnoise(coord.xy);
		star *= getnoise(coord.xy+0.1);
		star *= getnoise(coord.xy+0.23);
	}
	star = max(star-0.825,0.0)*5.0*NdotU*(1.0-rainStrength)*moonVisibility;
		
	return color + star*pow(light,vec3(0.8));
}