vec3 calcWaterFog(vec3 color, vec3 fragpos, vec3 wcol, float wstr, float fogrange){
    const float minimumBrightness = 0.01;
    float fog = 1.0 - exp(-length(fragpos.xyz) / fogrange);
    color = z < z1 ? color : color * Water;
    return mix(color, water_c * max(sunVisibility, minimumBrightness) * wstr, min(fog, 1.0));
}
