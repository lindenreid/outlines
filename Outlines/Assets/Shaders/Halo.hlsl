#ifndef LINDEN_HALO
#define LINDEN_HALO

#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"

struct HaloVertexInput {
    float4 vertex : POSITION;
    float3 normalOS : NORMAL;
};

struct HaloVertexOutput { 
    float4 posCS : SV_POSITION;
};

HaloVertexOutput HaloVertex(HaloVertexInput i) {
    HaloVertexOutput o;

    float4 newPos = i.vertex;
    i.normalOS = normalize(i.normalOS);
    newPos += float4(i.normalOS.xyz, 0.0) * 0.025;

    o.posCS = TransformObjectToHClip(newPos.xyz);

    return o;
}

float4 HaloFrag(HaloVertexOutput i) : SV_Target {
    return float4(0,0,0,1);
}

#endif