Shader "Unlit/Paint"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
                fixed4 col = tex2D(_MainTex, i.uv);

                pontoCSharp=mul(unity_WorldToObject, pontoCSharp);
                if(isPointInSphere(i.pos0, pontoCSharp.xyz, 1)){
                    return float4(1, 0, 0, 1);
                }
    
                return col;
            }
            ENDCG
        }
    }
}
