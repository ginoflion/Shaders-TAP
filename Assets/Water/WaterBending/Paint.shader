Shader "Unlit/Paint"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DirtTex ("Dirt Texture", 2D) = "black" {}
        _Noise ("Dirt Noise", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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
                float4 pos0 : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            bool isPointInSphere(float3 ponto, float3 center, float radius)
            {
                float squaredDistance = dot(ponto - center, ponto - center);
                
                return squaredDistance <= radius * radius;
            }

            sampler2D _Noise;
            sampler2D _DirtTex;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos0 = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            float4 pontoCSharp = float4(0, 0, 0, 1);

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 dirt = tex2D(_DirtTex, i.uv);
                fixed4 noise = tex2D(_Noise, i.uv);
                fixed4 clean = tex2D(_MainTex, i.uv);

                pontoCSharp=mul(unity_WorldToObject, pontoCSharp);
                if(isPointInSphere(i.pos0, pontoCSharp.xyz, 1)){
                    float mix = noise.r + noise.g + noise.b;
                    fixed4 color = lerp(clean, dirt, mix);
                    return color;
                }
                
    
                return dirt;
            }
            ENDCG
        }
    }
}
