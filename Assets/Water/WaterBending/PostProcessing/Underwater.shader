Shader "Hidden/SimpleUnderwater"
{
    Properties
    {
        _MainTex ("Base", 2D) = "white" {}
        _WaterColor ("Water Tint", Color) = (0.2, 0.6, 1.0, 1.0)
        _WaveAmount ("Wave Amount", Range(0.0, 0.01)) = 0.005
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
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            sampler2D _MainTex;
            fixed4 _WaterColor;
            float _WaveAmount;
            
            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                // Simple wave distortion
                float2 wave = float2(
                    sin(i.uv.y * 15.0 + _Time.y * 2.0),
                    cos(i.uv.x * 12.0 + _Time.y * 1.5)
                ) * _WaveAmount;
                
                // Sample with wave offset
                fixed4 col = tex2D(_MainTex, i.uv + wave);
                
                // Apply water tint
                col.rgb *= _WaterColor.rgb;
                
                return col;
            }
            ENDCG
        }
    }
}