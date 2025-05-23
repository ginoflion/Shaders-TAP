Shader "Hidden/StigmatismShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Slider ("Alcool", Range(0, 1)) = 0.5
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            float _Slider;

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uvE= i.uv;
                float2 uvD = i.uv;

                float2 uvC= i.uv;
                float2 uvB = i.uv;

                uvE.x += _Slider;
                uvD.x -= _Slider;

                uvC.y += _Slider;
                uvB.y -= _Slider;

                fixed4 col = tex2D(_MainTex, i.uv)*2;
                fixed4 col2 = tex2D(_MainTex, uvE)/2; 
                fixed4 col3 = tex2D(_MainTex, uvD)/2;
                fixed4 col4 = tex2D(_MainTex, uvC)/2;
                fixed4 col5 = tex2D(_MainTex, uvB)/2;
                // just invert the colors
                return (col + col2 + col3+ col4 +col5) / 5;
            }
            ENDCG
        }
    }
}
