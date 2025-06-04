Shader "Custom/Floor_Unlit"
{
    Properties
    {
        _GrassTex("Grass Texture (RGB)", 2D) = "white" {}

        _MagmaTex("Magma Texture (RGB)", 2D) = "white" {}
        _MagmaTex_UVScale("Magma Texture UV Scale", Float) = 1.0
        _MagmaEmission("Magma Emission Strength", Range(0, 5)) = 1.0
        _MagmaEffectTransition("Magma Effect Transition Softness", Range(0.01, 2.0)) = 0.5
        _MagmaDentDepth("Magma Dent Depth", Range(0.0,2.0)) = 0.1
        _MagmaDentFalloff("Magma Dent Falloff", Range(0.01, 2.0)) = 1.0
        _MagmaTrailWidth("Magma Trail Width", Range(0.01, 2.0)) = 0.1

        _WindTex("Wind Texture (RGB)", 2D) = "white" {}
        _WindTex_UVScale("Wind Texture UV Scale", Float) = 1.0
        _WindEmission("Wind Emission Strength", Range(0, 5)) = 1.0
        _WindEffectTransition("Magma Effect Transition Softness", Range(0.01, 2.0)) = 0.5
        _WindDentDepth("Magma Dent Depth", Range(0.0,2.0)) = 0.1
        _WindDentFalloff("Magma Dent Falloff", Range(0.01, 2.0)) = 1.0
        _WindTrailWidth("Magma Trail Width", Range(0.01, 2.0)) = 0.1

        _WaterTex("Water Texture (RGB)", 2D) = "white" {}
        _WaterTex_UVScale("Water Texture UV Scale", Float) = 1.0
        _WaterEmission("Water Emission Strength", Range(0, 5)) = 1.0
        _WaterEffectTransition("Water Effect Transition Softness", Range(0.01, 2.0)) = 0.5
        _WaterDentDepth("Magma Dent Depth", Range(0.0,2.0)) = 0.1
        _WaterDentFalloff("Magma Dent Falloff", Range(0.01, 2.0)) = 1.0
        _WaterTrailWidth("Magma Trail Width", Range(0.01, 2.0)) = 0.1

        _BulletType("Bullet Type", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _GrassTex;

            sampler2D _MagmaTex;
            float _MagmaTex_UVScale;
            float _MagmaEmission;
            float _MagmaEffectTransition;
            float _MagmaDentDepth;
            float _MagmaDentFalloff;
            float _MagmaTrailWidth;

            sampler2D _WindTex;
            float _WindTex_UVScale;
            float _WindEmission;
            float _WindEffectTransition;
            float _WindDentDepth;
            float _WindDentFalloff;
            float _WindTrailWidth;

            sampler2D _WaterTex;
            float _WaterTex_UVScale;
            float _WaterEmission;
            float _WaterEffectTransition;
            float _WaterDentDepth;
            float _WaterDentFalloff;
            float _WaterTrailWidth;

            float _BulletType;
            float4 _BallPositionWS;
            float4 _TrailOriginWS;
            float _TrailEffectActive;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float influence : TEXCOORD1;
            };

            float DistancePointToLineSegment(float3 p, float3 a, float3 b, out float3 closestPoint)
            {
                float3 ab = b - a;
                float3 ap = p - a;
                float t = dot(ap, ab) / dot(ab, ab);
                t = saturate(t);
                closestPoint = a + t * ab;
                return distance(p, closestPoint);
            }

            v2f vert(appdata v)
            {
                v2f o;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                float dentDepth = 0;
                float dentFalloff = 1;
                float trailWidth = 0.1;
                float effectTransition = 0.5;

                if (_BulletType == 0)
                {
                    dentDepth = _MagmaDentDepth;
                    dentFalloff = _MagmaDentFalloff;
                    trailWidth = _MagmaTrailWidth;
                    effectTransition = _MagmaEffectTransition;
                }
                else if (_BulletType == 1)
                {
                    dentDepth = _WaterDentDepth;
                    dentFalloff = _WaterDentFalloff;
                    trailWidth = _WaterTrailWidth;
                    effectTransition = _WaterEffectTransition;
                }
                else
                {
                    dentDepth = _WindDentDepth;
                    dentFalloff = _WindDentFalloff;
                    trailWidth = _WindTrailWidth;
                    effectTransition = _WindEffectTransition;
                }

                float influence = 0;
                float3 closest;
                if (_TrailEffectActive > 0.5)
                {
                    float dist = DistancePointToLineSegment(worldPos, _TrailOriginWS.xyz, _BallPositionWS.xyz, closest);

                    float dentFactor = pow(saturate(1.0 - dist / trailWidth), dentFalloff);
                    float inner = max(0.0, trailWidth - effectTransition * 0.5);
                    float outer = trailWidth + effectTransition * 0.5;

                    influence = 1.0 - smoothstep(inner, outer, dist);
                    v.vertex.xyz += v.normal * dentFactor * -dentDepth;
                }

                o.uv = v.uv;
                o.influence = influence;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 grass = tex2D(_GrassTex, i.uv);
                fixed3 effectColor = 0;
                float uvScale = 1;
                float emission = 0;

                if (_BulletType == 0)
                {
                    effectColor = tex2D(_MagmaTex, i.uv * _MagmaTex_UVScale).rgb;
                    emission = _MagmaEmission;
                }
                else if (_BulletType == 1)
                {
                    effectColor = tex2D(_WaterTex, i.uv * _WaterTex_UVScale).rgb;
                    emission = _WaterEmission;
                }
                else
                {
                    effectColor = tex2D(_WindTex, i.uv * _WindTex_UVScale).rgb;
                    emission = _WindEmission;
                }

                fixed3 col = lerp(grass.rgb, effectColor, i.influence);
                fixed3 emissive = effectColor * i.influence * emission;

                return fixed4(col + emissive, 1.0);
            }

            ENDCG
        }
    }
    FallBack Off
}
