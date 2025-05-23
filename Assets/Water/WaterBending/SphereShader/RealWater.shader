Shader "Unlit/WaterFlow"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Water Color", Color) = (0.3, 0.7, 1.0, 0.8)
        _EdgeColor ("Edge Color", Color) = (0.8, 0.9, 1.0, 1.0)
        _FlowSpeed ("Flow Speed", Range(0.1, 3.0)) = 1.0
        _WaveHeight ("Wave Height", Range(0.0, 0.5)) = 0.2
        _Alpha ("Alpha", Range(0.0, 1.0)) = 0.8
        _EdgeGlow ("Edge Glow", Range(0.0, 2.0)) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200
        
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        
        CGPROGRAM
        #pragma surface surf Standard alpha:fade vertex:vert
        #pragma target 3.0
        
        sampler2D _MainTex;
        fixed4 _Color;
        fixed4 _EdgeColor;
        float _FlowSpeed;
        float _WaveHeight;
        float _Alpha;
        float _EdgeGlow;
        
        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };
        
        void vert(inout appdata_full v)
        {
            float time = _Time.y * _FlowSpeed;
            float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            
            float wave1 = sin(worldPos.x * 3.0 + time * 2.0) * 0.5;
            float wave2 = cos(worldPos.z * 2.0 + time * 1.5) * 0.3;
            float waveOffset = (wave1 + wave2) * _WaveHeight;
            
            v.vertex.xyz += v.normal * waveOffset;
        }
        
        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            float time = _Time.y * _FlowSpeed;
            
            float2 flowUV = IN.uv_MainTex;
            flowUV.y += time * 0.2; 
            flowUV.x += sin(IN.uv_MainTex.y * 8.0 + time) * 0.05; 
            
            fixed4 mainTex = tex2D(_MainTex, flowUV);
            
            float ripple = sin(IN.uv_MainTex.y * 15.0 + time * 3.0) * 0.5 + 0.5;
            ripple *= sin(IN.uv_MainTex.x * 10.0 + time * 2.0) * 0.5 + 0.5;
            
            float2 center = abs(IN.uv_MainTex - 0.5) * 2.0;
            float edgeFactor = 1.0 - max(center.x, center.y);
            float edgeGlow = pow(edgeFactor, 2.0) * _EdgeGlow;
            
            fixed4 waterColor = lerp(_Color, _EdgeColor, edgeGlow);
            waterColor.rgb += ripple * 0.2; 
            waterColor *= mainTex;
            
            o.Albedo = waterColor.rgb;
            o.Alpha = _Alpha * waterColor.a * edgeFactor;
            o.Emission = waterColor.rgb * edgeGlow * 0.3;
        }
        ENDCG
    }
    
    Fallback "Transparent/Diffuse"
}