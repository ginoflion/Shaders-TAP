Shader "Hidden/DrawBrush"
{
    Properties
    {
        _MainTex ("Brush", 2D) = "white" {}
        _UV ("UV Center", Vector) = (0,0,0,0)
        _BrushSize ("Brush Size", Float) = 0.05
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            ZTest Always Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _UV;
            float _BrushSize;

            fixed4 frag(v2f_img i) : SV_Target
            {
                float2 coord = i.uv;
                float2 diff = coord - _UV.xy;
                float dist = length(diff / _BrushSize);
                float brush = tex2D(_MainTex, diff / _BrushSize + 0.5).r;

                return fixed4(brush, 0, 0, 1); // Use red channel for mask
            }
            ENDCG
        }
    }
}
