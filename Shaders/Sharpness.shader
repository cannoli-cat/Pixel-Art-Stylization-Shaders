Shader "Unlit/Sharpness" {
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass {
            HLSLPROGRAM
            
            #pragma vertex Vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            float _Amount;
            
            half4 frag (Varyings i) : SV_Target {
                float2 uv = i.texcoord;
                float neighbor = _Amount * -1;
                float center = _Amount * 4 + 1;

                float4 col = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, uv);
                float4 n = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, uv + _BlitTexture_TexelSize.xy * float2(0, 1));
                float4 e = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, uv + _BlitTexture_TexelSize.xy * float2(1, 0));
                float4 s = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, uv + _BlitTexture_TexelSize.xy * float2(0, -1));
                float4 w = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, uv + _BlitTexture_TexelSize.xy * float2(-1, 0));

                float4 output = n * neighbor + e * neighbor + col * center + s * neighbor + w * neighbor;

                return half4(saturate(output.rgb), saturate(output.a));
            }
            
            ENDHLSL
        }
    }
}