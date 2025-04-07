Shader "Unlit/WaterBending"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Speed ("Flow Speed", Float) = 1.0
        _DistortionStrength ("Distortion Strength", Float) = 0.05
        _WaveHeight ("Wave Height", Float) = 0.1
        _WaveFrequency ("Wave Frequency", Float) = 5.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off

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
            float4 _MainTex_ST;
            float _Speed;
            float _DistortionStrength;
            float _WaveHeight;
            float _WaveFrequency;

            v2f vert (appdata v)
            {
                v2f o;
                float time = _Time.y * _Speed;

                float3 pos = v.vertex.xyz;
                pos.y += sin((pos.x + pos.z) * _WaveFrequency + time) * _WaveHeight;

                o.vertex = UnityObjectToClipPos(float4(pos, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = _Time.y * _Speed;

                float2 distortedUV = i.uv;
                distortedUV.y += sin(i.uv.x * 20.0 + time) * _DistortionStrength;
                distortedUV.x += cos(i.uv.y * 20.0 + time) * _DistortionStrength;

                fixed4 col = tex2D(_MainTex, distortedUV);
                col.a = 0.3; 

                return col;
            }
            ENDCG
        }
    }
}
