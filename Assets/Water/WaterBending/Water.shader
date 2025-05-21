Shader "Unlit/Water"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _NoiseTex("Noise", 2D) = "white" {} // for UV distortion
        _Speed("Flow Speed", Float) = 1.0
        _DistortionStrength("Distortion Strength", Float) = 0.05
        _WaveHeight("Wave Height", Float) = 0.1
        _WaveFrequency("Wave Frequency", Float) = 5.0
        _Alpha("Alpha", Range(0,1)) = 0.4
        _FresnelColor("Fresnel Color", Color) = (0.3, 0.6, 1.0, 1)
        _FresnelPower("Fresnel Power", Float) = 5.0
        _ColorTint("Tint Color", Color) = (0.5, 0.8, 1.0, 1)
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200
        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _NoiseTex;
            float4 _MainTex_ST;
            float _Speed;
            float _DistortionStrength;
            float _WaveHeight;
            float _WaveFrequency;
            float _Alpha;
            float4 _FresnelColor;
            float _FresnelPower;
            float4 _ColorTint;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float time = _Time.y * _Speed;

                float3 pos = v.vertex.xyz;
                pos.y += sin((pos.x + pos.z) * _WaveFrequency + time) * _WaveHeight;

                o.vertex = UnityObjectToClipPos(float4(pos, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldViewDir = normalize(_WorldSpaceCameraPos - worldPos);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = _Time.y * _Speed;

                // UV distortion using noise texture
                float2 noiseUV = i.uv * 3.0 + time;
                float2 noise = tex2D(_NoiseTex, noiseUV).rg;
                float2 distortedUV = i.uv + (noise - 0.5) * _DistortionStrength;

                fixed4 col = tex2D(_MainTex, distortedUV);
                col.rgb *= _ColorTint.rgb;

                // Fresnel effect
                float fresnel = pow(1.0 - saturate(dot(i.worldNormal, i.worldViewDir)), _FresnelPower);
                float3 fresnelColor = _FresnelColor.rgb * fresnel;

                col.rgb += fresnelColor;
                col.a = _Alpha * col.a;

                return col;
            }
            ENDCG
        }
    }
    FallBack "Unlit/Transparent"
}
