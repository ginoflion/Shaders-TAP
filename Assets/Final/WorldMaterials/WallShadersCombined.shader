Shader "Unlit/WallShadersCombined"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _PollutionTex ("Pollution Texture", 2D) = "white" {}
        _NoiseTex ("Distortion Noise", 2D) = "white" {}
        _ImpactTex ("Impact Texture", 2D) = "white" {}

        _Distortion ("Distortion Strength", Range(0, 1)) = 0.1
        _RadiusWater ("Water Effect Radius", Range(0, 15)) = 0.2
        _WaterColor ("Main Pollution Color", Color) = (0.2, 0.4, 0.3, 1)
        _ReflectionStrength ("Reflection Strength", Range(0, 1)) = 0.3

        _RadiusFire ("Effect Radius Fire", Range(0, 15)) = 0.2
        _EdgeSoftness ("Edge Softness", Range(0.01, 1)) = 0.1
        _ImpactFireStrenght ("Impact Fire Strength", Float) = 0.1 
        _ImpactEmissionColor ("Impact Fire Emission Color", Color) = (1, 0.5, 0, 1)
        _MaxEmissionStrength ("Max Emission Strength", Range(0, 10)) = 2.0
        _EmissionDecayTime ("Emission Decay Time", Float) = 1.5
        _MinPersistentEmission ("Min Persistent Emission", Range(0, 5)) = 0.2 

        _ImpactWindStrenght ("Impact Wind Strength", Float) = 0.1   
        _TwistAmount ("Twist Amount", Float) = 1.5
        _RadiusWind ("Wind Effect Radius", Range(0, 15)) = 0.2

        _EarthTex ("Earth Texture", 2D) = "white" {}
        _RadiusEarth ("Earth Effect Radius", Range(0, 15)) = 0.2
        _ImpactEarthStrenght ("Impact Earth Strength", Float) = 0.1

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
            sampler2D _ImpactTex;
            float4 _MainTex_ST;

            float _Distortion;
            float _RadiusWater;

            float _RadiusFire;
            float _EdgeSoftness;
            float4 _WaterColor;
            float _ReflectionStrength;
            float _ImpactFireStrenght;
            
            float4 _ImpactEmissionColor;
            float _MaxEmissionStrength;
            float _EmissionDecayTime;
            float _MinPersistentEmission;

            float _ImpactWindStrenght;
            float _TwistAmount;
            float _RadiusWind;

            sampler2D _EarthTex;
            float _RadiusEarth;
            float _ImpactEarthStrenght;

            float4 _PontoEmbateFireArray[512]; 
            float4 _PontoEmbateWaterArray[512]; 
            float4 _PontoEmbateWindArray[512];
            float4 _PontoEmbateEarthArray[512]; 

            float _BulletType;

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
                float3 worldNormalInput = UnityObjectToWorldNormal(v.normal);
                float3 modifiedWorldPos = worldVertex.xyz; 

                if (_BulletType == 0.0)
                {
                    for (int i = 0; i < 512; i++)
                    {
                        float4 ponto = _PontoEmbateFireArray[i];
                        if (ponto.w > 0.001)
                        {
                            float impactTime = ponto.w;
                            float age = _Time.y - impactTime;

                            float3 delta = modifiedWorldPos - ponto.xyz;
                            float dist = length(delta);

                            if (dist <= _RadiusFire)
                            {
                                float t = saturate(1.0 - dist / _RadiusFire);
                                t = t * t;
                                modifiedWorldPos -= worldNormalInput * _ImpactFireStrenght * t;
                            }
                        }
                    }
                }
                else if (_BulletType == 2.0)
                {
                    for (int i = 0; i < 512; i++)
                    {
                        float4 ponto = _PontoEmbateWindArray[i];
                        if (ponto.w > 0.0) 
                        {
                            float3 delta = modifiedWorldPos - ponto.xyz;
                            float dist = length(delta);

                            if (dist <= _RadiusWind)
                            {
                                float t = saturate(1.0 - dist / _RadiusWind);
                                t *= t;

                                modifiedWorldPos -= worldNormalInput * _ImpactWindStrenght * t;

                                float3 localDelta = delta;
                                float angle = _TwistAmount * t;
                                float sinA = sin(angle);
                                float cosA = cos(angle);

                                float rotatedX = localDelta.x * cosA - localDelta.y * sinA;
                                float rotatedY = localDelta.x * sinA + localDelta.y * cosA;

                                float3 twistedOffset = float3(rotatedX, rotatedY, 0) - float3(localDelta.x, localDelta.y, 0);
                                modifiedWorldPos += twistedOffset;
                            }
                        }
                    }
                }else if(_BulletType == 3.0)
                {
                    for (int i = 0; i < 512; i++)
                    {
                        float4 ponto = _PontoEmbateEarthArray[i];
                        if (ponto.w > 0.001) 
                        {
                            float impactTime = ponto.w;
                            float age = _Time.y - impactTime;

                            float3 delta = modifiedWorldPos - ponto.xyz;
                            float dist = length(delta);

                            if (dist <= _RadiusEarth)
                            {
                                float t = saturate(1.0 - dist / _RadiusEarth);
                                t = t * t; 

                                modifiedWorldPos += worldNormalInput * _ImpactEarthStrenght * t;
                            }
                        }
                    }
                }
                worldVertex.xyz = modifiedWorldPos; 

                o.vertex = UnityWorldToClipPos(worldVertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = worldVertex.xyz; 
                o.worldNormal = worldNormalInput; 
                o.viewDir = normalize(UnityWorldSpaceViewDir(worldVertex.xyz));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 baseColor = tex2D(_MainTex, i.uv);
                float3 accumulatedEmission = float3(0,0,0);
                if (_BulletType == 0.0)
                {
                    for (int k = 0; k < 512; k++)
                    {
                        float4 ponto = _PontoEmbateFireArray[k];
                        if (ponto.w > 0.001) 
                        {
                            float impactTime = ponto.w;
                            float age = _Time.y - impactTime; 
                            float currentEmissionStrength = 0;

                            if (age >= 0) 
                            {
                                if (age < _EmissionDecayTime)
                                {
                                    float normalizedAge = age / _EmissionDecayTime;
                                    currentEmissionStrength = lerp(_MaxEmissionStrength, _MinPersistentEmission, normalizedAge);
                                }
                                else
                                {
                                    currentEmissionStrength = _MinPersistentEmission;
                                }

                                float distToImpact = length(i.worldPos - ponto.xyz);
                                float impactMask = 1.0 - smoothstep(_RadiusFire - _EdgeSoftness, _RadiusFire, distToImpact);

                                if (impactMask > 0.0 && currentEmissionStrength > 0.0)
                                {
                                    fixed4 impactTextureColor = tex2D(_ImpactTex, i.uv); 
                                    accumulatedEmission += impactTextureColor.rgb * _ImpactEmissionColor.rgb * currentEmissionStrength * impactMask;
                                }
                            }
                        }
                    }
                }
                else if (_BulletType == 1.0)
                {
                    float pollutionAmount = 0.0;
                    for (int j = 0; j < 512; j++)
                    {
                        float4 ponto = _PontoEmbateWaterArray[j];
                        if (ponto.w > 0.0) 
                        {
                            float3 delta = i.worldPos - ponto.xyz;
                            float r = length(delta) / _RadiusWater;
                            float blob = exp(-r * r * 4.0); 
                            pollutionAmount += blob * ponto.w;
                        }
                    }
                    pollutionAmount = saturate(pollutionAmount);

                    if (pollutionAmount > 0.0)
                    {
                        float noise = tex2D(_NoiseTex, i.uv * 2.0 + _Time.y * 0.1).r;
                        float2 distortedUV = i.uv + (_Distortion * (noise - 0.5) * pollutionAmount);

                        fixed4 pollutionTex = tex2D(_PollutionTex, distortedUV);
                        fixed4 pollutionColor = lerp(_WaterColor, pollutionTex, 0.6);

                        float fresnel = 1.0 - saturate(dot(i.worldNormal, i.viewDir));
                        fresnel *= fresnel;
                        float reflection = fresnel * _ReflectionStrength * pollutionAmount;

                        baseColor = lerp(baseColor, pollutionColor, pollutionAmount);
                        baseColor.rgb += reflection * pollutionColor.rgb * 0.8; 
                        return baseColor; 
                    }
                }
                else if (_BulletType == 3.0)
                {
                    float4 earthResult = float4(0, 0, 0, 0);
                    float totalBlend = 0.0;

                    for (int k = 0; k < 512; k++)
                    {
                        float4 ponto = _PontoEmbateEarthArray[k];
                        if (ponto.w > 0.001) 
                        {
                            float distToImpact = length(i.worldPos - ponto.xyz);
                            float impactMask = 1.0 - smoothstep(_RadiusEarth - _EdgeSoftness, _RadiusEarth, distToImpact);

                            if (impactMask > 0.0)
                            {
                                float2 localUV = (i.worldPos.xz - ponto.xz) / (_RadiusEarth * 2) + 0.5;
                                if (all(localUV >= 0.0) && all(localUV <= 1.0))
                                {
                                    fixed4 tex = tex2D(_EarthTex, localUV);
                                    earthResult.rgb = lerp(earthResult.rgb, tex.rgb, impactMask);
                                    totalBlend = max(totalBlend, impactMask);
                                }
                            }
                        }
                    }

                    if (totalBlend > 0.0)
                    {
                        return lerp(baseColor, earthResult, totalBlend);
                    }
                }
                baseColor.rgb += accumulatedEmission;
                return baseColor;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}