Shader "PostProcessing/ScreenEdgeFlames_MaterialEditable" // Nome alterado para fácil seleção
{
    Properties
    {
        // --- Screen Texture (Internal) ---
        _MainTex ("Texture (Assigned by Post-Process)", 2D) = "white" {}

        // --- Edge Flames ---
        _NoiseTex ("Flame Noise Texture (Grayscale)", 2D) = "gray" {}
        _FlameColor1 ("Flame Hot Color", Color) = (1, 0.8, 0.2, 1)
        _FlameColor2 ("Flame Cool Color", Color) = (0.8, 0.2, 0, 1)
        _EdgeSoftness ("Flame Edge Softness", Range(0.01, 0.5)) = 0.15
        _FlameIntensity ("Flame Intensity", Range(0, 2)) = 1.0
        _NoiseScale ("Flame Noise Scale", Float) = 10.0
        _NoiseSpeedX ("Flame Noise Scroll Speed X", Float) = 0.1
        _NoiseSpeedY ("Flame Noise Scroll Speed Y (Upwards)", Float) = 0.5
        _DistortionAmount ("Flame Edge Distortion", Range(0, 0.1)) = 0.03
        _FlameShapeBias("Flame Shape Bias (Higher = thinner flames)", Range(0.1, 2.0)) = 0.8

        // --- Screen Tint & Gradient ---
        _OverallTint ("Overall Tint Color (A for Strength)", Color) = (1,1,1,0) // Default: White, 0 Alpha (no tint)
        _GradientColorTop ("Gradient Top Color (A for Opacity)", Color) = (0,0,0,0) // Default: Transparent Black
        _GradientColorBottom ("Gradient Bottom Color (A for Opacity)", Color) = (0,0,0,0) // Default: Transparent Black
        _GradientIntensity ("Gradient Overall Intensity", Range(0,1)) = 0.0 // Default: No gradient
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"

            // Samplers
            sampler2D _MainTex;
            sampler2D _NoiseTex;

            // Flame Properties
            fixed4 _FlameColor1;
            fixed4 _FlameColor2;
            float _EdgeSoftness;
            float _FlameIntensity;
            float _NoiseScale;
            float _NoiseSpeedX;
            float _NoiseSpeedY;
            float _DistortionAmount;
            float _FlameShapeBias;

            // Tint & Gradient Properties
            fixed4 _OverallTint;
            fixed4 _GradientColorTop;
            fixed4 _GradientColorBottom;
            float _GradientIntensity;


            float simple_noise(float2 p)
            {
                float K1 = 0.03125;
                p = p * K1;
                return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
            }

            fixed4 frag (v2f_img i) : SV_Target
            {
                fixed4 originalSceneColor = tex2D(_MainTex, i.uv);
                fixed3 currentResult = originalSceneColor.rgb; // Começa com a cor da cena

                // --- 1. Edge Flames (se aplicável) ---
                float2 distanceFromCenter = abs(i.uv - 0.5) * 2.0;
                float edgeProximity = max(distanceFromCenter.x, distanceFromCenter.y);
                float edgeStart = 1.0 - _EdgeSoftness * 2.0;
                float edgeEnd = 1.0;
                float edgeMask = smoothstep(edgeStart, edgeEnd, edgeProximity);
                edgeMask = pow(edgeMask, 1.5);

                if (edgeMask > 0.001) // Só calcula chamas se estivermos na área da borda
                {
                    float2 noiseUV = i.uv * _NoiseScale;
                    noiseUV.x += _Time.y * _NoiseSpeedX;
                    noiseUV.y += _Time.y * _NoiseSpeedY;

                    float noiseValTex = tex2D(_NoiseTex, noiseUV).r;
                    float2 distortedNoiseUV = noiseUV;
                    distortedNoiseUV.y += (1.0-edgeProximity) * 0.5;
                    float noiseValProc = simple_noise(distortedNoiseUV * float2(1.5, 0.8));

                    float combinedNoise = noiseValTex * 0.6 + noiseValProc * 0.4;
                    combinedNoise = pow(combinedNoise, _FlameShapeBias);
                    
                    float2 distortionOffsetUV = i.uv * _NoiseScale * 0.7 + float2(_Time.x * 0.1, _Time.y * 0.2);
                    float distortionNoiseVal = (tex2D(_NoiseTex, distortionOffsetUV).r - 0.5) * _DistortionAmount * edgeMask;
                    
                    float flameShape = smoothstep(0.45 - distortionNoiseVal, 0.55 + distortionNoiseVal, combinedNoise);
                    flameShape *= edgeMask;

                    float colorLerpFactor = smoothstep(0.3, 0.7, combinedNoise);
                    fixed3 flameColor = lerp(_FlameColor2.rgb, _FlameColor1.rgb, colorLerpFactor);
                    
                    // Mistura as chamas com a cor da cena original
                    currentResult = lerp(originalSceneColor.rgb, flameColor, flameShape * _FlameIntensity * _FlameColor1.a);
                }

                // --- 2. Gradient Overlay ---
                if (_GradientIntensity > 0.001) // Só aplica se houver intensidade
                {
                    float gradientLerpFactor = i.uv.y; // Gradiente vertical simples (0 na base, 1 no topo)
                    // Interpola as cores do gradiente E seus alfas
                    fixed4 finalGradientColor = lerp(_GradientColorBottom, _GradientColorTop, gradientLerpFactor);
                    
                    // Mistura o gradiente sobre o resultado atual (pós-chamas)
                    // A força da mistura é controlada pelo alfa interpolado do gradiente E pela intensidade geral do gradiente
                    currentResult = lerp(currentResult, finalGradientColor.rgb, finalGradientColor.a * _GradientIntensity);
                }

                // --- 3. Overall Tint ---
                if (_OverallTint.a > 0.001) // Só aplica se o alfa do tint (força) for significativo
                {
                    // Mistura o resultado atual em direção a uma versão tingida dele mesmo.
                    // O _OverallTint.rgb é a cor do tint.
                    // O _OverallTint.a é a força da mistura.
                    currentResult = lerp(currentResult, currentResult * _OverallTint.rgb, _OverallTint.a);
                }
                
                return fixed4(currentResult, originalSceneColor.a); // Mantém o alfa original da cena
            }
            ENDCG
        }
    }
    Fallback Off
}