#define WeatherVaried

#ifdef WeatherVaried
uniform float isDesert;
uniform float isMesa;
uniform float isCold;
uniform float isSwamp;
uniform float isMushroom;
#endif


#ifdef WeatherVaried
vec3 calcWeatherColor(vec3 rain, vec3 desert, vec3 mesa, vec3 cold, vec3 swamp, vec3 mushroom){
	vec3 weather = rain;
	float weatherweight = isCold + isDesert + isMesa + isSwamp + isMushroom;
	if (weatherweight < 0.001) return weather;
	else{
		vec3 weather2 = cold*isCold + desert*isDesert + mesa*isMesa + swamp*isSwamp + mushroom*isMushroom;
		return mix(weather,weather2/weatherweight,weatherweight);
	}
}

vec3 weather = calcWeatherColor(weather_r, weather_d, weather_b, weather_c, weather_s, weather_m);
#else
vec3 weather = weather_r;
#endif

float mefade = 1.0-clamp(abs(timeAngle-0.5)*8.0-1.5,0.0,1.0);

vec3 calcLightColor(vec3 morning, vec3 day, vec3 afternoon, vec3 night, vec3 weather){
	vec3 c = mix(night,mix(mix(morning,afternoon,mefade),day,timeBrightness),sunVisibility);
	return mix(c,dot(c,vec3(0.299, 0.587, 0.114))*4.0*weather,wetness);
}

vec3 light = calcLightColor(light_m, light_d, light_a, light_n, weather);
vec3 ambient = calcLightColor(sky_m, sky_d, sky_e, sky_n, weather);