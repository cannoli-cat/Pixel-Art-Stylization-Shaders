Shader "Unlit/Nebula" {
    Properties {
        _Seed("Noise Seed", Float) = 1.0
        _NoiseScale("Noise Scale", Float) = 4.0
        _Chance("Chance", Float) = 0.6
        _Persistence("Persistence", Float) = 2
        _Octaves("Octaves", Int) = 5
        _Lacunarity("Lacunarity", Float) = 0.5
        _MainTex("Texture", 2D) = "white" {}
        _PixelDensity("Pixel Density", Float) = 1.0
        
        [Header(Colors)]
        _Shadow("Shadow", Color) = (0,0,0,1)
        _ShadowThreshold("Shadow Threshold", Float) = 0.4
        _Midtone("Midtone", Color)   = (0.5,0.5,0.5,1)
        _MidtoneThreshold("Midtone Threshold", Float) = 0.5
        _Highlight("Highlight", Color) = (1,1,1,1)
        _HighlightThreshold("Highlight Threshold", float) = 0.6
        _BrightestColor("Brightest Color", Color) = (1,1,1,1)
    }

    SubShader {
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "PreviewType" = "Plane"
        }
        LOD 100

        Pass {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _Seed;
            float _NoiseScale;
            float _Chance;
            float _Persistence;
            int _Octaves;
            float _Lacunarity;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _PixelDensity;
            float4 _Shadow;
            float _ShadowThreshold;
            float4 _Midtone;
            float _MidtoneThreshold;
            float4 _Highlight;
            float _HighlightThreshold;
            float4 _BrightestColor;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float hash(float2 p, float seed) {
                p = frac(p * 0.3183099 + seed * 0.1);
                return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
            }
            
            float perlin(float2 p, float seed) {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);

                float n00 = hash(i + float2(0.0, 0.0), seed);
                float n01 = hash(i + float2(0.0, 1.0), seed);
                float n10 = hash(i + float2(1.0, 0.0), seed);
                float n11 = hash(i + float2(1.0, 1.0), seed);

                return lerp(
                    lerp(n00, n10, u.x),
                    lerp(n01, n11, u.x),
                    u.y
                );
            }

            float2 flow(float2 uv, float strength) {
                float angle = perlin(uv * 0.5, _Seed) * 6.283185;
                float2 offset = float2(cos(angle), sin(angle)) * strength;
                return uv + offset;
            }

            float fractal(float2 p) {
                float total = 0.0;
                float frequency = _NoiseScale;
                float amplitude = 1.0;
                float maxValue = 0.0;

                for (int i = 0; i < _Octaves; i++) {
                    p = flow(p * frequency, 0.2);
                    total += perlin(p, _Seed) * amplitude;
                    maxValue += amplitude;

                    frequency *= _Lacunarity;
                    amplitude *= _Persistence;
                }

                return total / maxValue;
            }

            float billow(float2 p) {
                float n1 = perlin(p * 2.0, _Seed);
                float n2 = perlin(p * 2.0 + float2(10.0, 10.0), _Seed * 1.5);
                return abs(n1 - n2);
            }

            float ridge(float2 p) {
                return 1.0 - billow(p);
            }

            float combinedNoise(float2 uv) {
                float b = billow(uv * _NoiseScale);
                float r = ridge(uv * (_NoiseScale * 1.5));
                
                return lerp(b, r, smoothstep(0.3, 0.7, b));
            }
            
            float bayer_dither(float2 uv) {
                static const float dither_thresholds[16] = {
                    1.0 / 17.0, 9.0 / 17.0, 3.0 / 17.0, 11.0 / 17.0,
                    13.0 / 17.0, 5.0 / 17.0, 15.0 / 17.0, 7.0 / 17.0,
                    4.0 / 17.0, 12.0 / 17.0, 2.0 / 17.0, 10.0 / 17.0,
                    16.0 / 17.0, 8.0 / 17.0, 14.0 / 17.0, 6.0 / 17.0
                };

                int x = int(fmod(floor(uv.x * _PixelDensity), 4.0));
                int y = int(fmod(floor(uv.y * _PixelDensity), 4.0));
                return dither_thresholds[x + y * 4];
            }

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                float2 uv = floor(i.uv * _PixelDensity + 0.5) / _PixelDensity;
                
                float noise = fractal(uv);
                float dither = bayer_dither(uv);
                noise = saturate(noise + dither * 0.05);

                if (noise < _Chance) discard;

                if (noise < _ShadowThreshold)
                    return _Shadow;
                if (noise < _MidtoneThreshold)
                    return _Midtone;
                if (noise < _HighlightThreshold)
                    return _Highlight;
                
                return _BrightestColor;
            }
            
            ENDCG
        }
    }
}