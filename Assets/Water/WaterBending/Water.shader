Shader "Unlit/WaterBendingEnhanced" 
{     
    Properties     
    {         
        _MainTex("Main Texture", 2D) = "white" {}         
        _NoiseTex("Noise Texture", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
        
        [Header(Flow Animation)]
        _Speed("Flow Speed", Float) = 1.0         
        _FlowSpeed2("Secondary Flow Speed", Float) = 0.7
        _DistortionStrength("Distortion Strength", Float) = 0.08         
        
        [Header(Wave Properties)]
        _WaveHeight("Wave Height", Float) = 0.15         
        _WaveFrequency("Wave Frequency", Float) = 8.0
        _WaveSpeed("Wave Speed", Float) = 2.0
        _SecondaryWaveHeight("Secondary Wave Height", Float) = 0.08
        _SecondaryWaveFreq("Secondary Wave Frequency", Float) = 12.0
        
        [Header(Visual Effects)]         
        _Alpha("Base Alpha", Range(0,1)) = 0.6         
        _FresnelColor("Fresnel Color", Color) = (0.4, 0.8, 1.0, 1)         
        _FresnelPower("Fresnel Power", Float) = 3.0         
        _ColorTint("Water Tint", Color) = (0.3, 0.7, 1.0, 1)
        _DeepWaterColor("Deep Water Color", Color) = (0.1, 0.3, 0.6, 1)
        
        [Header(Surface Details)]
        _Foam("Foam Intensity", Range(0,2)) = 0.5
        _FoamColor("Foam Color", Color) = (0.9, 0.95, 1.0, 1)
        _Sparkle("Sparkle Intensity", Range(0,1)) = 0.3
        _SparkleSize("Sparkle Size", Float) = 20.0
        
        [Header(Refraction)]
        _RefractionStrength("Refraction Strength", Float) = 0.1
        _Depth("Water Depth Effect", Float) = 1.5     
    }      

    SubShader     
    {         
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }         
        LOD 300         
        Cull Off         
        ZWrite Off         
        Blend SrcAlpha OneMinusSrcAlpha          

        Pass         
        {             
            CGPROGRAM             
            #pragma vertex vert             
            #pragma fragment frag
            #pragma multi_compile_fog             
            #include "UnityCG.cginc"              

            sampler2D _MainTex;             
            sampler2D _NoiseTex;
            sampler2D _NormalMap;             
            float4 _MainTex_ST;
            float4 _NoiseTex_ST;             
            float _Speed, _FlowSpeed2;             
            float _DistortionStrength;             
            float _WaveHeight, _WaveFrequency, _WaveSpeed;
            float _SecondaryWaveHeight, _SecondaryWaveFreq;             
            float _Alpha;             
            float4 _FresnelColor;             
            float _FresnelPower;             
            float4 _ColorTint, _DeepWaterColor;
            float _Foam, _Sparkle, _SparkleSize;
            float4 _FoamColor;
            float _RefractionStrength, _Depth;              

            struct appdata             
            {                 
                float4 vertex : POSITION;                 
                float3 normal : NORMAL;
                float4 tangent : TANGENT;                 
                float2 uv : TEXCOORD0;             
            };              

            struct v2f             
            {                 
                float2 uv : TEXCOORD0;                 
                float4 vertex : SV_POSITION;                 
                float3 worldNormal : TEXCOORD1;                 
                float3 worldViewDir : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float4 screenPos : TEXCOORD4;
                UNITY_FOG_COORDS(5)             
            };

            // Função de ruído melhorada
            float hash(float2 p) 
            {
                return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
            }

            float noise(float2 p) 
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);
                return lerp(lerp(hash(i + float2(0,0)), hash(i + float2(1,0)), u.x),
                           lerp(hash(i + float2(0,1)), hash(i + float2(1,1)), u.x), u.y);
            }

            // Ruído fractal para detalhes complexos
            float fbm(float2 p) 
            {
                float value = 0.0;
                float amplitude = 0.5;
                for(int i = 0; i < 5; i++) 
                {
                    value += amplitude * noise(p);
                    p *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }              

            v2f vert (appdata v)             
            {                 
                v2f o;
                float time = _Time.y;
                float waveTime = time * _WaveSpeed;
                
                float3 pos = v.vertex.xyz;
                
                // Ondas primárias mais orgânicas
                float wave1 = sin((pos.x + pos.z) * _WaveFrequency + waveTime) * _WaveHeight;
                float wave2 = cos((pos.x - pos.z * 0.7) * _WaveFrequency * 1.3 + waveTime * 1.1) * _WaveHeight * 0.7;
                
                // Ondas secundárias para detalhes
                float wave3 = sin(pos.x * _SecondaryWaveFreq + waveTime * 2.0) * cos(pos.z * _SecondaryWaveFreq * 0.8 + waveTime * 1.5) * _SecondaryWaveHeight;
                float wave4 = cos(pos.y * _SecondaryWaveFreq * 1.2 + waveTime * 0.8) * sin(pos.x * _SecondaryWaveFreq * 0.9 + waveTime * 1.8) * _SecondaryWaveHeight * 0.6;
                
                // Movimento espiral orgânico
                float spiral = sin(length(pos.xz) * 8.0 - waveTime * 2.0) * cos(atan2(pos.z, pos.x) * 3.0 + waveTime) * _WaveHeight * 0.3;
                
                // Combinar todas as ondas
                pos.y += wave1 + wave2 + wave3 + wave4 + spiral;
                
                // Pequeno movimento lateral para fluidez
                pos.x += sin(pos.y * 10.0 + waveTime * 1.5) * 0.02;
                pos.z += cos(pos.y * 8.0 + waveTime * 1.8) * 0.02;

                o.vertex = UnityObjectToClipPos(float4(pos, 1.0));                 
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.vertex);                  

                float3 worldPos = mul(unity_ObjectToWorld, float4(pos, 1.0)).xyz;
                o.worldPos = worldPos;                 
                o.worldNormal = UnityObjectToWorldNormal(v.normal);                 
                o.worldViewDir = normalize(_WorldSpaceCameraPos - worldPos);
                
                UNITY_TRANSFER_FOG(o, o.vertex);                  

                return o;             
            }              

            fixed4 frag (v2f i) : SV_Target             
            {                 
                float time = _Time.y;
                
                // Múltiplas camadas de fluxo para movimento complexo
                float2 flow1 = float2(time * _Speed * 0.1, time * _Speed * 0.05);
                float2 flow2 = float2(-time * _FlowSpeed2 * 0.08, time * _FlowSpeed2 * 0.12);
                
                // Distorção UV com múltiplas camadas de ruído
                float2 noiseUV1 = i.uv * 4.0 + flow1;
                float2 noiseUV2 = i.uv * 2.5 + flow2;
                
                float2 noise1 = tex2D(_NoiseTex, noiseUV1).rg;
                float2 noise2 = tex2D(_NoiseTex, noiseUV2).rg;
                
                // Combinar ruídos para distorção mais orgânica
                float2 combinedNoise = (noise1 + noise2 * 0.7) - float2(0.85, 0.85);
                float2 distortedUV = i.uv + combinedNoise * _DistortionStrength;
                
                // Movimento adicional baseado em posição mundial
                float2 worldFlow = float2(
                    sin(i.worldPos.x * 2.0 + time * 1.5) * 0.01,
                    cos(i.worldPos.z * 3.0 + time * 2.0) * 0.01
                );
                distortedUV += worldFlow;

                // Textura base                 
                fixed4 col = tex2D(_MainTex, distortedUV);
                
                // Profundidade simulada
                float depth = saturate(fbm(i.uv * 3.0 + time * 0.1) * _Depth);
                col.rgb = lerp(_ColorTint.rgb, _DeepWaterColor.rgb, depth * 0.6);

                // Efeito Fresnel melhorado                 
                float fresnel = pow(1.0 - saturate(dot(normalize(i.worldNormal), normalize(i.worldViewDir))), _FresnelPower);
                
                // Brilhos e espuma nas bordas
                float foam = pow(fresnel, 0.8) * _Foam;
                float3 foamColor = _FoamColor.rgb * foam;
                
                // Sparkles dinâmicos
                float sparkleNoise = fbm(i.uv * _SparkleSize + time * 2.0);
                float sparkle = pow(saturate(sparkleNoise), 6.0) * _Sparkle * fresnel;
                
                // Variação de cor baseada no movimento
                float colorVariation = sin(i.worldPos.x * 5.0 + time) * cos(i.worldPos.z * 4.0 + time * 1.2) * 0.1 + 1.0;
                col.rgb *= colorVariation;
                
                // Combinar todos os efeitos
                col.rgb += _FresnelColor.rgb * fresnel * 0.8;
                col.rgb += foamColor;
                col.rgb += float3(1,1,1) * sparkle;
                
                // Alpha dinâmico
                float dynamicAlpha = _Alpha + fresnel * 0.3 + foam * 0.2;
                dynamicAlpha *= (0.8 + depth * 0.4); // Variação baseada na profundidade
                
                col.a = saturate(dynamicAlpha);
                
                UNITY_APPLY_FOG(i.fogCoord, col);                 
                return col;             
            }             
            ENDCG         
        }     
    }     
    FallBack "Unlit/Transparent" 
}