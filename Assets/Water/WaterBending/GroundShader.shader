Shader "Custom/GroundShader"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _SpillTex ("Spill (RGB)", 2D) = "white" {}
        _SpillMask ("Spill Mask ", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadow
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _SpillTex;
        sampler2D _SpillMask;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 uv = IN.uv_MainTex;

            // Sample base texture and tint
            fixed4 baseCol = tex2D(_MainTex, uv);

            // Sample spill and mask
            fixed4 spillCol = tex2D(_SpillTex, uv);
            float mask = tex2D(_SpillMask, uv).r;

            // Blend based on mask
            fixed4 blended = lerp(baseCol, spillCol, mask);

            o.Albedo = blended.rgb;
            o.Alpha = blended.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
