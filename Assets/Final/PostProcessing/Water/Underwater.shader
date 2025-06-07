Shader "Hidden/Underwater" {
    Properties
    {
        _MainTex ("Base", 2D) = "white" {}
        _NoiseOpacity ("Noise Opacity", Range(0.0, 1.0)) = 0.5
        _NoiseColor ("Noise Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _WaterColor ("Water Tint", Color) = (0.2, 0.6, 1.0, 1.0)
        _WaveAmount ("Wave Amount", Range(0.0, 0.01)) = 0.005
        _NoiseScale ("Noise Scale", Range(1.0, 20.0)) = 8.0
    }
    
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            sampler2D _MainTex;
            float _NoiseOpacity;
            fixed4 _NoiseColor;
            fixed4 _WaterColor;
            float _WaveAmount;
            float _NoiseScale;
            
            float2 hash(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
            }
            
            float worley(float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                
                float minDist = 1.0;
                
                for(int x = -1; x <= 1; x++)
                {
                    for(int y = -1; y <= 1; y++)
                    {
                        float2 neighbor = float2(x, y);
                        float2 points = hash(i + neighbor);
                        points = 0.5 + 0.5 * sin(_Time.y * 0.5 + 6.2831 * points);
                        
                        float2 diff = neighbor + points - f;
                        float dist = length(diff);
                        minDist = min(minDist, dist);
                    }
                }
                
                return minDist;
            }
            
            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                float2 wave = float2(
                    sin(i.uv.y * 15.0 + _Time.y * 2.0),
                    cos(i.uv.x * 12.0 + _Time.y * 1.5)
                ) * _WaveAmount;
                
                float2 noiseUv = i.uv * _NoiseScale + _Time.xy * 0.1;
                float noiseValue = worley(noiseUv);
                fixed4 noise = fixed4(noiseValue, noiseValue, noiseValue, 1.0);
                
                fixed4 col = tex2D(_MainTex, i.uv + wave);
                col.rgb *= _WaterColor.rgb;
                
                noise.rgb *= _NoiseColor.rgb;
                fixed4 noiseCol = lerp(col, noise, _NoiseOpacity);
                return noiseCol;
            }
            ENDCG
        }
    }
}