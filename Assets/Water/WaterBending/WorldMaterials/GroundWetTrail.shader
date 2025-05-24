Shader "Custom/Floor"
{
    Properties
    {
        _GrassTex("Grass Texture (RGB)", 2D) = "white" {}
        _MagmaTex("Magma Texture (RGB)", 2D) = "white" {}
        _MagmaTex_UVScale("Magma Texture UV Scale", Float) = 1.0

        _EffectTransition("Magma Effect Transition Softness", Range(0.01, 2.0)) = 0.5
        _MagmaEmission("Magma Emission Strength", Range(0, 5)) = 1.0

        // Note: _DentDepth, _DentFalloff, and _TrailWidth are now controlled
        // exclusively by the BallTrailPainter.cs script.
        // They are declared as uniforms below but not exposed in the Material Inspector here
        // to avoid confusion. The script MUST set them.
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow
        #pragma target 3.0

        sampler2D _GrassTex;
        sampler2D _MagmaTex;
        float _MagmaTex_UVScale;

        float _EffectTransition;
        float _MagmaEmission;

        // Uniforms controlled by C# script (BallTrailPainter.cs)
        float _DentDepth;         // How deep the dent effect is
        float _DentFalloff;       // How sharply the dent effect falls off
        float _TrailWidth;        // The radius of the trail's influence and visual width

        float4 _BallPositionWS;    // Current end of the trail (or last known if ball destroyed)
        float4 _TrailOriginWS;   // Fixed start of the trail
        float _TrailEffectActive; // 0.0 (inactive) or 1.0 (active)

        struct Input
        {
            float2 uv_GrassTex;
            float magmaInfluence;   // Pass combined influence from vertex to surface
        };

        // Function to calculate the distance from point P to line segment AB
        // and the closest point on that segment to P.
        // Returns the distance.
        float DistancePointToLineSegment(float3 p, float3 a, float3 b, out float3 closestPointOnSegment)
        {
            float3 ab = b - a; // Vector from A to B
            float3 ap = p - a; // Vector from A to P

            float sqrLenAB = dot(ab, ab); // Squared length of segment AB

            // If A and B are (nearly) the same point, the segment is just point A.
            // The closest point to P on the segment is A itself.
            if (sqrLenAB < 0.00001f)
            {
                closestPointOnSegment = a;
                return distance(p, a);
            }

            // Project AP onto AB to find the parameter t
            // t = dot(AP, AB) / dot(AB, AB)
            // t represents how far along AB the projection of P lies.
            float t = dot(ap, ab) / sqrLenAB;

            // Clamp t to the range [0, 1] to ensure the closest point is on the segment AB.
            // If t < 0, closest point is A.
            // If t > 1, closest point is B.
            // Otherwise, it's A + t * AB.
            t = saturate(t);

            closestPointOnSegment = a + t * ab; // Calculate the closest point on the segment
            return distance(p, closestPointOnSegment); // Return the distance from P to this closest point
        }


        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.uv_GrassTex = v.texcoord.xy;

            float3 worldPosVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
            float finalDentFactor = 0.0;
            float finalMagmaInfluence = 0.0;

            // Only calculate trail effect if it's active
            if (_TrailEffectActive > 0.5) // Use > 0.5 for float comparison to bool-like behavior
            {
                float3 closestPointOnTrailSegment;
                // Calculate distance from the current vertex to the line segment
                // defined by _TrailOriginWS and _BallPositionWS.
                float distToTrail = DistancePointToLineSegment(worldPosVertex, _TrailOriginWS.xyz, _BallPositionWS.xyz, closestPointOnTrailSegment);

                // --- Dent Factor based on distance to trail segment ---
                // Effect diminishes as distance from the trail line increases, up to _TrailWidth.
                // saturate(1.0 - distToTrail / _TrailWidth) gives 1 at the center, 0 at _TrailWidth edge.
                // pow(..., _DentFalloff) controls the sharpness of the falloff.
                finalDentFactor = pow(saturate(1.0 - distToTrail / _TrailWidth), _DentFalloff);
                
                // --- Magma Influence based on distance to trail segment ---
                // Similar falloff logic for magma, possibly with a softer transition.
                float magmaEffectOuterEdge = _TrailWidth + _EffectTransition * 0.5f;
                float magmaEffectInnerEdge = _TrailWidth - _EffectTransition * 0.5f;
                // Ensure inner edge is not negative, especially if _TrailWidth is small.
                magmaEffectInnerEdge = max(0.0f, magmaEffectInnerEdge); 
                
                // smoothstep creates a smooth transition from 0 to 1 between inner and outer edges.
                // We want 1 inside (close to trail) and 0 outside, so we use 1.0 - smoothstep.
                finalMagmaInfluence = 1.0 - smoothstep(magmaEffectInnerEdge, magmaEffectOuterEdge, distToTrail);
            }
            
            // Apply vertex displacement for the dent
            float3 displacement = v.normal * finalDentFactor * _DentDepth * -1.0f; // Displace inwards along normal
            v.vertex.xyz += displacement;

            // Pass magma influence to the surface shader
            o.magmaInfluence = finalMagmaInfluence;
            
            // o.worldPos is not explicitly set here as it's not used by the surf function in this shader.
            // If it were, it should be recalculated AFTER displacement:
            // o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float magmaBlend = IN.magmaInfluence;

            half4 grassCol = tex2D(_GrassTex, IN.uv_GrassTex);
            half4 magmaCol = tex2D(_MagmaTex, IN.uv_GrassTex * _MagmaTex_UVScale);

            half3 finalAlbedo = lerp(grassCol.rgb, magmaCol.rgb, magmaBlend);
            half3 finalEmission = magmaCol.rgb * magmaBlend * _MagmaEmission;

            o.Albedo = finalAlbedo;
            o.Emission = finalEmission;
            o.Metallic = 0.0; // Or lerp if desired: lerp(grassMetallic, magmaMetallic, magmaBlend)
            o.Smoothness = lerp(0.2, 0.05, magmaBlend); // Grass might be a bit smoother
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}