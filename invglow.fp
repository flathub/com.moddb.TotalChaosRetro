mat3 GetTBN();
uniform float timer;

Material ProcessMaterial()
{
    mat3 tbn = GetTBN();
    vec2 texCoord = vTexCoord.st;

    Material material;
    // Sample the glow effect based on time
    vec4 addEnv = texture(invglow, ((pixelpos.xyz).xy + (timer*30)) * 0.01);
	
    // Get the base color of the object
    material.Base = getTexel(texCoord);
	
    // FIX: Sum the effect but apply 'clamp' to block values at 1.0,
    // preventing the graphics card from burning the texture to pure white.
    material.Base.rgb = clamp(material.Base.rgb + (addEnv.rgb * 0.4), 0.0, 1.0);
	
    // Maintain the brightness of the effect mitigated to avoid blinding
    material.Bright = addEnv * 0.4;
    return material;
}

// Tangent/bitangent/normal space to world space transform matrix
mat3 GetTBN()
{
    vec3 n = normalize(vWorldNormal.xyz);
    vec3 p = pixelpos.xyz;
    vec2 uv = vTexCoord.st;

    // get edge vectors of the pixel triangle
    vec3 dp1 = dFdx(p);
    vec3 dp2 = dFdy(p);
    vec2 duv1 = dFdx(uv);
    vec2 duv2 = dFdy(uv);

    // solve the linear system
    vec3 dp2perp = cross(n, dp2); // cross(dp2, n);
    vec3 dp1perp = cross(dp1, n); // cross(n, dp1);
    vec3 t = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 b = dp2perp * duv1.y + dp1perp * duv2.y;

    // construct a scale-invariant frame
    float invmax = inversesqrt(max(dot(t,t), dot(b,b)));
    return mat3(t * invmax, b * invmax, n);
}