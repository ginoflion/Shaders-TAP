Shader "Hidden/GalacticWaterOrbEffect"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _ChromaticAmount ("Chromatic Aberration", Range(0, 2)) = 0.5
        _DistortionStrength ("Wave Distortion", Range(0, 0.05)) = 0.015
        _GlowColor ("Glow Color", Color) = (0.6, 0.3, 1.0, 1)
        _PulseSpeed ("Pulse Speed", Float) = 2.5
        _GlowIntensity ("Glow Intensity", Range(0, 2)) = 1.2
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Overlay" }

        Pass
        {
            ZTest Always Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _GlowColor;
            float _ChromaticAmount;
            float _DistortionStrength;
            float _PulseSpeed;
            float _GlowIntensity;

            float4 frag(v2f_img i) : SV_Target
            {
                float2 uv = i.uv;
                float time = _Time.y;

                // ✧ Spacey wave distortion
                float2 offset = float2(
                    sin(uv.y * 30.0 + time * 2.0),
                    cos(uv.x * 20.0 + time * 1.5)
                ) * _DistortionStrength;

                float2 distortedUV = uv + offset;

                // ✧ Chromatic aberration (separate R, G, B channels)
                float2 chroma = (uv - 0.5) * _ChromaticAmount;

                float r = tex2D(_MainTex, distortedUV + chroma * 0.5).r;
                float g = tex2D(_MainTex, distortedUV).g;
                float b = tex2D(_MainTex, distortedUV - chroma * 0.5).b;

                float3 color = float3(r, g, b);

                // ✧ Pulsing glow based on radial distance
                float2 centeredUV = uv * 2.0 - 1.0;
                float dist = length(centeredUV);
                float pulse = sin(time * _PulseSpeed + dist * 10.0) * 0.5 + 0.5;

                float glow = (1.0 - dist) * pulse * _GlowIntensity;
                float3 finalColor = color + _GlowColor.rgb * glow;

                return float4(finalColor, 1.0);
            }
            ENDCG
        }
    }
    FallBack Off
}
