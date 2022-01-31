#ifndef RERE_DIFFUSE_INCLUDED
#define RERE_DIFFUSE_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

CBUFFER_START(UnityPerMaterial)
half3 _BaseColor;
half _Metallic;
half _Smoothness;
half _Subsurface;
CBUFFER_END

struct Attributes
{
    float3 positionOS : POSITION;
    half3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float2 uv : TEXCOORD0;
    float4 positionWSAndFogFactor : TEXCOORD1; // xyz: positionWS, w: vertex fog factor
    half3 normalWS : TEXCOORD2;
    float4 positionCS : SV_POSITION;
};

inline half Pow5(half x)
{
    return x * x * x * x * x;
}

struct Material
{
    half3 diffuse;
    half3 specular;
    half perceptualRoughness; // sqrt(alpha)
    half subsurface; // k_ss
};

// Setup Material dat
// Functions computing diffuse and specular are defined in
// com.unity.render-pipelines.core\ShaderLibrary\CommonMaterial.hlsl
Material GetMaterial()
{
    Material mat;
    half3 baseColor = _BaseColor;
    half metallic = _Metallic;

    // diffuse = baseColor * (1 - metallic)
    mat.diffuse = ComputeDiffuseColor(baseColor, metallic);

    // specular = lerp(DEFAULT_SPECULAR_VALUE.xxx, baseColor, metallc)
    // with DEFAULT_SPECULAR_VALUE = 0.04
    mat.specular = ComputeFresnel0(baseColor, metallic, DEFAULT_SPECULAR_VALUE);

    mat.perceptualRoughness = 1 - _Smoothness;
    mat.subsurface = _Subsurface;
    return mat;
}

half3 Lambert(half3 diffuse)
{
    return INV_PI * diffuse;
}

// eq. (9.66)
half3 DisneyDiffuse(half ndotl,half ndotv, half hdotl, half3 diffuse, half perceptualRoughness, half subsurce)
{
    half tl = Pow5(1 - ndotl);
    half tv = Pow5(1 - ndotv);

    half F_D90 = 0.5 + 2 * perceptualRoughness * hdotl * hdotl;
    half lightScatter = 1 + (F_D90 - 1) * tl;
    half viewScatter = 1 + (F_D90 - 1) * tv;
    half f_d = lightScatter * viewScatter;

    half F_SS90 = perceptualRoughness * hdotl * hdotl;
    half lightSubsurfaceScatter = 1 + (F_SS90 - 1) * tl;
    half viewSubsurfaceScatter = 1 + (F_SS90 - 1) * tv;
    half F_SS = lightSubsurfaceScatter * viewSubsurfaceScatter;

    // eq.(9.67)
    // Note: (ndotv * ndotl) should be (ndotv + ndotl)
    float f_ss = (1 / (ndotv + ndotl) - 0.5) * F_SS + 0.5;
    return ((1 - subsurce) * f_d + 1.25 * subsurce * f_ss) * INV_PI * diffuse;
}


// eq. (9.68)
half3 HammonDiffuse(half ndotl, half ndotv, half ndoth, half ldotv, half3 diffuse, half3 specular, half roughness)
{
    half3 f_smooth = 21 / 20 * (1 - specular) * (1 - Pow5(1 - ndotl)) * (1 - Pow5(1 - ndotv));
    half k_facing = 0.5 + 0.5 * ldotv;
    half f_rough = k_facing * (0.9 - 0.4 * k_facing) * (0.5 + ndoth) / max(0.001, ndoth);
    half f_multi = 0.3641 * roughness;
    return diffuse * INV_PI * ((1 - roughness) * f_smooth + roughness * f_rough + diffuse * f_multi);
}

half3 Lighting(half3 view, half3 normal, Light light, Material material)
{
    // diffuse
    half3 diffuse = material.diffuse;
    half3 specular = material.specular;
    half3 l = light.direction;
    half perceptualRoughness = material.perceptualRoughness;
    half roughness = perceptualRoughness * perceptualRoughness;

    half3 h = SafeNormalize(view + l);
    half ndotl = max(0, dot(normal, l));
    half ndotv = max(0, dot(normal, view));
    half ndoth = max(0, dot(normal, h));
    half hdotl = max(0, dot(h, l));
    half ldotv = max(0, dot(l, view));

    half3 brdf;
#if defined(_BRDF_DIFFUSE_LAMBERT)
    brdf = Lambert(diffuse);
#elif defined(_BRDF_DIFFUSE_DISNEY)
    brdf = DisneyDiffuse(ndotl, ndotv, hdotl, diffuse, perceptualRoughness, material.subsurface);
#elif defined(_BRDF_DIFFUSE_HAMMON)
    brdf = HammonDiffuse(ndotl, ndotv, ndoth, ldotv, diffuse, specular, roughness);
#endif

    return PI * brdf * ndotl * light.color;
}

// Vertex Shader
Varyings Vert(Attributes input)
{
    Varyings output;
    output.uv = input.uv;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    output.positionWSAndFogFactor = float4(vertexInput.positionWS, fogFactor);
    output.positionCS = TransformWorldToHClip(vertexInput.positionWS);
    output.normalWS = vertexNormalInput.normalWS;
    return output;
}

// Fragment Shader
half4 Frag(Varyings input) : SV_TARGET
{
    half3 col;
    float3 positionWS = input.positionWSAndFogFactor.rgb;
    half3 viewWS = SafeNormalize(GetWorldSpaceViewDir(positionWS));
    half3 normalWS = SafeNormalize(input.normalWS);
    Light mainLight = GetMainLight();
    col = Lighting(viewWS, normalWS, mainLight, GetMaterial());
    return half4(col, 1);
}
#endif