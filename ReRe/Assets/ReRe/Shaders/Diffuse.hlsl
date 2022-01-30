#ifndef RERE_DIFFUSE_INCLUDED
#define RERE_DIFFUSE_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

CBUFFER_START(UnityPerMaterial)
half3 _BaseColor;
half _Metallic;
half _Smoothness;
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

half BRDF_Lambert(half3 diffuse)
{
    return diffuse * INV_PI;
}

half BRDF_DisneyDiffuse(half ndotl, half ndotv, half hdotl, half perceptualRoughness)
{
    half fd90 = 0.5 + 2 * hdotl * hdotl * perceptualRoughness;
    half lightScatter = 1 + (fd90 - 1) * Pow5(1 - ndotl);
    half viewScatter = 1 + (fd90 - 1) * Pow5(1 - ndotv);
    return lightScatter * viewScatter * INV_PI;
}

struct Material
{
    half3 diffuse;
    half3 specular;
    half perceptualRoughness; // sqrt(alpha)
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
    return mat;
}

half3 Lighting(half3 viewWS, half3 normalWS, Light light, Material material)
{
    // diffuse
    half3 diffuse = material.diffuse;
    half3 l = light.direction;
    half3 h = normalize(viewWS + l);
    half ndotl = max(0, dot(normalWS, l));
    half ndotv = max(0, dot(normalWS, l));
    half hdotl = max(0, dot(h, l));

    half brdf = BRDF_DisneyDiffuse(ndotl, ndotv, hdotl, material.perceptualRoughness);
    return PI * diffuse * brdf * ndotl;
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