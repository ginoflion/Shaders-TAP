Shader "Unlit/KataraWaterBending_Bioluminescent"
{
    Properties
    {
        _MainTex("Water Texture", 2D) = "white" {}
        _FlowSpeed("Flow Speed", Float) = 2.0
        _WaveHeight("Wave Height", Float) = 0.3
        _Alpha("Transparency", Range(0,1)) = 0.7
        _WaterColor("Water Color", Color) = (0.2, 0.5, 1.0, 1)
        _GlowIntensity("Glow Intensity", Range(0, 5)) = 2.0
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        ZWrite Off
        Blend One One  // Use additive blending for glowing look

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float _FlowSpeed;
            float _WaveHeight;
            float _Alpha;
            float4 _WaterColor;
            float _GlowIntensity;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                float time = _Time.y * _FlowSpeed;

                float3 pos = v.vertex.xyz;

                float wave1 = sin(pos.x * 4.0 + time) * _WaveHeight;
                float wave2 = cos(pos.z * 3.0 + time * 1.5) * _WaveHeight * 0.7;
                float spiral = sin(length(pos.xz) * 6.0 - time * 2.0) * _WaveHeight * 0.5;

                pos.y += wave1 + wave2 + spiral;
                pos.x += sin(time + pos.y * 8.0) * 0.05;
                pos.z += cos(time * 1.2 + pos.y * 6.0) * 0.05;

                o.vertex = UnityObjectToClipPos(pos);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, pos).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float time = _Time.y * _FlowSpeed;

                float2 flow1 = i.uv + float2(sin(time * 1.2) * 0.15, time * 0.3);
                float2 flow2 = i.uv + float2(cos(time * 0.8) * 0.1, -time * 0.2);

                fixed4 waterTex1 = tex2D(_MainTex, flow1);
                fixed4 waterTex2 = tex2D(_MainTex, flow2);
                fixed4 waterTex = (waterTex1 + waterTex2) * 0.5;

                // Combine with water color
                fixed4 col = _WaterColor * waterTex;

                // Bioluminescent pulse
                float pulse = sin(time * 3.0 + i.worldPos.x + i.worldPos.z) * 0.5 + 0.5;

                // Glowing streaks for added detail
                float streak1 = sin(i.uv.y * 30.0 - time * 5.0) * 0.5 + 0.5;
                float streak2 = cos(i.uv.x * 25.0 + time * 4.0) * 0.5 + 0.5;
                float streaks = (streak1 * streak2) * 0.5;

                // Total emission effect
                float glow = (pulse + streaks) * _GlowIntensity;

                col.rgb *= glow;
                col.a = _Alpha;

                return col;
            }
            ENDCG
        }
    }
}
