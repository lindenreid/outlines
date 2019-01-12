Shader "Custom/Outline"
{
    SubShader
    {
        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            HLSLPROGRAM

                #include "Outline.hlsl"

                #pragma vertex Vertex
                #pragma fragment Frag

            ENDHLSL
        }
    }
}
