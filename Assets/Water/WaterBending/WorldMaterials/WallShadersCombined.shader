Shader "Unlit/WallShadersCombined"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _PollutionTex ("Pollution Texture (for Type 1)", 2D) = "white" {}
        _NoiseTex ("Distortion Noise (for Type 1)", 2D) = "white" {}
        _ImpactTex ("Impact Texture (for Type 0)", 2D) = "white" {}

        _Distortion ("Distortion Strength (Type 1)", Range(0, 1)) = 0.1
        _Radius ("Effect Radius", Range(0, 15)) = 0.2
        _EdgeSoftness ("Edge Softness (Type 0)", Range(0.01, 1)) = 0.1
        _MainColor ("Main Pollution Color (Type 1)", Color) = (0.2, 0.4, 0.3, 1)
        _ReflectionStrength ("Reflection Strength (Type 1)", Range(0, 1)) = 0.3
        _ImpactPushStrength ("Impact Push Strength (Type 0)", Float) = 0.1 // NOVO
        _TwistAmount ("Twist Amount (Type 2 - Wind)", Float) = 1.5
        _BulletType  ("Bullet Type", Float) = 0.0 // 0:ImpactEmissive+Dent, 1:Water/Pollution, 2:Wind

        _ImpactEmissionColor ("Impact Emission Color (Type 0)", Color) = (1, 0.5, 0, 1)
        _MaxEmissionStrength ("Max Emission Strength (Type 0)", Range(0, 10)) = 2.0
        _EmissionDecayTime ("Emission Decay Time (seconds) (Type 0)", Float) = 1.5
        _MinPersistentEmission ("Min Persistent Emission (Type 0)", Range(0, 5)) = 0.2 // NOVO
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
            float _Radius;
            float _EdgeSoftness;
            float4 _MainColor;
            float _ReflectionStrength;
            float _ImpactPushStrength; // NOVO
            float _TwistAmount;
            float _BulletType;

            float4 _ImpactEmissionColor;
            float _MaxEmissionStrength;
            float _EmissionDecayTime;
            float _MinPersistentEmission; // NOVO

            float4 _PontoEmbateFireArray[1024];  // Type 0: xyz=pos, w=impactTime
            float4 _PontoEmbateWaterArray[1024]; // Type 1: xyz=pos, w=intensity
            float4 _PontoEmbateWindArray[1024];  // Type 2: xyz=pos, w=intensity

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
                float3 worldNormal : TEXCOORD2; // Normal original, não deformada
                float3 viewDir : TEXCOORD3;
            };

            v2f vert(appdata v)
            {
                v2f o;
                float4 worldVertex = mul(unity_ObjectToWorld, v.vertex);
                float3 worldNormalInput = UnityObjectToWorldNormal(v.normal);
                float3 modifiedWorldPos = worldVertex.xyz; // Começa com a posição original

                // Efeito de Amassado/Dent (BulletType == 0.0)
                if (_BulletType == 0.0)
                {
                    for (int i = 0; i < 1024; i++)
                    {
                        float4 ponto = _PontoEmbateFireArray[i];
                        if (ponto.w > 0.001) // Se o impacto está ativo (tempo de impacto válido)
                        {
                            float impactTime = ponto.w;
                            float age = _Time.y - impactTime;

                            // O amassado deve persistir enquanto o efeito de glow estiver ativo,
                            // ou talvez por um tempo um pouco maior.
                            // Por simplicidade, vamos fazê-lo persistir enquanto age < _EmissionDecayTime * 1.5 (um pouco mais que o glow forte)
                            // Ou, para que o amassado seja tão persistente quanto o brilho mínimo,
                            // ele só desaparece quando o ponto é sobrescrito no array.
                            // A condição ponto.w > 0.001 já garante isso.

                            float3 delta = modifiedWorldPos - ponto.xyz;
                            float dist = length(delta);

                            if (dist <= _Radius)
                            {
                                float t = saturate(1.0 - dist / _Radius);
                                t = t * t; // Para um falloff mais acentuado (quadrático)

                                // Empurra o vértice para dentro ao longo da sua normal original
                                // O ponto.w (tempo) não é usado para a força aqui, apenas para saber se está ativo.
                                modifiedWorldPos -= worldNormalInput * _ImpactPushStrength * t;
                            }
                        }
                    }
                }
                // Efeito de Vento (BulletType == 2.0)
                else if (_BulletType == 2.0)
                {
                    for (int i = 0; i < 1024; i++)
                    {
                        float4 ponto = _PontoEmbateWindArray[i];
                        if (ponto.w > 0.0) // ponto.w é a intensidade
                        {
                            float3 delta = modifiedWorldPos - ponto.xyz;
                            float dist = length(delta);

                            if (dist <= _Radius)
                            {
                                float t = saturate(1.0 - dist / _Radius);
                                t *= t;

                                // Empurrão ao longo da normal
                                modifiedWorldPos -= worldNormalInput * _ImpactPushStrength * t * ponto.w; // renomeei _Impact para _ImpactPushStrength antes, mas wind usava _Impact. Usando _ImpactPushStrength aqui também.
                                                                                                // Se quiser um valor diferente para wind, crie _WindPushStrength

                                // Torção
                                float3 localDelta = delta;
                                float angle = _TwistAmount * t * ponto.w;
                                float sinA = sin(angle);
                                float cosA = cos(angle);

                                float rotatedX = localDelta.x * cosA - localDelta.z * sinA;
                                float rotatedZ = localDelta.x * sinA + localDelta.z * cosA;

                                float3 twistedOffset = float3(rotatedX, localDelta.y, rotatedZ) - localDelta;
                                modifiedWorldPos += twistedOffset;
                            }
                        }
                    }
                }
                
                worldVertex.xyz = modifiedWorldPos; // Aplica a modificação final

                o.vertex = UnityWorldToClipPos(worldVertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = worldVertex.xyz; // Posição mundial potencialmente modificada
                o.worldNormal = worldNormalInput; // Passar a normal original para o fragment shader
                o.viewDir = normalize(UnityWorldSpaceViewDir(worldVertex.xyz));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 baseColor = tex2D(_MainTex, i.uv);
                float3 accumulatedEmission = float3(0,0,0);

                // Efeito de Impacto Emissivo + Textura Persistente (BulletType == 0.0)
                if (_BulletType == 0.0)
                {
                    for (int k = 0; k < 1024; k++)
                    {
                        float4 ponto = _PontoEmbateFireArray[k];
                        if (ponto.w > 0.001) 
                        {
                            float impactTime = ponto.w;
                            float age = _Time.y - impactTime; 
                            float currentEmissionStrength = 0;

                            if (age >= 0) // Impacto aconteceu ou está acontecendo
                            {
                                if (age < _EmissionDecayTime)
                                {
                                    // Interpola do máximo para o mínimo durante o tempo de decaimento
                                    float normalizedAge = age / _EmissionDecayTime;
                                    currentEmissionStrength = lerp(_MaxEmissionStrength, _MinPersistentEmission, normalizedAge);
                                }
                                else
                                {
                                    // Após o tempo de decaimento, mantém o brilho mínimo
                                    currentEmissionStrength = _MinPersistentEmission;
                                }

                                // O impacto só deixa de ser renderizado quando seu slot no array é sobrescrito
                                // por um novo impacto (devido ao buffer circular no C#).

                                float distToImpact = length(i.worldPos - ponto.xyz);
                                float impactMask = 1.0 - smoothstep(_Radius - _EdgeSoftness, _Radius, distToImpact);

                                if (impactMask > 0.0 && currentEmissionStrength > 0.0)
                                {
                                    fixed4 impactTextureColor = tex2D(_ImpactTex, i.uv); 
                                    accumulatedEmission += impactTextureColor.rgb * _ImpactEmissionColor.rgb * currentEmissionStrength * impactMask;
                                }
                            }
                        }
                    }
                    // A cor base NÃO é modificada aqui, apenas a emissão é adicionada.
                    // Se você quiser que a textura de impacto substitua a _MainTex na área afetada:
                    // float totalImpactMaskForAlbedo = 0;
                    // (calcular totalImpactMaskForAlbedo de forma similar a accumulatedEmission, mas sem strength, só a máscara)
                    // baseColor.rgb = lerp(baseColor.rgb, tex2D(_ImpactTex, i.uv).rgb * _ImpactEmissionColor.rgb, saturate(totalImpactMaskForAlbedo));
                    // Mas para um "glow" em cima, adicionar à emissão é o correto.
                }
                // Efeito de Poluição/Água (BulletType == 1.0)
                else if (_BulletType == 1.0)
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
                        float noise = tex2D(_NoiseTex, i.uv * 2.0 + _Time.y * 0.1).r;
                        float2 distortedUV = i.uv + (_Distortion * (noise - 0.5) * pollutionAmount);

                        fixed4 pollutionTex = tex2D(_PollutionTex, distortedUV);
                        fixed4 pollutionColor = lerp(_MainColor, pollutionTex, 0.6);

                        float fresnel = 1.0 - saturate(dot(i.worldNormal, i.viewDir));
                        fresnel *= fresnel;
                        float reflection = fresnel * _ReflectionStrength * pollutionAmount;

                        baseColor = lerp(baseColor, pollutionColor, pollutionAmount);
                        baseColor.rgb += reflection * pollutionColor.rgb * 0.8; 
                        return baseColor; 
                    }
                }
                
                baseColor.rgb += accumulatedEmission; // Adiciona a emissão acumulada (do tipo 0, se houver)
                return baseColor;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}