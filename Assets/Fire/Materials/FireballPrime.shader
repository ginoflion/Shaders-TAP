Shader "Custom/SolidMagmaBall_OverallAnimSpeedScale_NoPulseBoost"
{
    Properties
    {
        // --- Core Magma ---
        _Color("Core Color", Color) = (1, 0.4, 0, 1)
        _MainTex("Magma Texture (RGB)", 2D) = "white" {} 
        _NoiseTex("Flow Noise (Grayscale)", 2D) = "gray" {} 

        // --- Global Animation & Scale ---
        _OverallSpeed("Overall Animation Speed", Range(0.1, 3)) = 1.0
        _TextureScale("Overall Texture Scale", Range(0.5, 5)) = 1.5
        
        _NoiseDistortion("Flow Noise Distortion for Magma UVs", Range(0, 0.2)) = 0.08

        // --- Emission ---
        _EmissionColor("Emission Color", Color) = (1, 0.2, 0, 1)
        _EmissionStrength("Emission Strength", Range(0, 15)) = 3.0
        _EmissionNoiseInfluence("Emission Noise Influence", Range(0, 1)) = 0.6 

        // --- Fresnel Glow ---
        _FresnelColor("Fresnel Glow Color", Color) = (1, 0.7, 0.1, 1)
        _FresnelPower("Fresnel Power", Range(0.1, 10)) = 4.0

        // --- Surface Flames ---
        _SurfaceFlameTex("Surface Flame Noise (Grayscale)", 2D) = "gray" {} 
        _SurfaceFlameColor("Surface Flame Color", Color) = (1, 0.6, 0.0, 1)
        _SurfaceFlameIntensity("Surface Flame Intensity", Range(0, 10)) = 2.5
        _SurfaceFlameThreshold("Surface Flame Noise Threshold", Range(0, 1)) = 0.65
        _SurfaceFlameSmoothness("Surface Flame Edge Smoothness", Range(0.01, 0.5)) = 0.1 

        // --- 3D Ripples - Vertex Displacement ---
        _Ripple3DCenterOS ("3D Ripple Center (Object Space)", Vector) = (0,0,0,0)
        _Ripple3DFrequency ("3D Ripple Frequency", Float) = 5.0
        _Ripple3DAmplitude ("3D Ripple Amplitude (Vertex Disp.)", Float) = 0.05
        // _Ripple3DEmissionBoost is removed
        _Ripple3DWaveColor("3D Ripple Wave Color", Color) = (1,0.9,0.5,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _NoiseTex;
        sampler2D _SurfaceFlameTex;

        struct Input
        {
            float2 uv_MainTex;      
            float3 worldNormal;     
            float3 viewDir;         
            float wave3D_fromVert : TEXCOORD1; 
        };

        // Uniforms
        half4 _Color;
        // Removed individual scroll speeds and scales, added global ones
        float _OverallSpeed;
        float _TextureScale;
        half _NoiseDistortion;
        
        half4 _EmissionColor;
        half _EmissionStrength, _EmissionNoiseInfluence;

        half4 _FresnelColor;
        half _FresnelPower;

        half4 _SurfaceFlameColor;
        half _SurfaceFlameIntensity; // Kept individual intensity
        // Removed _SurfaceFlameScrollSpeedY, _SurfaceFlameScale
        half _SurfaceFlameThreshold, _SurfaceFlameSmoothness;

        float4 _Ripple3DCenterOS; 
        float _Ripple3DFrequency;
        // Removed _Ripple3DSpeed
        float _Ripple3DAmplitude; 
        half4 _Ripple3DWaveColor;
        // End Uniforms

        // --- Hardcoded Factors for deriving speeds/scales from global controls ---
        static const float MAIN_TEX_SCROLL_X_FACTOR = 0.03;
        static const float MAIN_TEX_SCROLL_Y_FACTOR = 0.02;
        static const float NOISE_TEX_SCROLL_X_FACTOR = 0.07;
        static const float NOISE_TEX_SCROLL_Y_FACTOR = -0.05;
        static const float NOISE_TEX_SCALE_MULTIPLIER = 1.0; // Noise scale relative to _TextureScale
        
        static const float SURFACE_FLAME_SCROLL_Y_FACTOR = 0.3;
        static const float SURFACE_FLAME_SCALE_MULTIPLIER = 1.2; // Flames slightly larger scale than base

        static const float RIPPLE_3D_SPEED_FACTOR = 1.0;
        static const float PULSE_EMISSION_STRENGTH_FACTOR = 0.08; 


        // Helper for sine wave
        half CalculateWave(float dist, float frequency, float speed, float timeParam) 
        {
            return sin(dist * frequency - timeParam * speed);
        }
        // Helper for remapping wave from [-1,1] to [0,1]
        half RemapWaveTo01(half waveValue_neg1_pos1)
        {
            return saturate(waveValue_neg1_pos1 * 0.5h + 0.5h);
        }
        // Helper for scrolling UVs based on global speed
        float2 ScrollUV(float2 uv, float scrollX_factor, float scrollY_factor, float globalSpeed, float timeParam)
        {
            float GSpeed = globalSpeed * timeParam;
            uv.x += GSpeed * scrollX_factor;
            uv.y += GSpeed * scrollY_factor;
            return uv;
        }


        // Vertex Modifier Function
        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            float3 objectPos = v.vertex.xyz;
            float3 rippleCenterOS_val = _Ripple3DCenterOS.xyz; 
            
            float distFrom3DCenter = length(objectPos - rippleCenterOS_val);
            // 3D Ripple speed now uses _OverallSpeed
            float currentRippleSpeed = RIPPLE_3D_SPEED_FACTOR * _OverallSpeed;
            half wave3DValue = CalculateWave(distFrom3DCenter, _Ripple3DFrequency, currentRippleSpeed, _Time.y);
            
            float3 displacement = v.normal * wave3DValue * _Ripple3DAmplitude;
            v.vertex.xyz += displacement;

            o.wave3D_fromVert = wave3DValue;
        }


        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Base UVs (NO UV RIPPLE HERE)
            float2 base_uv = IN.uv_MainTex;

            // --- 1. Núcleo de Magma ---
            // Noise texture UVs: uses _TextureScale and _OverallSpeed
            float2 scrolledNoiseUV = ScrollUV(base_uv * (_TextureScale * NOISE_TEX_SCALE_MULTIPLIER), 
                                              NOISE_TEX_SCROLL_X_FACTOR, 
                                              NOISE_TEX_SCROLL_Y_FACTOR, 
                                              _OverallSpeed, _Time.y);
            half noiseVal = tex2D(_NoiseTex, scrolledNoiseUV).r;

            // Main texture UVs: uses _TextureScale and _OverallSpeed
            float2 mainTexScaledUV = base_uv * _TextureScale;
            float2 mainTexScrolledUV = ScrollUV(mainTexScaledUV, 
                                                MAIN_TEX_SCROLL_X_FACTOR, 
                                                MAIN_TEX_SCROLL_Y_FACTOR, 
                                                _OverallSpeed, _Time.y);
            float2 distortedMainUV = mainTexScrolledUV + (noiseVal - 0.5h) * _NoiseDistortion;
            
            half4 mainTexCol = tex2D(_MainTex, distortedMainUV); 
            half3 albedo = mainTexCol.rgb * _Color.rgb; 

            // --- Summing Emissions ---
            half3 totalEmission = (half3)0;

            // --- 2. Emissão do Núcleo ---
            half emissionNoiseFactor = lerp(1.0h, noiseVal, _EmissionNoiseInfluence); 
            totalEmission += _EmissionColor.rgb * _EmissionStrength * emissionNoiseFactor;

            // --- 3. Brilho Fresnel ---
            half3 N = normalize(IN.worldNormal); 
            half3 V = normalize(IN.viewDir);     
            half fresnel = 1.0h - saturate(dot(N, V));
            fresnel = pow(fresnel, _FresnelPower);
            totalEmission += _FresnelColor.rgb * fresnel * _EmissionStrength;

            // --- 4. Chamas na Superfície ---
            // Surface flame UVs: uses _TextureScale and _OverallSpeed
            float2 surfaceFlameScaledUV = base_uv * (_TextureScale * SURFACE_FLAME_SCALE_MULTIPLIER);
            float2 surfaceFlameUV = ScrollUV(surfaceFlameScaledUV, 
                                             0.0h, // No X scroll for flames usually
                                             SURFACE_FLAME_SCROLL_Y_FACTOR, 
                                             _OverallSpeed, _Time.y);
            half surfaceFlameNoiseVal = tex2D(_SurfaceFlameTex, surfaceFlameUV).r;
            half surfaceFlameMask = smoothstep(
                _SurfaceFlameThreshold,
                _SurfaceFlameThreshold + _SurfaceFlameSmoothness,
                surfaceFlameNoiseVal
            );
            totalEmission += _SurfaceFlameColor.rgb * surfaceFlameMask * _SurfaceFlameIntensity;

            // --- 5. 3D Ripple Emission ---
            half3 pulseBaseEmission = _Ripple3DWaveColor.rgb * RemapWaveTo01(IN.wave3D_fromVert);
            totalEmission += pulseBaseEmission * _EmissionStrength * PULSE_EMISSION_STRENGTH_FACTOR;


            // --- Combinar Tudo ---
            o.Albedo = albedo;
            o.Emission = totalEmission; 
            o.Metallic = 0.0h;    
            o.Smoothness = 0.15h; 
            o.Alpha = 1.0h;       
        }
        ENDCG
    }
    FallBack "Diffuse"
}