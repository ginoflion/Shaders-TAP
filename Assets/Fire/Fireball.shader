Shader "Custom/SolidMagmaBall_SurfaceFlames"
{
    Properties
    {
        _Color("Core Color", Color) = (1, 0.4, 0, 1)         // Laranja/Vermelho base
        _MainTex("Magma Texture (RGB)", 2D) = "white" {}     // Textura de fissuras/rocha (opcional)
        _NoiseTex("Flow Noise (Grayscale)", 2D) = "gray" {}  // Para distor��o e fluxo do magma

        _MagmaTexScale ("Magma Texture Scale", Float) = 1.5
        _ScrollSpeedMainX ("Magma Scroll X", Float) = 0.03
        _ScrollSpeedMainY ("Magma Scroll Y", Float) = 0.02
        
        _NoiseTexScale ("Flow Noise Scale", Float) = 2.0
        _ScrollSpeedNoiseX ("Flow Noise Scroll X", Float) = 0.07
        _ScrollSpeedNoiseY ("Flow Noise Scroll Y", Float) = -0.05
        _NoiseDistortion ("Flow Noise Distortion for Magma UVs", Range(0, 0.2)) = 0.08

        _EmissionColor("Emission Color", Color) = (1, 0.2, 0, 1) // Cor da emiss�o principal
        _EmissionStrength("Emission Strength", Range(0, 15)) = 3.0
        _EmissionNoiseInfluence("Emission Noise Influence", Range(0, 1)) = 0.6 // Ru�do afeta brilho da emiss�o

        _FresnelColor("Fresnel Glow Color", Color) = (1, 0.7, 0.1, 1)
        _FresnelPower("Fresnel Power", Range(0.1, 10)) = 4.0

        // Propriedades para "Chamas na Superf�cie"
        _SurfaceFlameTex("Surface Flame Noise (Grayscale)", 2D) = "gray" {} // Ru�do para as chamas na superf�cie
        _SurfaceFlameColor("Surface Flame Color", Color) = (1, 0.6, 0.0, 1) // Cor das chamas superficiais
        _SurfaceFlameIntensity("Surface Flame Intensity", Range(0, 10)) = 2.5
        _SurfaceFlameScrollSpeedY("Surface Flame Scroll Y", Float) = 0.3
        _SurfaceFlameScale("Surface Flame Texture Scale", Float) = 3.5
        _SurfaceFlameThreshold("Surface Flame Noise Threshold", Range(0, 1)) = 0.65 // Define o corte para as chamas
        _SurfaceFlameSmoothness("Surface Flame Edge Smoothness", Range(0.01, 0.5)) = 0.1 // Suavidade das bordas
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _NoiseTex;
        sampler2D _SurfaceFlameTex;

        struct Input
        {
            float2 uv_MainTex;
            // As outras texturas usar�o uv_MainTex como base para tiling/offset
            float3 worldNormal;
            float3 viewDir;
        };

        // Propriedades
        half4 _Color;
        float _MagmaTexScale, _ScrollSpeedMainX, _ScrollSpeedMainY;
        float _NoiseTexScale, _ScrollSpeedNoiseX, _ScrollSpeedNoiseY;
        half _NoiseDistortion;
        
        half4 _EmissionColor;
        half _EmissionStrength, _EmissionNoiseInfluence;

        half4 _FresnelColor;
        half _FresnelPower;

        half4 _SurfaceFlameColor;
        half _SurfaceFlameIntensity, _SurfaceFlameScrollSpeedY, _SurfaceFlameScale;
        half _SurfaceFlameThreshold, _SurfaceFlameSmoothness;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // --- 1. N�cleo de Magma ---
            // Scroll do ru�do de fluxo
            float2 scrolledNoiseUV = IN.uv_MainTex * _NoiseTexScale;
            scrolledNoiseUV.x += _Time.y * _ScrollSpeedNoiseX;
            scrolledNoiseUV.y += _Time.y * _ScrollSpeedNoiseY;
            half noiseVal = tex2D(_NoiseTex, scrolledNoiseUV).r;

            // Distorcer UVs da textura principal de magma com o ru�do de fluxo
            float2 distortedMainUV = IN.uv_MainTex * _MagmaTexScale;
            distortedMainUV.x += (noiseVal - 0.5) * _NoiseDistortion + (_Time.y * _ScrollSpeedMainX);
            distortedMainUV.y += (noiseVal - 0.5) * _NoiseDistortion + (_Time.y * _ScrollSpeedMainY);
            half4 mainTexCol = tex2D(_MainTex, distortedMainUV); // Se _MainTex for branca, cor base � _Color

            // Albedo base
            half3 albedo = mainTexCol.rgb * _Color.rgb; // Combina cor da textura com _Color

            // --- 2. Emiss�o do N�cleo (afetada pelo ru�do de fluxo) ---
            half emissionNoiseFactor = lerp(1.0, noiseVal, _EmissionNoiseInfluence); // 0.5 para que o ru�do possa escurecer e clarear
            half3 coreEmission = _EmissionColor.rgb * _EmissionStrength * emissionNoiseFactor;
            // Adicionar um pouco da cor do albedo � emiss�o para consist�ncia se desejar
            // coreEmission += albedo * 0.1 * _EmissionStrength;


            // --- 3. Brilho Fresnel nas Bordas ---
            half fresnel = 1.0 - saturate(dot(normalize(IN.worldNormal), normalize(IN.viewDir)));
            fresnel = pow(fresnel, _FresnelPower);
            half3 fresnelEmission = _FresnelColor.rgb * fresnel * _EmissionStrength; // Fresnel tamb�m escala com a for�a da emiss�o


            // --- 4. Chamas na Superf�cie (efeito de emiss�o adicional) ---
            float2 surfaceFlameUV = IN.uv_MainTex * _SurfaceFlameScale;
            surfaceFlameUV.y += _Time.y * _SurfaceFlameScrollSpeedY; // Chamas "sobem" na textura
            // Opcional: distorcer UVs das chamas superficiais com o ru�do de fluxo ou outro ru�do
            // surfaceFlameUV.x += (noiseVal - 0.5) * 0.1; // Pequena distor��o para formas mais org�nicas

            half surfaceFlameNoiseVal = tex2D(_SurfaceFlameTex, surfaceFlameUV).r;

            // Criar formas de chamas definidas a partir do ru�do
            half surfaceFlameMask = smoothstep(
                _SurfaceFlameThreshold,
                _SurfaceFlameThreshold + _SurfaceFlameSmoothness,
                surfaceFlameNoiseVal
            );
            
            half3 surfaceFlameEmission = _SurfaceFlameColor.rgb * surfaceFlameMask * _SurfaceFlameIntensity;

            // --- Combinar Tudo ---
            o.Albedo = albedo;
            // Adicionar todas as componentes emissivas
            o.Emission = coreEmission + fresnelEmission + surfaceFlameEmission;
            o.Metallic = 0.0;    // N�o met�lico
            o.Smoothness = 0.15; // Um pouco de suavidade para o magma
            o.Alpha = 1.0;       // S�lido
        }
        ENDCG
    }
    FallBack "Diffuse"
}