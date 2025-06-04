Shader "Hidden/Wind"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WindStrength ("Wind Strength", Range(0, 0.1)) = 0.02
        _WindSpeed ("Wind Speed", Range(0, 1)) = 1.5
        _WindFrequency ("Wind Frequency", Range(1, 5)) = 5.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off ZWrite Off ZTest Always
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
            float _WindStrength;
            float _WindSpeed;
            float _WindFrequency;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // Create wind wave pattern
                float windTime = _Time.y * _WindSpeed;
                float windWave1 = sin((i.uv.y * _WindFrequency) + windTime) * _WindStrength;
                float windWave2 = sin((i.uv.y * _WindFrequency * 0.7) + windTime * 1.3) * _WindStrength * 0.5;
                
                // Combine waves for more natural movement
                float windOffset = windWave1 + windWave2;
                
                // Apply horizontal distortion
                float2 distortedUV = i.uv + float2(windOffset, 0);
                
                // Sample the texture with distorted coordinates
                fixed4 col = tex2D(_MainTex, distortedUV);
                
                return col;
            }
            ENDCG
        }
    }
}
