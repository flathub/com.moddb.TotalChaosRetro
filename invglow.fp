mat3 GetTBN();
uniform float timer;

// MINIMAL MODIFICATION 1 FOR UZDOOM 4.14+: Bring back the missing Normal function
vec3 GetBumpedNormal(mat3 tbn, vec2 texcoord);

Material ProcessMaterial()
{
    mat3 tbn = GetTBN();
    vec2 texCoord = vTexCoord.st;

    Material material;
    vec4 addEnv = texture(invglow, ((pixelpos.xyz).xy + (timer*30)) * 0.01);
	
    material.Base = getTexel(texCoord);
    material.Base.r += addEnv.r;
    material.Base.g += addEnv.g;
    material.Base.b += addEnv.b;
    
    // MINIMAL MODIFICATION 2 FOR UZDOOM 4.14+: Enforce a safety clamp on the base color
    material.Base.rgb = clamp(material.Base.rgb, 0.0, 1.0);
	
    // MINIMAL MODIFICATION 3 FOR UZDOOM 4.14+: Restore the Normal pipeline that UZDoom requires
    material.Normal = GetBumpedNormal(tbn, texCoord);
	
#if defined(SPECULAR)
    material.Specular = texture(speculartexture, texCoord).rgb;
    material.Glossiness = uSpecularMaterial.x;
    material.SpecularLevel = uSpecularMaterial.y;
#else
    // Fallback constants to prevent UZDoom from generating NaN errors on missing channels
    material.Specular = vec3(0.1) * addEnv.rgb;
    material.Glossiness = 5.0;
    material.SpecularLevel = 1.0;
#endif

#if defined(PBR)
    material.Metallic = texture(metallictexture, texCoord).r;
    material.Roughness = texture(roughnesstexture, texCoord).r;
    material.AO = texture(aotexture, texCoord).r;
#endif

    material.Bright = addEnv;
    return material;
}

// Tangent/bitangent/normal space to world space transform matrix
mat3 GetTBN()
{
    vec3 n = normalize(vWorldNormal.xyz);
    vec3 p = pixelpos.xyz;
    vec2 uv = vTexCoord.st;

    vec3 dp1 = dFdx(p); vec3 dp2 = dFdy(p); vec2 duv1 = dFdx(uv); vec2 duv2 = dFdy(uv);
    vec3 dp2perp = cross(n, dp2); vec3 dp1perp = cross(dp1, n);
    vec3 t = dp2perp * duv1.x + dp1perp * duv2.x; vec3 b = dp2perp * duv1.y + dp1perp * duv2.y;

    float invmax = inversesqrt(max(dot(t,t), dot(b,b)));
    return mat3(t * invmax, b * invmax, n);
}

// MINIMAL MODIFICATION 4 FOR UZDOOM 4.14+: Restore the missing BumpedNormal math block
vec3 GetBumpedNormal(mat3 tbn, vec2 texcoord)
{
#if defined(NORMALMAP)
    vec3 map = texture(normaltexture, texcoord).xyz;
    map = map * 255./127. - 128./127.; 
    map.xy *= vec2(0.5, -0.5); 
    return normalize(tbn * map);
#else
    return normalize(vWorldNormal.xyz);
#endif
}
