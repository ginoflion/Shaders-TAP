Shader "Hidden/HeatHazeRadialGradientEffect"
{
    Properties
    {
        _MainTex ("Screen Texture", 2D) = "white" {}

        [Header(Radial Gradient Settings)]
        _GradientColorCenter ("Center Color", Color) = (0,0,1,1)
        _GradientColorOuter ("Outer Color", Color) = (0,1,0,1)
        _GradientRadius ("Radius (0-1, screen relative)", Range(0.01, 1.5)) = 0.5
        _GradientIntensity ("Intensity", Range(0, 1)) = 0.75

        [Header(Heat Haze Distortion Settings)]
        _DistortionTex ("Distortion Noise Texture", 2D) = "gray" {} 
        _DistortionStrength ("Strength", Range(0, 0.1)) = 0.01     
        _DistortionSpeedX ("Speed X", Range(-5, 5)) = 0.5          
        _DistortionSpeedY ("Speed Y", Range(-5, 5)) = 1.0         
        _DistortionScale ("Scale", Range(0.1, 20)) = 5.0          
        _DistortionMaskPower ("Mask Power (Center Falloff)", Range(0.1, 10)) = 2.0 
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _DistortionTex;

            // Gradiente
            fixed4 _GradientColorCenter;
            fixed4 _GradientColorOuter;
            float _GradientRadius;
            float _GradientIntensity;

            // Distorção
            float _DistortionStrength;
            float _DistortionSpeedX;
            float _DistortionSpeedY;
            float _DistortionScale;
            float _DistortionMaskPower;


            fixed4 frag (v2f_img i) : SV_Target
            {
                float2 distortionUV = i.uv * _DistortionScale;
                distortionUV.x += _Time.y * _DistortionSpeedX;
                distortionUV.y += _Time.y * _DistortionSpeedY;

                float2 noiseValue = (tex2D(_DistortionTex, distortionUV).rg * 2.0 - 1.0);

                float2 centeredUV_Uncorrected = i.uv - 0.5;
                float distForMask = length(centeredUV_Uncorrected); 
                

                float distortionMask = saturate(pow(distForMask / (_GradientRadius * 0.75 + 0.01), _DistortionMaskPower));


                float2 uvOffset = noiseValue * _DistortionStrength * distortionMask;


                float2 distortedSceneUV = i.uv + uvOffset;

                fixed4 originalColor = tex2D(_MainTex, distortedSceneUV);
                float3 finalColor = originalColor.rgb;


                float currentAspectRatio = _ScreenParams.x / _ScreenParams.y;
                float2 centeredUV_Corrected = i.uv - 0.5; 

                if (currentAspectRatio > 1.0)
                {
                    centeredUV_Corrected.x *= currentAspectRatio;
                }
                else
                {
                    centeredUV_Corrected.y /= currentAspectRatio;
                }
                float distFromCenter = length(centeredUV_Corrected);

                float t = smoothstep(0.0, _GradientRadius, distFromCenter);
                t = saturate(t);

                fixed3 gradientColor = lerp(_GradientColorCenter.rgb, _GradientColorOuter.rgb, t);

                finalColor = lerp(finalColor, gradientColor, _GradientIntensity * _GradientColorCenter.a);

                return fixed4(finalColor, originalColor.a);
            }
            ENDCG
        }
    }
    Fallback Off
}