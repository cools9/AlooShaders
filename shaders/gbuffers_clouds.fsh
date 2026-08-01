#version 330 compatibility

uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 shadowLightPosition;

in vec2 texcoord;
in vec4 glcolor;
in vec2 cellUV;

layout(location = 0) out vec4 color;

void main()
{
    vec4 cloud = glcolor;

    float dist2 = dot(cellUV, cellUV); // squared distance from cell center

    // build a fake hemisphere normal: flat at center-top, curving outward toward edges,
    // dropping to zero (silhouette edge) at the circle boundary
    float fakeHeight = sqrt(max(1.0 - dist2, 0.0));
    vec3 fakeNormal = normalize(vec3(cellUV.x, fakeHeight, cellUV.y));

    // light the fake sphere normal against the actual sun direction
    float sun = clamp(dot(fakeNormal, normalize(shadowLightPosition)), 0.0, 1.0);
    sun = mix(0.35, 1.15, sun); // keep a soft ambient floor so shadowed side isn't pure black

    vec3 litColor = cloud.rgb * sun;

    // round the silhouette: fade alpha to 0 outside the inscribed circle of the cell
    float roundMask = 1.0 - smoothstep(0.75, 1.0, dist2);
    cloud.a = smoothstep(0.0, 1.0, cloud.a) * 0.85 * roundMask;

    // subtle texture variation
    float variation = sin(texcoord.x * 40.0) * cos(texcoord.y * 40.0);
    litColor *= 1.0 + variation * 0.03;

    float fogFade = smoothstep(0.0, 0.85, 1.0 - gl_FragCoord.z);
    litColor = mix(fogColor, litColor, fogFade);

    litColor = mix(skyColor, litColor, cloud.a);

    color = vec4(litColor, cloud.a);
}