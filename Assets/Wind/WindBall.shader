Shader "Unlit/WindBall"
{
    Properties
        {
            _CoreColor ("Core Color", Color) = (1.0, 1.0, 1.0, 0.5)
            _OuterColor ("Outer Color", Color) = (1.0, 1.0, 1.0, 0.5)
            _Speed ("Speed", Range(1.0, 10.0)) = 5.0
        }
        
        SubShader
        {
            Tags { "RenderType"="Transparent" "Queue"="Transparent" }
            LOD 100
            
            
            Pass
            {
                ZWrite Off
                Blend SrcAlpha OneMinusSrcAlpha
                Cull Off
                
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
                
                fixed4 _CoreColor;
                float _Speed;
                
                v2f vert (appdata v)
                {
                    v2f o;
                    float3 pos = v.vertex.xyz*0.4;
                    
                    
                    float angle = -_Time.y * _Speed + pos.y * 6.0;



                    float s = sin(angle), c = cos(angle);
                    pos.xz = float2(pos.x * c - pos.z * s, pos.x * s + pos.z * c);
                    



                    o.vertex = UnityObjectToClipPos(pos);
                    o.uv = v.uv;
                    return o;
                }
                
                fixed4 frag (v2f i) : SV_Target
                {
                    float2 uv = i.uv - 0.5;
                    float dist = length(uv);
                    float angle = atan2(uv.y, uv.x);
                    
                    
                    float spiral = sin(angle * 4.0 + dist * 15.0 + _Time.y * _Speed * 3.0) * 0.5 + 0.5;
                    float fade = 1.0 - smoothstep(0.3, 0.5, dist);
                    
                    return fixed4(_CoreColor.rgb, spiral * fade * 0.5);
                }
                ENDCG
            }
            
            
            Pass
            {
                ZWrite Off
                Blend SrcAlpha OneMinusSrcAlpha
                Cull Off
                
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
                
                fixed4 _OuterColor;
                float _Speed;
                
                v2f vert (appdata v)
                {
                    v2f o;
                    float3 pos = v.vertex.xyz;
                    
                    
                    float angle = _Time.y * _Speed + pos.y * 6.0;
                    float s = sin(angle), c = cos(angle);
                    pos.xz = float2(pos.x * c - pos.z * s, pos.x * s + pos.z * c);
                    
                    o.vertex = UnityObjectToClipPos(pos);
                    o.uv = v.uv;
                    return o;
                }
                
                fixed4 frag (v2f i) : SV_Target
                {
                    float2 uv = i.uv - 0.5;
                    float dist = length(uv);
                    float angle = atan2(uv.y, uv.x);
                    
                    
                    float spiral = sin(angle * 4.0 + dist * 15.0 + _Time.y * _Speed * 3.0) * 0.5 + 0.5;
                    float fade = 1.0 - smoothstep(0.3, 0.5, dist);
                    
                    return fixed4(_OuterColor.rgb, spiral * fade * 0.5);
                }
                ENDCG
            }
        }

}
