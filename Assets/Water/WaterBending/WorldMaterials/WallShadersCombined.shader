Shader "Unlit/WallShadersCombined"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _PollutionTex ("Pollution Texture", 2D) = "white" {}
        _NoiseTex ("Distortion Noise", 2D) = "white" {}
        _Distortion ("Distortion Strength", Range(0, 1)) = 0.1
        _Radius ("Effect Radius", Range(0, 15)) = 0.2
        _EdgeSoftness ("Edge Softness", Range(0.01, 1)) = 0.1
        _MainColor ("Main Pollution Color", Color) = (0.2, 0.4, 0.3, 1)
        _ReflectionStrength ("Reflection Strength", Range(0, 1)) = 0.3
        _Impact ("Impact", Float) = 0.5
        _TwistAmount ("Twist Amount", Float) = 1.5
        _BulletType  ("Bullet Type", Float) = 0.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

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

            float _Distortion;
            float _Radius;
            float _EdgeSoftness;
            float4 _MainColor;
            float _ReflectionStrength;
            float _Impact;
            float _TwistAmount;
            float _BulletType;

            float4 _PontoEmbateFireArray[1024];
            float4 _PontoEmbateWindArray[1024];
            float4 _PontoEmbateWaterArray[1024];

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            v2f vert(appdata v)
            {
                v2f o;

                float4 worldVertex = mul(unity_ObjectToWorld, v.vertex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);

                if (_BulletType == 2.0)
                    {
                        float3 worldPos = worldVertex.xyz;

                        for (int i = 0; i < 1024; i++)
                        {
                            float4 ponto = _PontoEmbateWindArray[i];
                            if (ponto.w > 0.0)
                            {
                                float3 delta = worldPos - ponto.xyz;
                                float dist = length(delta);

                                if (dist <= _Radius)
                                {
                                    float t = saturate(1.0 - dist / _Radius);

                                    worldPos -= worldNormal * _Impact * t * ponto.w;

                                    float angle = _TwistAmount * t * ponto.w;
                                    float sinA = sin(angle);
                                    float cosA = cos(angle);

                                    float3 localDelta = delta;
                                    float rotatedX = localDelta.x * cosA - localDelta.z * sinA;
                                    float rotatedZ = localDelta.x * sinA + localDelta.z * cosA;

                                    float3 twistedOffset = float3(rotatedX, localDelta.y, rotatedZ) - localDelta;
                                    worldPos += twistedOffset * t * ponto.w;
                                }
                            }
                        }

                        // Update worldVertex with modified position
                        worldVertex.xyz = worldPos;
                    }


                o.vertex = UnityWorldToClipPos(worldVertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = worldVertex.xyz;
                o.worldNormal = worldNormal;
                o.viewDir = normalize(UnityWorldSpaceViewDir(worldVertex.xyz));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 baseColor = tex2D(_MainTex, i.uv);

                if (_BulletType == 1.0)
                {
                    float pollutionAmount = 0.0;

                    for (int j = 0; j < 1024; j++)
                    {
                        float4 ponto = _PontoEmbateWaterArray[j];
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
                        float noise = tex2D(_NoiseTex, i.uv).r;
                        float2 distortedUV = i.uv + (_Distortion * (noise - 0.5));

                        fixed4 pollutionTex = tex2D(_PollutionTex, distortedUV * 2.0);
                        fixed4 pollutionColor = lerp(_MainColor, pollutionTex, 0.6);

                        float fresnel = 1.0 - saturate(dot(i.worldNormal, i.viewDir));
                        float reflection = fresnel * _ReflectionStrength * pollutionAmount;

                        fixed4 finalColor = lerp(baseColor, pollutionColor, pollutionAmount);
                        finalColor.rgb += reflection * 0.5;

                        return finalColor;
                    }
                }

                // Default
                return baseColor;
            }

            ENDCG
        }
    }
}
