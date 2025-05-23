Shader "Custom/SolidMagmaBall_SimplifiedInspector"
{
    Properties
    {
        // --- Core Magma ---
        _Color("Core Color", Color) = (1, 0.4, 0, 1)
        _MainTex("Magma Texture (RGB)", 2D) = "white" {} // Cracks, rock texture
        _NoiseTex("Flow Noise (Grayscale)", 2D) = "gray" {} // For distortion and flow

        _OverallSpeed("Overall Animation Speed", Range(0.1, 3)) = 1.0
        _TextureScale("Overall Texture Scale", Range(0.5, 5)) = 1.5
        _NoiseDistortion("Flow Noise Distortion", Range(0, 0.2)) = 0.08

        // --- Emission ---
        _EmissionColor("Emission Color", Color) = (1, 0.2, 0, 1)
        _EmissionStrength("Emission Strength", Range(0, 15)) = 3.0
        _EmissionNoiseInfluence("Emission Noise Influence", Range(0, 1)) = 0.6 // How much flow noise affects emission brightness

        // --- Fresnel Glow ---
        _FresnelColor("Fresnel Glow Color", Color) = (1, 0.7, 0.1, 1)
        _FresnelPower("Fresnel Power", Range(0.1, 10)) = 4.0

        // --- Surface Activity (Simplified Flames/Hotspots) ---
        _SurfaceActivityTex("Surface Activity Noise (Grayscale)", 2D) = "gray" {} // Could be same as _NoiseTex
        _SurfaceActivityColor("Surface Activity Color", Color) = (1, 0.6, 0.0, 1)
        _SurfaceActivityIntensity("Surface Activity Intensity", Range(0, 10)) = 2.0
        _SurfaceActivityThreshold("Surface Activity Threshold", Range(0.1, 0.9)) = 0.65

        // --- 3D Pulsing Ripple (Vertex Displacement) ---
        _Ripple3DAmplitude("3D Pulse Amplitude", Float) = 0.05 // How much vertices move
        _Ripple3DFrequency("3D Pulse Frequency", Float) = 3.0   // How many waves from center
        _Ripple3DEmissionBoost("3D Pulse Emission Boost", Range(0,5)) = 0.8
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 3.0

        // Samplers
        sampler2D _MainTex;
        sampler2D _NoiseTex;
        sampler2D _SurfaceActivityTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldNormal;
            float3 viewDir;
            float wave3D_fromVert : TEXCOORD1; 
        };

        // --- Uniforms ---
        half4 _Color;
        float _OverallSpeed;
        float _TextureScale;
        half _NoiseDistortion;
        
        half4 _EmissionColor;
        half _EmissionStrength, _EmissionNoiseInfluence;

        half4 _FresnelColor;
        half _FresnelPower;

        half4 _SurfaceActivityColor;
        half _SurfaceActivityIntensity, _SurfaceActivityThreshold;

        // 3D Ripple - Note: Speed and Center are now hardcoded/derived
        float _Ripple3DAmplitude;
        float _Ripple3DFrequency;
        half _Ripple3DEmissionBoost;
        // --- End Uniforms ---

        // --- Hardcoded/Derived Values (Simplification) ---
        static const float MAIN_TEX_SCROLL_X_FACTOR = 0.03;
        static const float MAIN_TEX_SCROLL_Y_FACTOR = 0.02;
        static const float NOISE_TEX_SCROLL_X_FACTOR = 0.07;
        static const float NOISE_TEX_SCROLL_Y_FACTOR = -0.05;
        static const float SURFACE_ACTIVITY_SCROLL_Y_FACTOR = 0.3;
        static const float RIPPLE_3D_SPEED_FACTOR = 1.0;
        static const float3 RIPPLE_3D_CENTER_OS = float3(0,0,0); // Object space center

        // --- HELPER FUNCTIONS ---
        half CalculateWave(float dist, float frequency, float speed, float timeParam) 
        {
            return sin(dist * frequency - timeParam * speed);
        }
        float2 ScrollUV(float2 uv, float scrollX, float scrollY) // timeParam is now global via _OverallSpeed * _Time.y
        {
            float timeScaled = _Time.y * _OverallSpeed;
            uv.x += timeScaled * scrollX;
            uv.y += timeScaled * scrollY;
            return uv;
        }
        half RemapWaveTo01(half waveValue_neg1_pos1) { return saturate(waveValue_neg1_pos1 * 0.5h + 0.5h); }

        // --- VERTEX SHADER ---
        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            float3 objectPos = v.vertex.xyz;
            float distFrom3DCenter = length(objectPos - RIPPLE_3D_CENTER_OS);
            
            // Use _OverallSpeed to affect 3D ripple speed
            float rippleSpeed = RIPPLE_3D_SPEED_FACTOR * _OverallSpeed;
            half wave3DValue = CalculateWave(distFrom3DCenter, _Ripple3DFrequency, rippleSpeed, _Time.y); // Time.y direct here, speed scaled
            
            v.vertex.xyz += v.normal * wave3DValue * _Ripple3DAmplitude;
            o.wave3D_fromVert = wave3DValue;
        }

        // --- SURFACE SHADER ---
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 base_uv = IN.uv_MainTex; // Using a shorter name

            // 1. Flow Noise (used for distortion and emission influence)
            float2 noiseUV = ScrollUV(base_uv * _TextureScale * 1.2, // Noise slightly different scale
                                      NOISE_TEX_SCROLL_X_FACTOR, 
                                      NOISE_TEX_SCROLL_Y_FACTOR);
            half noiseVal = tex2D(_NoiseTex, noiseUV).r;
            
            // 2. Main Magma Texture & Albedo
            float2 mainTexUV_scaled = base_uv * _TextureScale;
            float2 mainTexUV_scrolled = ScrollUV(mainTexUV_scaled, 
                                                 MAIN_TEX_SCROLL_X_FACTOR, 
                                                 MAIN_TEX_SCROLL_Y_FACTOR);
            float2 mainTexUV_distorted = mainTexUV_scrolled + (noiseVal - 0.5h) * _NoiseDistortion;
            
            half3 mainTexColor = tex2D(_MainTex, mainTexUV_distorted).rgb;
            o.Albedo = mainTexColor * _Color.rgb;

            // 3. Emission Components
            half3 totalEmission = (half3)0;

            // 3a. Core Emission
            half emissionNoiseFactor = lerp(1.0h, noiseVal, _EmissionNoiseInfluence);
            totalEmission += _EmissionColor.rgb * _EmissionStrength * emissionNoiseFactor;

            // 3b. Fresnel Emission
            half3 N = normalize(IN.worldNormal);
            half3 V = normalize(IN.viewDir);
            half fresnelTerm = pow(1.0h - saturate(dot(N, V)), _FresnelPower);
            totalEmission += _FresnelColor.rgb * fresnelTerm * _EmissionStrength * 0.75; // Fresnel slightly less strong than core

            // 3c. Surface Activity (Simplified Flames/Hotspots)
            // Uses its own texture, scrolls only vertically, different scale.
            // Could reuse _NoiseTex if _SurfaceActivityTex is the same.
            float2 activityUV_scaled = base_uv * _TextureScale * 1.5; // Activity different scale
            float2 activityUV = ScrollUV(activityUV_scaled, 0.0h, SURFACE_ACTIVITY_SCROLL_Y_FACTOR);
            half activityNoise = tex2D(_SurfaceActivityTex, activityUV).r;
            half activityMask = smoothstep(_SurfaceActivityThreshold - 0.05, // Slightly softer thresholding
                                           _SurfaceActivityThreshold + 0.05, 
                                           activityNoise);
            totalEmission += _SurfaceActivityColor.rgb * activityMask * _SurfaceActivityIntensity;
            
            // 3d. 3D Ripple Emission
            // Use a fixed color for 3D ripple emission, or derive from _EmissionColor
            half3 ripple3DWaveColor = _EmissionColor.rgb * 1.5; // Brighter version of core emission for ripples
            totalEmission += ripple3DWaveColor * RemapWaveTo01(IN.wave3D_fromVert) * _Ripple3DEmissionBoost;

            o.Emission = totalEmission;
            
            // 4. Other Standard Surface Properties
            o.Metallic = 0.0h;    
            o.Smoothness = 0.15h; 
            o.Alpha = 1.0h;       
        }
        ENDCG
    }
    FallBack "Diffuse"
}