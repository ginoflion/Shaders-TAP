Shader "Custom/GroundWetTrail"
{
    Properties
    {
        _MainTex ("Ground Texture", 2D) = "white" {}
        _WetTex ("Wet Texture", 2D) = "white" {}
        _TrailColor ("Trail Color", Color) = (0.2, 0.3, 0.5, 1)
        _TrailIntensity ("Trail Intensity", Range(0, 2)) = 1.0
        _TrailRadius ("Trail Radius", Range(0.1, 5.0)) = 1.0
        _TrailFalloff ("Trail Falloff", Range(0.1, 3.0)) = 1.0
        _OrbPosition ("Orb Position", Vector) = (0, 0, 0, 0)
        _TrailPositions ("Trail Positions", Vector) = (0, 0, 0, 0)
        _MaxTrails ("Max Trails", Int) = 50
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_WetTex);
            SAMPLER(sampler_WetTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _WetTex_ST;
                float4 _TrailColor;
                float _TrailIntensity;
                float _TrailRadius;
                float _TrailFalloff;
                float4 _OrbPosition;
                int _MaxTrails;
            CBUFFER_END
            
            // Array to store trail positions (you'll update this from script)
            float4 _TrailPositions[50];
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionHCS = vertexInput.positionCS;
                output.worldPos = vertexInput.positionWS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                return output;
            }
            
            float4 frag(Varyings input) : SV_Target
            {
                // Sample base ground texture
                float4 groundColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float4 wetColor = SAMPLE_TEXTURE2D(_WetTex, sampler_WetTex, input.uv);
                
                // Calculate distance to current orb position
                float2 worldXZ = input.worldPos.xz;
                float2 orbXZ = _OrbPosition.xz;
                float distanceToOrb = distance(worldXZ, orbXZ);
                
                // Calculate wet trail effect
                float trailMask = 0.0;
                
                // Current orb position effect
                if (distanceToOrb < _TrailRadius)
                {
                    float orbEffect = 1.0 - smoothstep(0.0, _TrailRadius, distanceToOrb);
                    orbEffect = pow(orbEffect, _TrailFalloff);
                    trailMask = max(trailMask, orbEffect);
                }
                
                // Trail positions effect (for persistent trails)
                for (int i = 0; i < _MaxTrails; i++)
                {
                    float2 trailPos = _TrailPositions[i].xy;
                    float trailAge = _TrailPositions[i].z; // Age factor (0-1, where 1 is newest)
                    
                    if (trailAge > 0.0)
                    {
                        float distanceToTrail = distance(worldXZ, trailPos);
                        if (distanceToTrail < _TrailRadius)
                        {
                            float trailEffect = 1.0 - smoothstep(0.0, _TrailRadius, distanceToTrail);
                            trailEffect = pow(trailEffect, _TrailFalloff);
                            trailEffect *= trailAge; // Fade based on age
                            trailMask = max(trailMask, trailEffect);
                        }
                    }
                }
                
                // Blend between dry and wet
                float4 finalColor = lerp(groundColor, wetColor * _TrailColor, trailMask * _TrailIntensity);
                
                return finalColor;
            }
            ENDHLSL
        }
    }
}