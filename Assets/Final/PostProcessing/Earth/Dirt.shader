Shader "Hidden/Dirt" 
{
    Properties 
    {
        _MainTex ("Scene", 2D) = "white" {}
        _DirtTex ("Dirt Texture", 2D) = "white" {}
        _VignetteStrength ("Vignette Strength", Range(0, 1)) = 0.5
        _DirtDesaturation ("Dirt Desaturation", Range(0, 1)) = 0.5
        _DirtTintColor ("Dirt Tint Color", Color) = (0.4, 0.3, 0.2, 1)
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
 
            sampler2D _MainTex;
            sampler2D _DirtTex;
            float _VignetteStrength;
            float _DirtDesaturation;
            fixed4 _DirtTintColor;
 
            struct appdata 
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
 
            struct v2f 
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
 
            v2f vert(appdata v) 
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
 
            fixed4 frag(v2f i) : SV_Target 
            {
                // Sample textures
                fixed4 scene = tex2D(_MainTex, i.uv);
                fixed4 dirt = tex2D(_DirtTex, i.uv);
 
                // Desaturate scene
                float gray = dot(scene.rgb, float3(0.299, 0.587, 0.114));
                scene.rgb = lerp(scene.rgb, gray, _DirtDesaturation);
 
                // Vignette
                float2 center = i.uv - 0.5;
                float vignette = 1.0 - smoothstep(0.3, 0.7, length(center)) * _VignetteStrength;
                scene.rgb *= vignette;
 
                // Tint dirt
                dirt.rgb = lerp(dirt.rgb, _DirtTintColor.rgb, 0.5);
 
                // Composite
                return lerp(scene, dirt, dirt.a);
            }
            ENDCG
        }
    }
}