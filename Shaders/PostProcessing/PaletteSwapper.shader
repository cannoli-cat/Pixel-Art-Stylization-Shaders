Shader "Unlit/PaletteSwapper"{
    SubShader{
        Tags{
            "RenderType"="Opaque"
        }
        LOD 100

        Pass{
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            Texture2D _ColorPalette;
            float4 _ColorPalette_TexelSize;
            int _Invert;
            int _IsColorRamp;

            float3 rgbToYCbCr(float3 c)
            {
                float y = dot(c, float3(0.299, 0.587, 0.114));
                float cb = 0.564 * (c.b - y);
                float cr = 0.713 * (c.r - y);
                return float3(y, cb, cr);
            }

            half4 frag(Varyings i) : SV_Target
            {
                float4 src = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_PointClamp, i.texcoord);
                float3 color = src.rgb;

                if (_Invert == 1)
                {
                    color = 1.0 - color;
                }

                float width = _ColorPalette_TexelSize.z;

                if (_IsColorRamp == 1)
                {
                    float gray = dot(color, float3(0.299, 0.587, 0.114));
                    float2 uv = float2(gray, 0.5);

                    float index = uv.x * width;

                    float2 uv_a = float2(floor(index) / width, 0.5);
                    float2 uv_b = float2(ceil(index) / width, 0.5);

                    float4 color_a = _ColorPalette.Sample(sampler_PointClamp, uv_a);
                    float4 color_b = _ColorPalette.Sample(sampler_PointClamp, uv_b);

                    return lerp(color_a, color_b, frac(index)) * float4(1, 1, 1, src.a);
                }

                float min_dist = 999999.0;
                float4 nearest_color = 0;

                float3 inputYCbCr = rgbToYCbCr(color);

                for (int idx = 0; idx < (int)width; idx++)
                {
                    float2 uv_palette = float2((idx + 0.5) / width, 0.5);
                    float4 pal_color = _ColorPalette.Sample(sampler_PointClamp, uv_palette);

                    float3 paletteYCbCr = rgbToYCbCr(pal_color.rgb);
                    float dist = distance(inputYCbCr, paletteYCbCr);

                    if (dist < min_dist)
                    {
                        min_dist = dist;
                        nearest_color = pal_color;
                    }
                }
                
                return float4(nearest_color.rgb, src.a);
            }
            ENDHLSL
        }
    }
}