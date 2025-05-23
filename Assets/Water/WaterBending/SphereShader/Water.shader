Shader "Unlit/KataraWaterBending_Bioluminescent_Fresnel"
{
        Properties
    {
        _MainTex("Water Texture", 2D) = "white" {}
        _FlowSpeed("Flow Speed", Float) = 2.0
        _WaveHeight("Wave Height", Float) = 0.3
        _Alpha("Transparency", Range(0,1)) = 0.7
        _WaterColor("Primary Water Color", Color) = (0.2, 0.5, 1.0, 1)
        _SecondaryColor("Secondary Glow Color", Color) = (0.0, 1.0, 0.8, 1)
        _GlowIntensity("Glow Intensity", Range(0, 5)) = 2.0
        _FresnelPower("Fresnel Power", Range(0.5, 10.0)) = 3.0
        _FresnelColor("Fresnel Glow Color", Color) = (0.0, 1.0, 1.0, 1.0)
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        ZWrite Off
        Blend One OneMinusSrcAlpha

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
            float4 _SecondaryColor;
            float _GlowIntensity;
            float _FresnelPower;
            float4 _FresnelColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 waveUV : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
            };

            v2f vert(appdata v)
            {
                v2f o;
                float t = _Time.y * _FlowSpeed;
                float3 pos = v.vertex.xyz;

                float wave = sin(pos.x * 4.0 + t) * _WaveHeight +
                             cos(pos.z * 3.0 + t * 1.5) * _WaveHeight * 0.7 +
                             sin(length(pos.xz) * 6.0 - t * 2.0) * _WaveHeight * 0.5;

                pos.y += wave;
                pos.x += sin(t + pos.y * 8.0) * 0.05;
                pos.z += cos(t * 1.2 + pos.y * 6.0) * 0.05;

                o.vertex = UnityObjectToClipPos(pos);
                o.uv = v.uv;
                o.waveUV = pos.xz;

                float3 worldPos = mul(unity_ObjectToWorld, float4(pos, 1.0)).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = _WorldSpaceCameraPos - worldPos;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float t = _Time.y * _FlowSpeed;

                float2 flow1 = i.uv + float2(sin(t * 1.2) * 0.15, t * 0.3);
                float2 flow2 = i.uv + float2(cos(t * 0.8) * 0.1, -t * 0.2);

                fixed4 waterTex = (tex2D(_MainTex, flow1) + tex2D(_MainTex, flow2)) * 0.5;

                float pulse = sin(t * 3.0 + i.waveUV.x + i.waveUV.y) * 0.5 + 0.5;
                float streaks = (sin(i.uv.y * 30.0 - t * 5.0) * 0.5 + 0.5) *
                                (cos(i.uv.x * 25.0 + t * 4.0) * 0.5 + 0.5) * 0.5;

                float glow = (pulse + streaks) * _GlowIntensity;

                fixed4 blendedColor = lerp(_WaterColor, _SecondaryColor, pulse);
                fixed4 col = blendedColor * waterTex;

                float3 N = normalize(i.worldNormal);
                float3 V = normalize(i.viewDir);
                float fresnel = pow(1.0 - saturate(dot(N, V)), _FresnelPower);
                col.rgb += fresnel * _FresnelColor.rgb * _GlowIntensity;
                col.rgb *= glow;
                col.a = _Alpha;

                return col;
            }
            ENDCG
        }
    }
}
