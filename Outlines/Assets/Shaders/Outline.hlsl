#ifndef COLOR_SPREAD
#define COLOR_SPREAD

#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

// Depth texture
TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);
float4 _CameraDepthTexture_TexelSize;
// Camera texture 
TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
// Material properties
float _Size;
float _Sensitivity;
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

float GetDepth (float2 uv) {
    return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
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

float CompareNeighbor (float baseDepth, float2 uv, float2 offset) {
    // multiply offset by texture size
    uv += _CameraDepthTexture_TexelSize.xy * offset;
    // sample neighboring pixel
    float z = GetDepth(uv);
    // get difference in depth between local and neighbor depth
    return baseDepth - z;
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
    float localDepth = GetDepth(i.screenPos);
    //float3 worldPos = GetWorldFromViewPosition(i, localDepth);

    // camera texture
    float4 cam = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.screenPos);
    
    // lighting info
    //Light light = GetMainLight();

    // get difference between local pixel depth & neighboring pixel depths
    float diff = CompareNeighbor(localDepth, i.screenPos, float2(1, 0));
    diff += CompareNeighbor(localDepth, i.screenPos, float2(-1, 0));
    diff += CompareNeighbor(localDepth, i.screenPos, float2(0, 1));
    diff += CompareNeighbor(localDepth, i.screenPos, float2(0, -1));

    // create outline color
    float3 outlineColor = _Color.rgb; //lerp(_Color.rgb, cam.rgb, 0.5);

    // translate difference into outlines with settings
    //diff *= localDepth * _DistanceMult;
    diff *= _Sensitivity;
    diff = saturate(diff);

    // apply to camera color
    float3 color = lerp(cam.rgb, outlineColor, diff);

    return float4(color, 1.0);
    //return float4(cam.rgb, 1.0); // TEST
    //return float4(localDepth.xxx, 1.0); // TEST
    //return float4(diff.xxx, 1.0);
}

#endif