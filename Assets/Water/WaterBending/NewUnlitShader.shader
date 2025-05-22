Shader "Unlit/NewUnlitShader"
{
   Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _Color ("Blade Color", Color) = (0.7, 0.9, 1.0, 0.8)
        _EdgeColor ("Edge Color", Color) = (0.9, 1.0, 1.0, 1.0)
        _BladeWidth ("Blade Width", Range(0.1, 2.0)) = 1.0
        _BladeSharpness ("Blade Sharpness", Range(1.0, 10.0)) = 3.0
        _WindSpeed ("Wind Speed", Range(0.1, 5.0)) = 2.0
        _WindStrength ("Wind Strength", Range(0.0, 1.0)) = 0.5
        _Distortion ("Distortion", Range(0.0, 1.0)) = 0.3
        _Alpha ("Alpha", Range(0.0, 1.0)) = 0.8
        _EdgeGlow ("Edge Glow", Range(0.0, 3.0)) = 1.5
        _Speed ("Animation Speed", Range(0.1, 10.0)) = 3.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200
        
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off
        
        CGPROGRAM
        #pragma surface surf Standard alpha:fade vertex:vert
        #pragma target 3.0
        
        sampler2D _MainTex;
        sampler2D _NoiseTex;
        fixed4 _Color;
        fixed4 _EdgeColor;
        float _BladeWidth;
        float _BladeSharpness;
        float _WindSpeed;
        float _WindStrength;
        float _Distortion;
        float _Alpha;
        float _EdgeGlow;
        float _Speed;
        
        struct Input
        {
            float2 uv_MainTex;
            float2 uv_NoiseTex;
            float3 worldPos;
            float4 screenPos;
        };
        
        void vert(inout appdata_full v)
        {
            // Adicionar movimento de vento aos vértices
            float time = _Time.y * _Speed;
            float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            
            // Noise para movimento orgânico
            float noise = sin(worldPos.x * 2.0 + time) * cos(worldPos.z * 1.5 + time * 0.7);
            float windOffset = noise * _WindStrength * 0.1;
            
            v.vertex.xyz += v.normal * windOffset;
        }
        
        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float time = _Time.y * _Speed;
            
            // Calcular distância do centro da lâmina (eixo Y como altura da lâmina)
            float distanceFromCenter = abs(IN.uv_MainTex.x - 0.5) * 2.0;
            
            // Criar forma da lâmina com falloff suave
            float bladeShape = 1.0 - pow(distanceFromCenter / _BladeWidth, _BladeSharpness);
            bladeShape = saturate(bladeShape);
            
            // Noise para distorção da lâmina
            float2 noiseUV = IN.uv_NoiseTex + float2(time * 0.1, time * 0.05);
            float noise = tex2D(_NoiseTex, noiseUV).r;
            float distortedShape = bladeShape + (noise - 0.5) * _Distortion * bladeShape;
            distortedShape = saturate(distortedShape);
            
            // Criar efeito de borda brilhante
            float edgeGradient = 1.0 - distanceFromCenter;
            float edgeIntensity = pow(edgeGradient, 3.0) * _EdgeGlow;
            
            // Animação de energia ao longo da lâmina
            float energyWave = sin(IN.uv_MainTex.y * 10.0 + time * 2.0) * 0.5 + 0.5;
            energyWave *= sin(IN.uv_MainTex.y * 3.0 - time * 1.5) * 0.5 + 0.5;
            
            // Combinar cores
            fixed4 bladeColor = lerp(_Color, _EdgeColor, edgeIntensity);
            bladeColor.rgb += energyWave * 0.3;
            
            // Aplicar textura principal
            fixed4 mainTex = tex2D(_MainTex, IN.uv_MainTex);
            bladeColor *= mainTex;
            
            // Output
            o.Albedo = bladeColor.rgb;
            o.Alpha = distortedShape * _Alpha * bladeColor.a;
            o.Emission = bladeColor.rgb * edgeIntensity * 0.5;
            o.Smoothness = 0.9;
            o.Metallic = 0.1;
        }
        ENDCG
    }
    
    Fallback "Transparent/Diffuse"
}
