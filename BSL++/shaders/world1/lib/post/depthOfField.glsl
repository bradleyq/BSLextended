#define DOFStrength 8.0 //[1.0 2.0 4.0 8.0 16.0 32.0 64.0 128.0 256.0 512.0 1024.0]

const vec2 hqoffset[60] = vec2[60]  (  vec2( 0.0000, 0.2500 ),
									vec2( -0.2165, 0.1250 ),
									vec2( -0.2165, -0.1250 ),
									vec2( -0.0000, -0.2500 ),
									vec2( 0.2165, -0.1250 ),
									vec2( 0.2165, 0.1250 ),
									vec2( 0.0000, 0.5000 ),
									vec2( -0.2500, 0.4330 ),
									vec2( -0.4330, 0.2500 ),
									vec2( -0.5000, 0.0000 ),
									vec2( -0.4330, -0.2500 ),
									vec2( -0.2500, -0.4330 ),
									vec2( -0.0000, -0.5000 ),
									vec2( 0.2500, -0.4330 ),
									vec2( 0.4330, -0.2500 ),
									vec2( 0.5000, -0.0000 ),
									vec2( 0.4330, 0.2500 ),
									vec2( 0.2500, 0.4330 ),
									vec2( 0.0000, 0.7500 ),
									vec2( -0.2565, 0.7048 ),
									vec2( -0.4821, 0.5745 ),
									vec2( -0.51295, 0.3750 ),
									vec2( -0.7386, 0.1302 ),
									vec2( -0.7386, -0.1302 ),
									vec2( -0.51295, -0.3750 ),
									vec2( -0.4821, -0.5745 ),
									vec2( -0.2565, -0.7048 ),
									vec2( -0.0000, -0.7500 ),
									vec2( 0.2565, -0.7048 ),
									vec2( 0.4821, -0.5745 ),
									vec2( 0.51295, -0.3750 ),
									vec2( 0.7386, -0.1302 ),
									vec2( 0.7386, 0.1302 ),
									vec2( 0.51295, 0.3750 ),
									vec2( 0.4821, 0.5745 ),
									vec2( 0.2565, 0.7048 ),
									vec2( 0.0000, 1.0000 ),
									vec2( -0.2588, 0.9659 ),
									vec2( -0.5000, 0.8660 ),
									vec2( -0.7071, 0.7071 ),
									vec2( -0.8660, 0.5000 ),
									vec2( -0.9659, 0.2588 ),
									vec2( -1.0000, 0.0000 ),
									vec2( -0.9659, -0.2588 ),
									vec2( -0.8660, -0.5000 ),
									vec2( -0.7071, -0.7071 ),
									vec2( -0.5000, -0.8660 ),
									vec2( -0.2588, -0.9659 ),
									vec2( -0.0000, -1.0000 ),
									vec2( 0.2588, -0.9659 ),
									vec2( 0.5000, -0.8660 ),
									vec2( 0.7071, -0.7071 ),
									vec2( 0.8660, -0.5000 ),
									vec2( 0.9659, -0.2588 ),
									vec2( 1.0000, -0.0000 ),
									vec2( 0.9659, 0.2588 ),
									vec2( 0.8660, 0.5000 ),
									vec2( 0.7071, 0.7071 ),
									vec2( 0.5000, 0.8660 ),
									vec2( 0.2588, 0.9659 ));

const vec2 celshadeoffset[24] = vec2[24](vec2(-2.0,2.0),vec2(-1.0,2.0),vec2(0.0,2.0),vec2(1.0,2.0),vec2(2.0,2.0),vec2(-2.0,1.0),vec2(-1.0,1.0),vec2(0.0,1.0),vec2(1.0,1.0),vec2(2.0,1.0),vec2(-2.0,0.0),vec2(-1.0,0.0),vec2(1.0,0.0),vec2(2.0,0.0),vec2(-2.0,-1.0),vec2(-1.0,-1.0),vec2(0.0,-1.0),vec2(1.0,-1.0),vec2(2.0,-1.0),vec2(-2.0,-2.0),vec2(-1.0,-2.0),vec2(0.0,-2.0),vec2(1.0,-2.0),vec2(2.0,-2.0));

vec3 depthOfField(vec3 color){
	vec3 dof = vec3(0.0);
	
	float z = texture2D(depthtex1, texcoord.st).r;
	#ifdef Celshade
	float cph = 1.0/1080.0;
	float cpw = cph/aspectRatio;
	for (int i = 0; i < 24; i++){
		z = min(z,texture2D(depthtex1,texcoord.xy+vec2(cpw,cph)*celshadeoffset[i]).r);
	}
	#endif
	float hand = float(z < 0.56);
	
	float coc = max(abs(z-centerDepthSmooth)*DOFStrength-0.0001,0.0);
	coc = coc/sqrt(0.1+coc*coc);
	
	if (coc*0.015 > 1.0/max(viewWidth,viewHeight) && hand < 0.5){
		for (int i = 0; i < 60; ++i) {
			dof += texture2DLod(colortex0, texcoord.xy + hqoffset[i]*coc*0.015*vec2(1.0/aspectRatio,1.0),log2(viewHeight/180.0*aspectRatio/1.77777778)*coc).rgb;
		}
		dof /= 60.0;
	}
	else dof = color;
	return dof;
}