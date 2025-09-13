Shader "Custom/Starfield" {
    Properties {
        _StarChance ("Star Chance", Range(0, 1)) = 0.1
        _TwinkleSpeed ("Twinkle Speed", Range(0.1, 5)) = 1.0
        _PixelDensity ("Pixel Density", Float) = 30000
        _StarColor ("Star Color", Color) = (1, 1, 1, 1)
    }
    
    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            float _StarChance;
            float _TwinkleSpeed;
            float _PixelDensity;
            fixed4 _StarColor;
            
            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            float random(float2 uv) {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }
            
            float noise(float2 uv) {
                return random(uv) * 0.5 + random(uv * 2.0) * 0.3 + random(uv * 4.0) * 0.2;
            }
            
            fixed4 frag (v2f i) : SV_Target {
                float2 pixelUV = floor(i.uv * _PixelDensity) / _PixelDensity;
                
                float star = step(1.0 - _StarChance, noise(pixelUV));
  
                float starTime = random(pixelUV * 0.5) * 6.28318;
                float twinkle = sin((_Time.y * _TwinkleSpeed) + starTime) * 0.5 + 0.5;
                star *= twinkle;
                
                fixed4 col = _StarColor * star;
                col.a = star;
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
