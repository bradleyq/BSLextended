vec3 getSkyColor(vec3 fragpos, vec3 light, vec3 ambient){
vec3 sky_col = sky_c;
vec3 nfragpos = normalize(fragpos);

float NdotU = clamp(dot(nfragpos,upVec),0.0,1.0);
float NdotS = clamp(dot(nfragpos,sunVec)*0.5+0.5,0.0,1.0);

float top = pow(max(NdotU,0.1),0.25)* SkyBrightness;
float horizon = pow(1.0-NdotU,8.0)*(0.4*sunVisibility+0.2)*(1-rainStrength*0.75);
float lightmix = (pow(NdotS, 0.5)*(1-0.6 * max(NdotU,0.0))*pow(1.0-timeBrightness,8.0) + horizon*0.1*timeBrightness)*sunVisibility*(1.0-rainStrength);

#ifdef SkyVanilla
sky_col = mix(sky_col,fog_c,max(1.0-NdotU,0.0));
#endif

float mult = 0.5 - top*(1.0-rainStrength*0.2) + horizon;

sky_col = (mix(sky_col*pow(max(1-lightmix,0.0),2.0),pow(light,vec3(2.0)),lightmix)*sunVisibility + light_n*0.4);
sky_col = mix(sky_col,weather*luma(ambient)*4.0,rainStrength)*mult;

return sky_col;
}