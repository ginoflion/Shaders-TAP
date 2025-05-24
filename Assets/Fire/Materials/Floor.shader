Shader "Custom/Floor"
{
    Properties
    {
        _FloorTex("Floor Texture (RGB)", 2D) = "white" {}
        _RevealTex("Reveal Texture (RGB)", 2D) = "white" {}
        _RevealTex_UVScale("Reveal Texture UV Scale", Float) = 1.0

        _EffectTransition("Reveal Effect Transition Softness", Range(0.01, 2.0)) = 0.5
        _RevealEmission("Reveal Emission Strength", Range(0, 5)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow
        #pragma target 3.0

        sampler2D _FloorTex;
        sampler2D _RevealTex;
        float _RevealTex_UVScale;

        float _EffectTransition;
        float _RevealEmission;

        // Valores controlados por BallTrailPainter.cs
        float _DentDepth;       
        float _DentFalloff; 
        float _TrailWidth;

        float4 _BallPositionWS;   
        float4 _TrailOriginWS;   
        float _TrailEffectActive;

        struct Input
        {
            float2 uv_FloorTex;
            float revealInfluence;   // Pass combined influence from vertex to surface
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
            o.uv_FloorTex = v.texcoord.xy;

            float3 worldPosVertex = mul(unity_ObjectToWorld, v.vertex).xyz;
            float finalDentFactor = 0.0;
            float finalRevealInfluence = 0.0;

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
                float revealEffectOuterEdge = _TrailWidth + _EffectTransition * 0.5f;
                float revealEffectInnerEdge = _TrailWidth - _EffectTransition * 0.5f;
                // Ensure inner edge is not negative, especially if _TrailWidth is small.
                revealEffectInnerEdge = max(0.0f, revealEffectInnerEdge); 
                
                // smoothstep creates a smooth transition from 0 to 1 between inner and outer edges.
                // We want 1 inside (close to trail) and 0 outside, so we use 1.0 - smoothstep.
                finalRevealInfluence = 1.0 - smoothstep(revealEffectInnerEdge, revealEffectOuterEdge, distToTrail);
            }
            
            // Apply vertex displacement for the dent
            float3 displacement = v.normal * finalDentFactor * _DentDepth * -1.0f; // Displace inwards along normal
            v.vertex.xyz += displacement;

            // Pass magma influence to the surface shader
            o.revealInfluence = finalRevealInfluence;
            
            // o.worldPos is not explicitly set here as it's not used by the surf function in this shader.
            // If it were, it should be recalculated AFTER displacement:
            // o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float revealBlend = IN.revealInfluence;

            half4 floorCol = tex2D(_FloorTex, IN.uv_FloorTex);
            half4 revealCol = tex2D(_RevealTex, IN.uv_FloorTex * _RevealTex_UVScale);

            half3 finalAlbedo = lerp(floorCol.rgb, revealCol.rgb, revealBlend);
            half3 finalEmission = revealCol.rgb * revealBlend * _RevealEmission;

            o.Albedo = finalAlbedo;
            o.Emission = finalEmission;
            o.Metallic = 0.0; // Or lerp if desired: lerp(grassMetallic, magmaMetallic, magmaBlend)
            o.Smoothness = lerp(0.2, 0.05, revealBlend); // Grass might be a bit smoother
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}