#define AOStrength 1.50	//[1.00 1.25 1.50 1.75 2.00]

float dither5x3()
{
	const int ditherPattern[15] = int[15](
		 9, 3, 7,12, 0,
		11, 5, 1,14, 8,
		 2,13,10, 4, 6);

    vec2 position = floor(mod(vec2(texcoord.s * viewWidth,texcoord.t * viewHeight), vec2(5.0,3.0)));

	int dither = ditherPattern[int(position.x) + int(position.y) * 5];

	return float(dither) / 15.0f;
}

float dbao(sampler2D depth, float dither){
	float ao = 0.0;
	
	const int aoloop = 3;
	#if AA == 2
	const int aoside = 2;
	dither = fract(dither + frameCounter/8.0);
	#else
	const int aoside = 4;
	#endif
	float radius = 0.75/aoloop;
	float dither2 = fract(dither5x3()-dither);
	float d = texture2D(depth,texcoord.xy).r;
	float hand = float(d < 0.56);
	d = ld(d);
	const float piangle = 0.0174603175;
	float rot = 90.0/aoside*dither2;
	#if AA == 2
	rot *= 2;
	#endif
	float size = radius*(dither*0.5+0.5);
	float sd = 0.0;
	float angle = 0.0;
	float dist = 0.0;
	vec2 scale = vec2(1.0/aspectRatio,1.0) * gbufferProjection[1][1] / (2.74747742 * max(far*d,6.0));
	
	for (int i = 0; i < aoloop; i++) {
		for (int j = 0; j < aoside; j++) {
			sd = ld(texture2D(depth,texcoord.xy+vec2(cos(rot*piangle),sin(rot*piangle)) * size * scale).r);
			float sample = far*(d-sd)/size;
			if (hand > 0.5) sample *= 1024.0;
			angle = clamp(0.5-sample,0.0,1.0);
			dist = clamp(0.0625*sample,0.0,1.0);

			sd = ld(texture2D(depth,texcoord.xy-vec2(cos(rot*piangle),sin(rot*piangle)) * size * scale).r);
			sample = far*(d-sd)/size;
			if (hand > 0.5) sample *= 1024.0;
			angle += clamp(0.5-sample,0.0,1.0);
			dist += clamp(0.0625*sample,0.0,1.0);
			
			ao += clamp(angle+dist,0.0,1.0);
			rot += 180.0/aoside;
		}
		rot += 180.0/aoside;
		size += radius;
		angle = 0.0;
		dist = 0.0;
	}
	ao /= aoloop*aoside;
	
	return pow(ao,AOStrength);
}