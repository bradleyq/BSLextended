#define TonemapExposure 4.0 //[1.0 1.4 2.0 2.8 4.0 5.6 8.0 11.3 16.0]
#define TonemapWhiteCurve 2.0 //[1.0 1.5 2.0 2.5 3.0 3.5 4.0]
#define TonemapLowerCurve 1.0 //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define TonemapUpperCurve 1.0 //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]

#define Saturation 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define Vibrance 1.00 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

vec3 BSLTonemap(vec3 x){
	x = TonemapExposure * x;
	x = x / pow(pow(x,vec3(TonemapWhiteCurve)) + 1.0,vec3(1.0/TonemapWhiteCurve));
	x = pow(x,mix(vec3(TonemapLowerCurve),vec3(TonemapUpperCurve),sqrt(x)));
	return x;
}

vec3 colorSaturation(vec3 x){
	float grayv = (x.r + x.g + x.b) / 3;
	float grays = grayv;
	if (Saturation < 1.0) grays = dot(x,vec3(0.299, 0.587, 0.114));

	float mn = min(x.r, min(x.g, x.b));
	float mx = max(x.r, max(x.g, x.b));
	float sat = (1.0-(mx-mn)) * (1.0-mx) * grayv * 5.0;
	vec3 lightness = vec3((mn+mx)*0.5);

	x = mix(x,mix(x,lightness,1.0-Vibrance),sat);
	x = mix(x, lightness, (1.0-lightness)*(2.0-Vibrance)/2.0*abs(Vibrance-1.0));

	return x * Saturation - grays * (Saturation - 1.0);
}