vec3 calcNormalFog(vec3 color, vec3 fragpos){
float fog = length(fragpos)/(16.0*FogRange);
fog = 1.0-exp(-0.8*fog*fog);
return mix(color,end_c*0.01,fog);
}

vec3 calcBlindFog(vec3 color, vec3 fragpos, float blindness){
	float b = clamp(blindness*2.0-1.0,0.0,1.0);
	b = b*b;
	float fog = length(fragpos)/(5.0/b);
	fog = (1.0-exp(-6.0*fog*fog*fog))*b;
	return mix(color,vec3(0.0),fog);
}

vec3 calcLavaFog(vec3 color, vec3 fragpos){
	float fog = length(fragpos)/2.0;
	fog = (1.0-exp(-4.0*fog*fog*fog));
	#ifdef EmissiveRecolor
	return mix(color,pow(Torch/TorchS,vec3(4.0))*2.0,fog);
	#else
	return mix(color,vec3(1.0,0.3,0.01),fog);
	#endif
}

vec3 calcFog(vec3 color, vec3 fragpos, float blindness){
	color = calcNormalFog(color, fragpos);
	if (isEyeInWater == 2.0) color = calcLavaFog(color, fragpos);
	if (blindness > 0.0) color = calcBlindFog(color, fragpos, blindness);
	return color;
}