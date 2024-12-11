#define SHADOWS @shadows_enabled

#define SHADOWMAP_RES (1024.0)
#define FILTER_SIZE 8
// make it look more like natural sun radius smoothing
// also saves a couple samples and improves performance slightly on modern GPUs
#define DO_CIRCULAR 1


#if SHADOWS
    uniform float maximumShadowMapDistance;
    uniform float shadowFadeStart;
    @foreach shadow_texture_unit_index @shadow_texture_unit_list
        uniform sampler2DShadow shadowTexture@shadow_texture_unit_index;
        varying vec4 shadowSpaceCoords@shadow_texture_unit_index;

#if @perspectiveShadowMaps
        varying vec4 shadowRegionCoords@shadow_texture_unit_index;
#endif
    @endforeach
#endif // SHADOWS

float getFilteredShadowing(sampler2DShadow tex, vec4 coord)
{
    vec2 scale = vec2(1.0, 1.0) / (SHADOWMAP_RES) * coord.w;
    vec4 offs = vec4(1.0, 0.0, 0.0, 0.0) * vec4(scale, 1.0, 1.0);
    vec4 offs2 = vec4(0.0, 1.0, 0.0, 0.0) * vec4(scale, 1.0, 1.0);
    
// viewport-dependent filtering
#if 1
    vec3 coord2 = coord.xyz / coord.w;
    
    vec3 x_d = vec3(dFdx(coord2.x), dFdx(coord2.y), dFdx(coord2.z));
    vec3 y_d = vec3(dFdy(coord2.x), dFdy(coord2.y), dFdy(coord2.z));
    
    float stride_min_px = 2.0;
    offs = vec4(x_d, 0.0) * stride_min_px;
    offs2 = vec4(y_d, 0.0) * stride_min_px;
    
    // require filter to cover at least a certain number of texels
    float filter_min_texels = 2.0;
    float offs_l = length(offs.xy);
    if (offs_l < length(scale / float(FILTER_SIZE) * filter_min_texels))
        offs *= length(scale / float(FILTER_SIZE) * filter_min_texels)/offs_l;
    float offs2_l = length(offs2.xy);
    if (offs2_l < length(scale / float(FILTER_SIZE) * filter_min_texels))
        offs2 *= length(scale / float(FILTER_SIZE) * filter_min_texels)/offs2_l;
    
    // limit filter size to roughly a multiple of its "typical" size
    float mul_limit = 1.8;
    float offs_l2 = length(offs);
    if (offs_l2 > length(scale * mul_limit))
        offs *= length(scale * mul_limit)/offs_l2;
    float offs2_l2 = length(offs2);
    if (offs2_l2 > length(scale * mul_limit))
        offs2 *= length(scale * mul_limit)/offs2_l2;
#endif

    float amount = 0.0;
    float norm = 0.0;
    int size = (FILTER_SIZE);
    size = (size < 1) ? 1 : (size > 16) ? 16 : size;
    float ends = (size - 1.0) / 2.0;
#if DO_CIRCULAR
    float size2 = float(size/2.0);
    size2 *= size2;
#endif

#if 0
    float edge_offset = float(FILTER_SIZE) / 2.0 / SHADOWMAP_RES * mul_limit;
    coord.xy /= coord.w;
    coord.x = clamp(coord.x, edge_offset, 1.0 - edge_offset);
    coord.y = clamp(coord.y, edge_offset, 1.0 - edge_offset);
    coord.xy *= coord.w;
#endif

    for (float y = -ends; y < ends + 0.1; y++)
    {
        for (float x = -ends; x < ends + 0.1; x++)
        {
#if DO_CIRCULAR
            if (x*x + y*y > size2)
                continue;
#endif
            vec4 innercoord = coord + offs*float(x) + offs2*float(y);
            amount += shadow2DProj(tex, innercoord).r;
            norm += 1.0;
        }
    }
    amount /= norm;

    return amount;
}

float unshadowedLightRatio(float distance)
{
    float shadowing = 1.0;
#if SHADOWS
#if @limitShadowMapDistance
    float fade = clamp((distance - shadowFadeStart) / (maximumShadowMapDistance - shadowFadeStart), 0.0, 1.0);
    if (fade == 1.0)
        return shadowing;
#endif // limitShadowMapDistance
    bool doneShadows = false;
    @foreach shadow_texture_unit_index @shadow_texture_unit_list
        if (!doneShadows)
        {
            vec3 shadowXYZ = shadowSpaceCoords@shadow_texture_unit_index.xyz / shadowSpaceCoords@shadow_texture_unit_index.w;
#if @perspectiveShadowMaps
            vec3 shadowRegionXYZ = shadowRegionCoords@shadow_texture_unit_index.xyz / shadowRegionCoords@shadow_texture_unit_index.w;
#endif
            if (all(lessThan(shadowXYZ.xy, vec2(1.0, 1.0))) && all(greaterThan(shadowXYZ.xy, vec2(0.0, 0.0))))
            {
                float amount = getFilteredShadowing(shadowTexture@shadow_texture_unit_index, shadowSpaceCoords@shadow_texture_unit_index);
                shadowing = min(amount, shadowing);

                doneShadows = all(lessThan(shadowXYZ, vec3(0.95, 0.95, 1.0))) && all(greaterThan(shadowXYZ, vec3(0.05, 0.05, 0.0)));
#if @perspectiveShadowMaps
                doneShadows = doneShadows && all(lessThan(shadowRegionXYZ, vec3(1.0, 1.0, 1.0))) && all(greaterThan(shadowRegionXYZ.xy, vec2(-1.0, -1.0)));
#endif
            }
        }
    @endforeach
#if @limitShadowMapDistance
    shadowing = mix(shadowing, 1.0, fade);
#endif
#endif // SHADOWS
    return shadowing;
}

void applyShadowDebugOverlay()
{
#if SHADOWS && @useShadowDebugOverlay
    bool doneOverlay = false;
    float colourIndex = 0.0;
    @foreach shadow_texture_unit_index @shadow_texture_unit_list
        if (!doneOverlay)
        {
            vec3 shadowXYZ = shadowSpaceCoords@shadow_texture_unit_index.xyz / shadowSpaceCoords@shadow_texture_unit_index.w;
#if @perspectiveShadowMaps
            vec3 shadowRegionXYZ = shadowRegionCoords@shadow_texture_unit_index.xyz / shadowRegionCoords@shadow_texture_unit_index.w;
#endif
            if (all(lessThan(shadowXYZ.xy, vec2(1.0, 1.0))) && all(greaterThan(shadowXYZ.xy, vec2(0.0, 0.0))))
            {
                colourIndex = mod(@shadow_texture_unit_index.0, 3.0);
                if (colourIndex < 1.0)
                    gl_FragData[0].x += 0.1;
                else if (colourIndex < 2.0)
                    gl_FragData[0].y += 0.1;
                else
                    gl_FragData[0].z += 0.1;

                doneOverlay = all(lessThan(shadowXYZ, vec3(0.95, 0.95, 1.0))) && all(greaterThan(shadowXYZ, vec3(0.05, 0.05, 0.0)));
#if @perspectiveShadowMaps
                doneOverlay = doneOverlay && all(lessThan(shadowRegionXYZ.xyz, vec3(1.0, 1.0, 1.0))) && all(greaterThan(shadowRegionXYZ.xy, vec2(-1.0, -1.0)));
#endif
            }
        }
    @endforeach
#endif // SHADOWS
}