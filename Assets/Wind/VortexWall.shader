Shader "Unlit/VortexWall"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Radius ("Radius", Range(0, 15)) = 0.2
        _Impact("Impact", Float) = 0.5
        _TwistAmount ("Twist Amount", Float) = 1.5
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
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _PontoEmbateArray[1024];

            float _Radius;
            float _Impact;
            float _TwistAmount;

            v2f vert (appdata v)
            {
                v2f o;
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                
                for (int i = 0; i < 1024; i++)
                {
                    float4 ponto = _PontoEmbateArray[i];
                    if (ponto.w > 0.0)
                    {
                        float3 delta = worldPos - ponto.xyz;
                        float dist = length(delta);
                        
                        if (dist <= _Radius)
                        {
                            float t = saturate(1.0 - dist / _Radius);
                            
                            worldPos -= worldNormal * _Impact * t * ponto.w;
                            
                            float angle = _TwistAmount * t * ponto.w;
                            float sinA = sin(angle);
                            float cosA = cos(angle);
                            
                            float3 localDelta = delta;
                            float rotatedX = localDelta.x * cosA - localDelta.z * sinA;
                            float rotatedZ = localDelta.x * sinA + localDelta.z * cosA;
                            
                            float3 twistedOffset = float3(rotatedX, localDelta.y, rotatedZ) - localDelta;
                            worldPos += twistedOffset * t * ponto.w;
                        }
                    }
                }
                
                float4 localPos = mul(unity_WorldToObject, float4(worldPos, 1.0));
                
                o.vertex = UnityObjectToClipPos(localPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
}