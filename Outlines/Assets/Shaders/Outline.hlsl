#ifndef COLOR_SPREAD
#define COLOR_SPREAD

#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

// Depth texture
TEXTURE2D_SAMPLER2D(_LindenDepthTexture, sampler_LindenDepthTexture);
float4 _LindenDepthTexture_TexelSize;
// Camera texture 
TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
// Material properties
float _Size;
float _DepthSensitivity;
float _NormalSensitivity;
float _DistanceMult;
float4 _Color;
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

float3 GetWorldFromViewPosition (VertexOutput i, float z) {
    // get view space position
    // thank you to the built-in pp screenSpaceReflections effect for this code lel
    float4 result = mul(unity_InverseProjectionMatrix, float4(2.0 * i.screenPos - 1.0, z, 1.0));
    float3 viewPos = result.xyz / result.w;

    // get ws position
    float3 worldPos = mul(unity_ViewToWorldMatrix, float4(viewPos, 1.0));

    return worldPos;
    //return viewPos; // TEST
    //return float3(z, z, z); // TEST
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
    o.screenPos = TransformTriangleVertexToUV(i.vertex.xy);
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
    //float3 worldPos = GetWorldFromViewPosition(i, localDepth);

    // camera texture
    float4 cam = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.screenPos);
    
    // lighting info
    //Light light = GetMainLight();

    // get difference between local pixel depth & neighboring pixel depths
    float2 diff = CompareNeighbor(localDepth, localNormal, i.screenPos, float2(1, 0));
    diff += CompareNeighbor(localDepth, localNormal, i.screenPos, float2(-1, 0));
    diff += CompareNeighbor(localDepth, localNormal, i.screenPos, float2(0, 1));
    diff += CompareNeighbor(localDepth, localNormal, i.screenPos, float2(0, -1));

    // create outline color
    float3 outlineColor = _Color.rgb * cam.rgb; //lerp(_Color.rgb, cam.rgb, 0.5);

    // translate difference into outlines with settings
    //diff *= localDepth * _DistanceMult;
    diff.x *= _DepthSensitivity;
    diff.y *= _NormalSensitivity;
    
    //diff = saturate(diff);
    float outline = diff.x + diff.y;
    outline = saturate(outline);

    // apply to camera color
    float3 color = lerp(cam.rgb, outlineColor, outline);

    return float4(color, 1.0);
    //return float4(cam.rgb, 1.0); // test plain camera tex
    //return float4(localDepth.xxx, 1.0); // test local depth vals
    //return float4(diff.xxx, 1.0); // test depth difference vals
    //return float4(localNormal.rgb, 1.0); // test local normal vals
    //return float4(diff.yyy, 1.0); // test normal difference vals
}

#endif