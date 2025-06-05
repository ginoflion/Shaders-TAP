Shader "Hidden/Wind"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogIntensity ("Fog Intensity", Range(0, 2)) = 0.6
        _FogSpeed ("Fog Speed", Range(0, 2)) = 0.5
    }
    SubShader
    {
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
            float _FogIntensity;
            float _FogSpeed;
            fixed4 _FogColor;
            
            float noise(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                _FogColor  = float4(0.8, 0.8, 0.85, 1);
                float time = _Time.y * _FogSpeed;
                float fog = noise(i.uv + time) * 0.5 + 0.3;
                
                col.rgb = lerp(col.rgb, _FogColor.rgb, fog * _FogIntensity);
                
                return col;
            }
            ENDCG
        }
    }
}
