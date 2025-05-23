Shader "Custom/PollutedWater"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (0.2, 0.4, 0.3, 1)
        _PollutionTex ("Pollution Texture", 2D) = "white" {}
        _NoiseTex ("Distortion Noise", 2D) = "white" {}
        _Distortion ("Distortion Strength", Range(0, 1)) = 0.1
        _Speed ("Flow Speed", Range(0.1, 5)) = 1
        _WaveStrength ("Vertex Wave Strength", Range(0, 1)) = 0.05
        _WaveFreq ("Vertex Wave Frequency", Range(0.1, 10)) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _NoiseTex;
            sampler2D _PollutionTex;
            float4 _MainColor;
            float _Distortion;
            float _Speed;
            float _WaveStrength;
            float _WaveFreq;

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
            };

            v2f vert (appdata v)
            {
                v2f o;

                float wave = sin(_Time.y * _WaveFreq + v.vertex.x * 2.0 + v.vertex.y * 2.0) * _WaveStrength;
                float3 offset = v.normal * wave;
                float4 displaced = v.vertex + float4(offset, 0);

                o.vertex = UnityObjectToClipPos(displaced);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 flowUV = i.uv + float2(_Time.y * _Speed * 0.05, _Time.y * _Speed * 0.03);
                float noise = tex2D(_NoiseTex, flowUV).r;

                float2 distortedUV = i.uv + (_Distortion * (noise - 0.5));

                fixed4 pollutionColor = tex2D(_PollutionTex, distortedUV * 2.0);

                fixed4 color = lerp(_MainColor, pollutionColor, 0.6);

                color.a = 0.7;
                return color;
            }
            ENDCG
        }
    }
}
