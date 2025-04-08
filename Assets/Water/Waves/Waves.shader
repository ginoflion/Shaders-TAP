Shader "Unlit/WaterBendingFoil"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _FoilTex ("Foil Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _Speed ("Flow Speed", Float) = 1.0
        _WaveHeight ("Wave Height", Float) = 0.1
        _WaveFrequency ("Wave Frequency", Float) = 5.0
        _Distortion ("Wave Distortion", Float) = 0.05
        _NoiseStrength ("Noise Strength", Float) = 1.0
        _Alpha ("Alpha", Range(0, 1)) = 0.4
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _FoilTex;
            sampler2D _NoiseTex;
            float4 _MainTex_ST;
            float4 _FoilTex_ST;
            float4 _NoiseTex_ST;
            float _Speed;
            float _WaveHeight;
            float _WaveFrequency;
            float _Distortion;
            float _NoiseStrength;
            float _Alpha;

            v2f vert (appdata v)
            {
                v2f o;
                float time = _Time.y * _Speed;

                float3 pos = v.vertex.xyz;

                float waveX = sin(pos.x * _WaveFrequency + time);
                float waveZ = cos(pos.z * _WaveFrequency * 0.5 + time * 1.2);

                pos.y += (waveX + waveZ) * _WaveHeight;
                pos.x += sin(pos.z * _WaveFrequency * 0.7 + time * 1.5) * _Distortion;
                pos.z += cos(pos.x * _WaveFrequency * 0.6 + time * 1.3) * _Distortion;

                o.vertex = UnityObjectToClipPos(float4(pos, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = _Time.y * _Speed;

                // Base color (black texture)
                fixed4 baseCol = tex2D(_MainTex, i.uv);

                // Noise value
                float2 noiseUV = i.uv + float2(time * 0.05, time * 0.03); // slight motion
                float noise = tex2D(_NoiseTex, TRANSFORM_TEX(noiseUV, _NoiseTex)).r;

                // Use noise to distort foil UVs
                float2 foilUV = i.uv + (noise - 0.5) * _NoiseStrength;
                fixed4 foilCol = tex2D(_FoilTex, TRANSFORM_TEX(foilUV, _FoilTex));

                // Combine: Foil on top of black base using alpha
                fixed4 final = lerp(baseCol, foilCol, noise);
                final.a = _Alpha;

                return final;
            }
            ENDCG
        }
    }
}
