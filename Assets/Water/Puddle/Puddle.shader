Shader "Custom/Puddle"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _WetMask ("Puddle Mask", 2D) = "black" {} 
        _Glossiness ("Smoothness", Range(0, 1)) = 1
        _Darken ("Darken Amount", Range(0, 1)) = 0.4
        _Metallic ("Metallic", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows

        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _WetMask;
        float _Glossiness;
        float _Darken;
        float _Metallic;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_WetMask;
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float mask = tex2D(_WetMask, IN.uv_WetMask).r;

            // Soften the mask towards the edges
            float wet = saturate(pow(mask, 2.5)); // Increase exponent to soften more

            fixed4 col = tex2D (_MainTex, IN.uv_MainTex);

            // Apply the darkening effect only where the mask is stronger (center)
            col.rgb = lerp(col.rgb, col.rgb * (1 - _Darken), wet);

            o.Albedo = col.rgb;
            o.Smoothness = lerp(0.2, _Glossiness, wet);
            o.Metallic = lerp(0.0, _Metallic, wet);
        }

        ENDCG
    }
    FallBack "Diffuse"
}
