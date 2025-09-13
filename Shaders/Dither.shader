Shader "Unlit/Dither"{
    SubShader{
        Pass{
            Name "DitherPass"

            Tags{
                "RenderType" = "Transparent" "Queue" = "Transparent"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest Always
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            float _Spread;
            int _RedColorCount, _GreenColorCount, _BlueColorCount, _BayerLevel;

            static const int bayer2[2 * 2] = {
                0, 2,
                3, 1
            };

            static const int bayer4[4 * 4] = {
                0, 8, 2, 10,
                12, 4, 14, 6,
                3, 11, 1, 9,
                15, 7, 13, 5
            };

            static const int bayer8[8 * 8] = {
                0, 32, 8, 40, 2, 34, 10, 42,
                48, 16, 56, 24, 50, 18, 58, 26,
                12, 44, 4, 36, 14, 46, 6, 38,
                60, 28, 52, 20, 62, 30, 54, 22,
                3, 35, 11, 43, 1, 33, 9, 41,
                51, 19, 59, 27, 49, 17, 57, 25,
                15, 47, 7, 39, 13, 45, 5, 37,
                63, 31, 55, 23, 61, 29, 53, 21
            };

            static const int bayer16[16 * 16] = {
                0, 128, 32, 160, 8, 136, 40, 168, 2, 130, 34, 162, 10, 138, 42, 170,
                192, 64, 224, 96, 200, 72, 232, 104, 194, 66, 226, 98, 202, 74, 234, 106,
                48, 176, 16, 144, 56, 184, 24, 152, 50, 178, 18, 146, 58, 186, 26, 154,
                240, 112, 208, 80, 248, 120, 216, 88, 242, 114, 210, 82, 250, 122, 218, 90,
                12, 140, 44, 172, 4, 132, 36, 164, 14, 142, 46, 174, 6, 134, 38, 166,
                204, 76, 236, 108, 196, 68, 228, 100, 206, 78, 238, 110, 198, 70, 230, 102,
                60, 188, 28, 156, 52, 180, 20, 148, 62, 190, 30, 158, 54, 182, 22, 150,
                252, 124, 220, 92, 244, 116, 212, 84, 254, 126, 222, 94, 246, 118, 214, 86,
                3, 131, 35, 163, 11, 139, 43, 171, 1, 129, 33, 161, 9, 137, 41, 169,
                195, 67, 227, 99, 203, 75, 235, 107, 193, 65, 225, 97, 201, 73, 233, 105,
                51, 179, 19, 147, 59, 187, 27, 155, 49, 177, 17, 145, 57, 185, 25, 153,
                243, 115, 211, 83, 251, 123, 219, 91, 241, 113, 209, 81, 249, 121, 217, 89,
                15, 143, 47, 175, 7, 135, 39, 167, 13, 141, 45, 173, 5, 133, 37, 165,
                207, 79, 239, 111, 199, 71, 231, 103, 205, 77, 237, 109, 197, 69, 229, 101,
                63, 191, 31, 159, 55, 183, 23, 151, 61, 189, 29, 157, 53, 181, 21, 149,
                255, 127, 223, 95, 247, 119, 215, 87, 253, 125, 221, 93, 245, 117, 213, 85
            };

            float get_bayer2(uint x, uint y)
            {
                return float(bayer2[(x % 2) + (y % 2) * 2]) * (1.0f / 4.0f) - 0.5f;
            }

            float get_bayer4(uint x, uint y)
            {
                return float(bayer4[(x % 4) + (y % 4) * 4]) * (1.0f / 16.0f) - 0.5f;
            }

            float get_bayer8(uint x, uint y)
            {
                return float(bayer8[(x % 8) + (y % 8) * 8]) * (1.0f / 64.0f) - 0.5f;
            }

            float get_bayer16(uint x, uint y)
            {
                return float(bayer16[(x % 16) + (y % 16) * 16]) * (1.0f / 256.0f) - 0.5f;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float2 texel = _BlitTexture_TexelSize.xy;
                
                float4 col =
                    SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, i.texcoord + texel*float2(-0.5,-0.5)) +
                    SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, i.texcoord + texel*float2( 0.5,-0.5)) +
                    SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, i.texcoord + texel*float2(-0.5, 0.5)) +
                    SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, i.texcoord + texel*float2( 0.5, 0.5));
                col *= 0.25;
                
                uint2 px = (uint2)floor(i.positionCS.xy);
                
                float bayer_values[4] = {
                    get_bayer2(px.x, px.y),
                    get_bayer4(px.x, px.y),
                    get_bayer8(px.x, px.y),
                    get_bayer16(px.x, px.y)
                };
                
                float threshold = _Spread * bayer_values[_BayerLevel];

                float3 q;
                q.r = floor((_RedColorCount - 1.0) * col.r + threshold + 0.5) / (_RedColorCount - 1.0);
                q.g = floor((_GreenColorCount - 1.0) * col.g + threshold + 0.5) / (_GreenColorCount - 1.0);
                q.b = floor((_BlueColorCount - 1.0) * col.b + threshold + 0.5) / (_BlueColorCount - 1.0);

                return half4(saturate(q), col.a);
            }
            ENDHLSL
        }
    }
}