vec3 calcWaterFog(vec3 color, vec3 fragpos, vec3 wcol, float wstr, float fogrange){
float fog = length(fragpos)/fogrange;
fog = 1.0-exp(-3.0*fog*fog);
return mix(color,pow(wcol*cmult,vec3(2.0)),min(fog,1.0));
}