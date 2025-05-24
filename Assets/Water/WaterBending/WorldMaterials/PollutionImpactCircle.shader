Shader "Unlit/PollutionImpactCircle"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _PollutionTex ("Pollution Texture", 2D) = "white" {}
        _NoiseTex ("Distortion Noise", 2D) = "white" {}
        _Distortion ("Distortion Strength", Range(0, 1)) = 0.1
        _Speed ("Flow Speed", Range(0.1, 5)) = 1
        _Radius ("Pollution Radius", Range(0, 5)) = 0.2
        _EdgeSoftness ("Edge Softness", Range(0.01, 1)) = 0.1
        _MainColor ("Main Pollution Color", Color) = (0.2, 0.4, 0.3, 1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _PollutionTex;
            sampler2D _NoiseTex;
            float4 _MainTex_ST;
            float4 _MainColor;

            float _Distortion;
            float _Speed;
            float _Radius;
            float _EdgeSoftness;

            float4 _PontoEmbateArray[1024];

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 baseColor = tex2D(_MainTex, i.uv);
                float pollutionAmount = 0.0;

                for (int j = 0; j < 1024; j++)
                {
                    float4 ponto = _PontoEmbateArray[j];
                    if (ponto.w > 0.0)
                    {
                        float3 delta = i.worldPos - ponto.xyz;
                        float r = length(delta) / _Radius;
                        float blob = exp(-r * r * 4.0);
                        pollutionAmount += blob * ponto.w;
                    }
                }

                pollutionAmount = saturate(pollutionAmount);

                if (pollutionAmount > 0.0)
                {
                    float2 flowUV = i.uv + float2(_Time.y * _Speed * 0.05, _Time.y * _Speed * 0.03);
                    float noise = tex2D(_NoiseTex, flowUV).r;
                    float2 distortedUV = i.uv + (_Distortion * (noise - 0.5));

                    fixed4 pollutionTex = tex2D(_PollutionTex, distortedUV * 2.0);
                    fixed4 pollutionColor = lerp(_MainColor, pollutionTex, 0.6);

                    return lerp(baseColor, pollutionColor, pollutionAmount);
                }

                return baseColor;
            }


            ENDCG
        }
    }
}
