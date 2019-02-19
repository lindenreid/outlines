#ifndef COLOR_SPREAD
#define COLOR_SPREAD

//#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"

// Depth texture
TEXTURE2D(_LindenDepthTexture); SAMPLER(sampler_LindenDepthTexture);
float4 _LindenDepthTexture_TexelSize;
// Camera texture 
TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
// noise tex
TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);
// Material properties
float _Size;
float _DepthSensitivity;
float _NormalSensitivity;
float _DistanceMult;
float4 _Color;
float _NoiseScale;
// Unity properties (set in Outline.cs)
float4x4 unity_ViewToWorldMatrix;
float4x4 unity_InverseProjectionMatrix;

struct VertexInput {
    float4 vertex : POSITION;
};

struct VertexOutput {
    float4 pos : SV_POSITION;
    float2 screenPos : TEXCOORD0;
};

float4 GetDepthAndNormal (float2 uv) {
    float4 dn = SAMPLE_TEXTURE2D(_LindenDepthTexture, sampler_LindenDepthTexture, uv);
    return dn;
}

// x = depth difference
// y = normal difference
float2 CompareNeighbor (float baseDepth, float3 baseNormal, float2 uv, float2 offset) {
    float2 normalAndDepthDifference = float2(0,0);

    // multiply offset by texture size
    uv += _LindenDepthTexture_TexelSize.xy * offset;

    // sample neighboring pixel
    float4 normalDepth = GetDepthAndNormal(uv);

    // get difference in depth between local and neighbor depth
    normalAndDepthDifference.x = baseDepth - normalDepth.w;

    // get difference between local normal and neighbor normal
    float3 nd = baseNormal - normalDepth.xyz;
    nd = nd.x + nd.y + nd.z;
    normalAndDepthDifference.y = nd;

    return normalAndDepthDifference;
}

VertexOutput Vertex(VertexInput i) {
    VertexOutput o;
    o.pos = float4(i.vertex.xy, 0.0, 1.0);
    
    // get clip space coordinates for sampling camera tex
    o.screenPos = (i.vertex.xy + 1.0) * 0.5;
#if UNITY_UV_STARTS_AT_TOP
    o.screenPos = o.screenPos * float2(1.0, -1.0) + float2(0.0, 1.0);
#endif

    return o;
}

float4 Frag(VertexOutput i) : SV_Target
{
    float4 localdn = GetDepthAndNormal(i.screenPos);
    float localDepth = localdn.a;
    float3 localNormal = localdn.rgb;

    // camera texture
    float4 cam = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.screenPos);
    
    // lighting info
    //Light light = GetMainLight();

    // get difference between local pixel depth & neighboring pixel depths
    float2 diff = CompareNeighbor(localDepth, localNormal, i.screenPos, float2(1, 0));
    diff += CompareNeighbor(localDepth, localNormal, i.screenPos, float2(-1, 0));
    diff += CompareNeighbor(localDepth, localNormal, i.screenPos, float2(0, 1));
    diff += CompareNeighbor(localDepth, localNormal, i.screenPos, float2(0, -1));

    // translate difference into outlines with settings
    //diff *= localDepth * _DistanceMult;
    diff.x *= _DepthSensitivity;
    diff.y *= _NormalSensitivity;
    
    //diff = saturate(diff);
    float outline = diff.x + diff.y;
    outline = saturate(outline);

    // apply noise for random breaks in outline
    float2 noiseUV = i.screenPos * _NoiseScale;
    float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV).r;
    noise = noise > 0.4;
    outline -= noise;
    outline = saturate(outline);

    // get outline color
    float3 outlineColor = _Color.rgb*cam.rgb; //_Color.rgb * cam.rgb; //lerp(_Color.rgb, cam.rgb, 0.5);
    
    //half fogFactor = ComputeFogFactor(localDepth);
    //outlineColor = MixFog(outlineColor, fogFactor); //??? not working

    // apply to camera color
    float3 color = cam.rgb*(1-outline) + outlineColor*outline; //lerp(cam.rgb, outlineColor, outline);

    return float4(color, 1.0);
    //return float4(fogFactor.xxx, 1.0);
    //return float4(cam.rgb, 1.0); // test plain camera tex
    //return float4(localDepth.xxx, 1.0); // test local depth vals
    //return float4(diff.xxx, 1.0); // test depth difference vals
    //return float4(localNormal.rgb, 1.0); // test local normal vals
    //return float4(diff.yyy, 1.0); // test normal difference vals
}

#endif