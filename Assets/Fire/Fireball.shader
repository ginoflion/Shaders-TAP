Shader "Custom/MagmaFireballEmittingFlames"
{
    Properties
    {
        // Magma Core
        _Color("Core Color", Color) = (1, 0.5, 0, 1)
        _MainTex("Magma Texture (RGB)", 2D) = "white" {}
        _NoiseTex("Flow Noise Texture (Grayscale)", 2D) = "gray" {}
        _ScrollSpeedMainX ("Magma Scroll Speed X", Float) = 0.05
        _ScrollSpeedMainY ("Magma Scroll Speed Y", Float) = 0.03
        _MagmaTexScale ("Magma Texture Scale", Float) = 1.0
        _ScrollSpeedNoiseX ("Flow Noise Scroll X", Float) = 0.1
        _ScrollSpeedNoiseY ("Flow Noise Scroll Y", Float) = -0.08
        _NoiseTexScale ("Flow Noise Scale", Float) = 2.0
        _NoiseDistortion ("Flow Noise Distortion for Magma", Range(0, 0.2)) = 0.05
        _EmissionColor("Core Emission Color", Color) = (1, 0.2, 0, 1)
        _EmissionStrength("Core Emission Strength", Range(0, 10)) = 2.0
        _EmissionNoiseInfluence("Core Emission Noise Influence", Range(0, 1)) = 0.5

        // Fresnel
        _FresnelColor("Fresnel Glow Color", Color) = (1, 0.8, 0.2, 1)
        _FresnelPower("Fresnel Power", Range(0.1, 10)) = 3.0

        // Emitting Flames
        _FlameAppearanceTex("Flame Appearance Noise (Grayscale)", 2D) = "gray" {} // Noise for flame visual shape
        _FlameColor("Flame Color", Color) = (1, 0.7, 0.1, 0.8) // RGBA, A for flame opacity
        _FlameIntensity("Flame Emission Intensity", Range(0, 10)) = 3.0
        _FlameScrollSpeedY("Flame Visual Scroll Y", Float) = 0.8
        _FlameScale("Flame Visual Scale", Float) = 2.5
        _FlameThreshold("Flame Visual Threshold", Range(0, 1)) = 0.55
        _FlameSmoothness("Flame Visual Edge Smoothness", Range(0.01, 0.5)) = 0.15

        // Vertex Displacement for Flames
        _FlameDisplacementMap("Flame Displacement Noise (Grayscale)", 2D) = "gray" {} // Noise for pushing vertices
        _FlameMaxHeight("Max Flame Height (Displacement)", Float) = 0.3
        _FlameDisplacementScale("Flame Disp. Noise Scale", Float) = 2.0
        _FlameDisplacementScrollY("Flame Disp. Noise Scroll Y", Float) = 0.4
        _FlameDispThreshold("Flame Disp. Threshold", Range(0,1)) = 0.5
        _FlameDispSmoothness("Flame Disp. Smoothness", Range(0.01, 0.5)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" }
        LOD 300 // Might need to adjust

        CGPROGRAM
        #pragma surface surf Standard vertex:vert alpha:blend fullforwardshadows
        #pragma target 3.5 // For tex2Dlod in vertex shader

        sampler2D _MainTex;
        sampler2D _NoiseTex;
        sampler2D _FlameAppearanceTex;
        sampler2D _FlameDisplacementMap;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldNormal;
            INTERNAL_DATA // Required for Fresnel when normals are modified by vert
            float3 viewDir;
            // Data from vertex shader
            half flamePresence; // 0 for magma, 1 for full flame (interpolated)
        };

        // Magma Core Properties
        half4 _Color;
        float _ScrollSpeedMainX, _ScrollSpeedMainY, _MagmaTexScale;
        float _ScrollSpeedNoiseX, _ScrollSpeedNoiseY, _NoiseTexScale;
        half _NoiseDistortion;
        half4 _EmissionColor;
        half _EmissionStrength, _EmissionNoiseInfluence;

        // Fresnel
        half4 _FresnelColor;
        half _FresnelPower;

        // Emitting Flames Visuals
        half4 _FireColor; // Renamed from _FlameColor in Properties to avoid conflict
        half _FireIntensity; // Renamed
        half _FireScrollSpeedY; // Renamed
        half _FireScale; // Renamed
        half _FireThreshold; // Renamed
        half _FireSmoothness; // Renamed

        // Flame Displacement
        float _FlameMaxHeight;
        float _FlameDisplacementScale;
        float _FlameDisplacementScrollY;
        float _FlameDispThreshold;
        float _FlameDispSmoothness;


        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);

            // Calculate UVs for displacement noise
            float2 dispUV = v.texcoord.xy * _FlameDisplacementScale;
            dispUV.y += _Time.y * _FlameDisplacementScrollY; // Animate displacement noise

            // Sample displacement noise (tex2Dlod needed for vertex texture fetch)
            half displacementNoiseVal = tex2Dlod(_FlameDisplacementMap, float4(dispUV, 0, 0)).r;

            // Determine flame presence for displacement and to pass to surface shader
            // This value (0-1) determines if/how much this vertex becomes part of a flame
            half flameDisplacementFactor = smoothstep(
                _FlameDispThreshold,
                _FlameDispThreshold + _FlameDispSmoothness,
                displacementNoiseVal
            );

            // Displace vertex along its normal if it's a flame part
            v.vertex.xyz += v.normal * flameDisplacementFactor * _FlameMaxHeight;

            // Pass the flame presence factor to the surface shader
            o.flamePresence = flameDisplacementFactor;
            
            // After modifying v.vertex, Unity's surface shader magic will recompute normals, etc.
            // for the Input struct before calling surf.
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // --- Magma Core Base (Always present, fades under flames) ---
            float2 flowNoiseUV = IN.uv_MainTex * _NoiseTexScale;
            flowNoiseUV.x += _Time.y * _ScrollSpeedNoiseX;
            flowNoiseUV.y += _Time.y * _ScrollSpeedNoiseY;
            half flowNoiseVal = tex2D(_NoiseTex, flowNoiseUV).r;

            float2 magmaUV = IN.uv_MainTex * _MagmaTexScale;
            magmaUV.x += (flowNoiseVal - 0.5) * _NoiseDistortion + (_Time.y * _ScrollSpeedMainX);
            magmaUV.y += (flowNoiseVal - 0.5) * _NoiseDistortion + (_Time.y * _ScrollSpeedMainY);
            half4 magmaTexCol = tex2D(_MainTex, magmaUV);

            half3 coreAlbedo = magmaTexCol.rgb * _Color.rgb;
            half coreAlpha = _Color.a * magmaTexCol.a; // Magma's base opacity
            half emissionNoiseFactor = lerp(1.0, flowNoiseVal, _EmissionNoiseInfluence);
            half3 coreEmission = _EmissionColor.rgb * _EmissionStrength * emissionNoiseFactor;

            // --- Fresnel Glow (Primarily for the core) ---
            half fresnel = 1.0 - saturate(dot(IN.worldNormal, normalize(IN.viewDir))); // worldNormal is from displaced surface
            fresnel = pow(fresnel, _FresnelPower);
            half3 fresnelEmission = _FresnelColor.rgb * fresnel * _EmissionStrength * (1.0 - IN.flamePresence); // Fade fresnel on flame parts

            // --- Emitting Flames (Appear on displaced parts) ---
            float2 flameVisualUV = IN.uv_MainTex * _FireScale;
            flameVisualUV.y += _Time.y * _FireScrollSpeedY; // Scroll visual flame texture
            // Optionally, distort flameVisualUV with another noise for more complex shapes
            // float2 flameDistortUV = IN.uv_MainTex * _NoiseTexScale * 0.7 + _Time.y * 0.1;
            // flameVisualUV.x += (tex2D(_NoiseTex, flameDistortUV).r - 0.5) * 0.2;

            half flameAppearanceNoise = tex2D(_FlameAppearanceTex, flameVisualUV).r;
            half flameAppearanceMask = smoothstep(_FireThreshold, _FireThreshold + _FireSmoothness, flameAppearanceNoise);
            
            // Combine vertex-driven flame presence with surface texture mask for final flame look
            half finalFlameMask = IN.flamePresence * flameAppearanceMask;

            half3 flameEmission = _FireColor.rgb * finalFlameMask * _FireIntensity;
            half flameAlpha = _FireColor.a * finalFlameMask; // Alpha for the flame parts

            // --- Combine Surface Properties ---
            // Lerp between magma and flame properties based on flamePresence from vertex shader.
            // When flamePresence is 1, it's mostly flame. When 0, it's magma.

            o.Albedo = lerp(coreAlbedo, float3(0,0,0), IN.flamePresence); // Flames have no albedo (purely emissive)
            o.Emission = lerp(coreEmission + fresnelEmission, float3(0,0,0), IN.flamePresence) + flameEmission;
            o.Metallic = 0.0;
            o.Smoothness = lerp(0.2, 0.05, IN.flamePresence); // Magma is a bit smooth, flames less so
            o.Alpha = lerp(coreAlpha, flameAlpha, IN.flamePresence); // Blend alpha from magma to flame
            
            // If you want flames to always be "on top" additively without affecting coreAlpha as much:
            // o.Albedo = coreAlbedo * (1.0 - finalFlameMask); // Carve out albedo where flames are strong
            // o.Emission = coreEmission + fresnelEmission + flameEmission;
            // o.Alpha = coreAlpha * (1.0 - finalFlameMask * 0.5) + flameAlpha; // More complex alpha logic
                                                                              // The lerp above is usually cleaner for a transition
        }
        ENDCG
    }
    FallBack "Transparent/Diffuse" // Fallback for transparent shaders
}