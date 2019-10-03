//GGX area light approximation from Horizon Zero Dawn
float GetNoHSquared(float radiusTan, float NoL, float NoV, float VoL)
{
    // radiusCos can be precalculated if radiusTan is a directional light
    float radiusCos = 1.0 / sqrt(1.0 + radiusTan * radiusTan);
    
    // Early out if R falls within the disc
    float RoL = 2.0 * NoL * NoV - VoL;
    if (RoL >= radiusCos)
        return 1.0;

    float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    // Calculate dot(cross(N, L), V). This could already be calculated and available.
    float triple = sqrt(clamp(1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL,0.0,1.0));
    
    // Do one Newton iteration to improve the bent light vector
    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;    
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * p + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr + 
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr; // use new T to update NoTr
    VoTr = cosTheta * VoTr + sinTheta * VoBr; // use new T to update VoTr
    
    // Calculate (N.H)^2 based on the bent light vector
    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;
    return max(0.0, NoH * NoH / HoH);
}

float GGX (vec3 n, vec3 v, vec3 l, float r, float F0) {
    r = max(0.02, r);
    r*=r;r*=r;
    
    vec3 h = normalize(l - v);

    float dotLH = clamp(dot(h, l), 0.0, 1.0);
    float dotNL = clamp(dot(n, l), 0.0, 1.0);
    float dotNH = GetNoHSquared(0.025 * sunVisibility + 0.025, dotNL, dot(n, -v), dot(-v, l));
    
    float denom = dotNH * r - dotNH + 1.0;
    float D = r / (3.141592653589793 * denom * denom);
    float F = exp2((-5.55473*dotLH-6.98316)*dotLH) * (1.0-F0) + F0;
    float k2 = r * 0.25;

    float specular = max(dotNL * dotNL * D * F / (dotLH*dotLH*(1.0-k2)+k2),0.0);
    specular = max(specular, 0.0) * (1.0 - r * (1.0 - F0));
    specular = specular / (0.125*specular + 1.0);

    return specular;
}