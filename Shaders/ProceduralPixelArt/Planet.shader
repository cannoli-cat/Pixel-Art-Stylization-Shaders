Shader "Custom/Planet" {
    Properties {
        [Header(Planetary Noise)]
        _Radius ("Planet Radius", Float) = 0.5
        _Seed ("Noise Seed", Float) = 1.0
        _NoiseScale ("Noise Scale", Float) = 4.0
        _Chance ("Chance", Float) = 0.6
        _Persistence ("Persistence", Float) = 2
        _Octaves ("Octaves", Int) = 5
        _Lacunarity ("Lacunarity", Float) = 0.5
        _PixelDensity ("Pixel Density", Float) = 50.0
        
        [Header(Planetary Colors)]
        _Shadow ("Shadow", Color) = (0,0,0,1)
        _ShadowThreshold ("Shadow Threshold", Float) = 0.4
        _Midtone ("Midtone", Color) = (0.5,0.5,0.5,1)
        _MidtoneThreshold ("Midtone Threshold", Float) = 0.5
        _Highlight ("Highlight", Color) = (1,1,1,1)
        _HighlightThreshold ("Highlight Threshold", Float) = 0.6
        _BrightestColor ("Brightest Color", Color) = (1,1,1,1)
        
        [Header(Clouds)]
        _CloudColor ("Color", Color) = (1, 1, 1, 0.8)
        _CloudScale ("Scale", Float) = 3.0
        _CloudThreshold ("Threshold", Float) = 0.5
        _CloudPersistence ("Persistence", Float) = 2
        _CloudOctaves ("Octaves", Int) = 5
        _CloudLacunarity ("Lacunarity", Float) = 0.5
        _CloudTimeScale("Time Scale", Float) = 1.0
        
        [Header(Outline)]
        _OutlineColor("Color", Color) = (1,1,1,1)
        _OutlineThickness ("Thickness", Float) = 0.05
        _OutlineNoiseScale ("Noise Scale", Float) = 3.0
        _OutlinePersistence ("Persistence", Float) = 2
        _OutlineOctaves ("Octaves", Int) = 5
        _OutlineLacunarity ("Lacunarity", Float) = 0.5
        _OutlineTimeScale("Time Scale", Float) = 0.1
        
        [Header(Shading)]
        _ShadingColor ("Color", Color) = (0.2, 0.2, 0.4, 1.0)
        _ShadingNoiseScale ("Noise Scale", Float) = 3.0
        _ShadingPersistence ("Persistence", Float) = 2
        _ShadingOctaves ("Octaves", Int) = 5
        _ShadingLacunarity ("Lacunarity", Float) = 0.5
        _ShadingAngle ("Angle", Float) = 0.5
        _ShadingCurve ("Curve", Float) = 0.5
        _ShadingThickness ("Thickness", Float) = 0.2
        _ShadingCoverage ("Coverage", Float) = 0.01
    }

    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _Radius;
            float _Seed;
            float _NoiseScale;
            float _Chance;
            float _Persistence;
            int _Octaves;
            float _Lacunarity;
            float _PixelDensity;
            
            fixed4 _Shadow, _Midtone, _Highlight, _BrightestColor, _ShadingColor;
            float _ShadowThreshold, _MidtoneThreshold, _HighlightThreshold;
            
            fixed4 _OutlineColor;
            float _OutlineThickness;
            float _OutlineNoiseScale;
            float _OutlinePersistence;
            int _OutlineOctaves;
            float _OutlineLacunarity;
            float _OutlineTimeScale;
            
            float _ShadingNoiseScale;
            float _ShadingPersistence;
            int _ShadingOctaves;
            float _ShadingLacunarity;
            float _ShadingAngle;
            float _ShadingCurve;
            float _ShadingThickness;
            float _ShadingCoverage;
            
            fixed4 _CloudColor;
            float _CloudScale;
            float _CloudThreshold;
            float _CloudPersistence;
            int _CloudOctaves;
            float _CloudLacunarity;
            float _CloudTimeScale;

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
            
            float fractal(float2 p, float noise_scale, int octaves, float lacunarity, float persistence) {
                float total = 0.0;
                float frequency = noise_scale;
                float amplitude = 1.0;
                float maxValue = 0.0;

                for (int i = 0; i < octaves; i++) {
                    total += perlin(p * frequency, _Seed) * amplitude;
                    maxValue += amplitude;

                    frequency *= lacunarity;
                    amplitude *= persistence;
                }

                return total / maxValue;
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

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target {
                float2 uv = floor(i.uv * _PixelDensity) / _PixelDensity;
                float2 centered_uv = uv - 0.5;
                float dist = length(centered_uv);
                
                float dither = bayer_dither(uv);
                float noise = fractal(centered_uv * _NoiseScale, _NoiseScale, _Octaves, _Lacunarity, _Persistence);
                noise = saturate(noise + dither * 0.05);

                float outline_time = _Time.y * _OutlineTimeScale;
                float2 outline_offset = float2(
                    sin(outline_time + centered_uv.x * 10.0) * 0.1,
                    cos(outline_time + centered_uv.y * 10.0) * 0.1
                );
                
                float secondary_pulse = fractal(centered_uv * (_OutlineNoiseScale * 0.5) + outline_time * 0.3, 
                                                _OutlineNoiseScale, 
                                                _OutlineOctaves, 
                                                _OutlineLacunarity, 
                                                _OutlinePersistence);

                float outline_noise = fractal((centered_uv + outline_offset) * _OutlineNoiseScale, 
                                              _OutlineNoiseScale, 
                                              _OutlineOctaves, 
                                              _OutlineLacunarity, 
                                              _OutlinePersistence);

                outline_noise = saturate(outline_noise + secondary_pulse * 0.5 + sin(outline_time * 3.0) * 0.1 + dither * 0.05);


                float inner_edge = smoothstep(_Radius, _Radius - _OutlineThickness * outline_noise, dist);
                if (dither > inner_edge && dist <= _Radius && dist >= _Radius - _OutlineThickness) {
                    return _OutlineColor;
                }
                
                if (dist > _Radius) {
                    float outer_edge = smoothstep(_Radius, _Radius + _OutlineThickness * outline_noise, dist);
                    if (dither > outer_edge) {
                        return _OutlineColor;
                    }
                    return fixed4(0, 0, 0, 0);
                }
                
                fixed4 noise_color;
                if (noise < _Chance) discard;
                if (noise < _ShadowThreshold) noise_color = _Shadow;
                else if (noise < _MidtoneThreshold) noise_color = _Midtone;
                else if (noise < _HighlightThreshold) noise_color = _Highlight;
                else noise_color = _BrightestColor;

                float cloud_time = _Time.y * _CloudTimeScale;
                float2 cloud_offset = float2(sin(cloud_time), cos(cloud_time)) * 0.2;
                float cloud_noise = fractal((centered_uv + cloud_offset) * _CloudScale, _CloudScale, _CloudOctaves, _CloudLacunarity, _CloudPersistence);
                cloud_noise = saturate(cloud_noise + dither * 0.05);
                float cloud_mask = step(_CloudThreshold, cloud_noise);        
                fixed4 cloud_color = _CloudColor * cloud_mask;                
                
                float2 light_dir = float2(0.5, -0.5);
                float angle = atan2(centered_uv.y, centered_uv.x);
                float light_angle = atan2(light_dir.y, light_dir.x);
                
                float angle_diff = abs(angle - light_angle);
                if (angle_diff > 3.14159) angle_diff = 6.28318 - angle_diff;
                
                float angular_mask = smoothstep(_ShadingAngle, _ShadingAngle - _ShadingCurve, angle_diff);
                float radial_mask = smoothstep(_Radius - _ShadingThickness, _Radius, dist);

                float shading_mask = angular_mask * radial_mask;
                float shading_noise = fractal(centered_uv * _ShadingNoiseScale + _Seed, _ShadingNoiseScale, _ShadingOctaves, _ShadingLacunarity, _ShadingPersistence);
                shading_noise = saturate(shading_noise + dither * 0.05);

                if (shading_mask > shading_noise && dist <= _Radius) {
                    return _ShadingColor;
                }

                return lerp(noise_color, cloud_color, cloud_color.a * cloud_mask);
            }
            
            ENDCG
        }
    }
}
