Shader "Custom/PedraRotativa"
{
    Properties
    {
        _MainTex ("Textura da Pedra", 2D) = "white" {}
        _Cor ("Cor da Pedra", Color) = (1,1,1,1)
        _Deformacao ("Deformacao da Pedra", Range(-0.2, 0.2)) = 0.1
        _EscalaRuido ("Escala do Ruido", Float) = 4.0
        _VelocidadeRotacao ("Velocidade de Rotacao", Float) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Cor;
            float _Deformacao;
            float _EscalaRuido;
            float _VelocidadeRotacao;
            
            float hash(float3 p)
            {
                return frac(sin(dot(p, float3(127.1, 311.7, 74.7))) * 43758.5453123);
            }
            
            float noise3D(float3 p)
            {
                float3 i = floor(p);
                float3 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                
                return lerp(lerp(lerp(hash(i + float3(0,0,0)), hash(i + float3(1,0,0)), f.x),
                               lerp(hash(i + float3(0,1,0)), hash(i + float3(1,1,0)), f.x), f.y),
                          lerp(lerp(hash(i + float3(0,0,1)), hash(i + float3(1,0,1)), f.x),
                               lerp(hash(i + float3(0,1,1)), hash(i + float3(1,1,1)), f.x), f.y), f.z);
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                
                float tempo = _Time.y * _VelocidadeRotacao;
                
                float cosY = cos(tempo);
                float sinY = sin(tempo);
                float3x3 rotacaoY = float3x3(
                    cosY, 0, sinY,
                    0, 1, 0,
                    -sinY, 0, cosY
                );
                
                float cosX = cos(tempo * 0.3);
                float sinX = sin(tempo * 0.3);
                float3x3 rotacaoX = float3x3(
                    1, 0, 0,
                    0, cosX, -sinX,
                    0, sinX, cosX
                );
                
                float3x3 rotacaoFinal = mul(rotacaoY, rotacaoX);
                
                float3 verticeRotacionado = mul(rotacaoFinal, v.vertex.xyz);
                float3 normalRotacionada = mul(rotacaoFinal, v.normal);
                
                float noiseValue = noise3D(v.vertex.xyz * _EscalaRuido);
                verticeRotacionado += normalRotacionada * noiseValue * _Deformacao;
                
                o.vertex = UnityObjectToClipPos(float4(verticeRotacionado, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(normalRotacionada);
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 textura = tex2D(_MainTex, i.uv);
                
                float3 luzDirecao = normalize(float3(1, 1, 1));
                float iluminacao = max(0.3, dot(normalize(i.worldNormal), luzDirecao));
                
                return textura * _Cor * iluminacao;
            }
            ENDCG
        }
    }
}