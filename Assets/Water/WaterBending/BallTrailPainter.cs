using UnityEngine;

public class BallTrailPainter : MonoBehaviour
{
    [Header("Core Setup")]
    public Transform ballTransform;
    public Material floorMaterial;
    public Transform floorTransform;

    [Header("Trail Effect Settings")]
    [Tooltip("How close above the floor's Y the ball needs to be (within its influence) to be considered 'affecting'")]
    public float activationHeightOffset = 0.1f;
    [Tooltip("The radius of the trail's influence and visual width.")]
    public float trailWidth = 1.0f;
    [Tooltip("How deep the dent effect is for the trail.")]
    public float dentDepth = 0.1f;
    [Tooltip("How sharply the dent effect falls off. Higher is sharper.")]
    public float dentFalloff = 1.5f;

    private Vector3 _trailOriginWS;
    private Vector3 _lastKnownBallPositionWS; // To store the ball's position
    private bool _isTrailActive = false;
    private bool _awaitingFirstEffect = true;
    private bool _ballIsDestroyed = false; // New flag

    private float _prevTrailWidth = -1f;
    private float _prevDentDepth = -1f;
    private float _prevDentFalloff = -1f;

    private static readonly int BallPositionWSID = Shader.PropertyToID("_BallPositionWS");
    private static readonly int TrailOriginWSID = Shader.PropertyToID("_TrailOriginWS");
    private static readonly int TrailEffectActiveID = Shader.PropertyToID("_TrailEffectActive");
    private static readonly int TrailWidthID = Shader.PropertyToID("_TrailWidth");
    private static readonly int DentDepthID = Shader.PropertyToID("_DentDepth");
    private static readonly int DentFalloffID = Shader.PropertyToID("_DentFalloff");

    void Start()
    {
        if (floorMaterial == null)
        {
            Debug.LogError("BallTrailPainter: Floor Material not assigned!", this);
            enabled = false;
            return;
        }

        if (floorTransform == null)
        {
            Debug.LogError("BallTrailPainter: Floor Transform not assigned!", this);
            enabled = false;
            return;
        }

        if (floorMaterial.shader.name != "Custom/InteractiveFloor_Trail")
        {
            Debug.LogWarning($"BallTrailPainter: Floor material is not using 'Custom/InteractiveFloor_Trail'. Current: {floorMaterial.shader.name}", this);
        }

        UpdateShaderEffectParameters();

        // Initialize ball position far away
        _lastKnownBallPositionWS = Vector3.down * 10000;
        floorMaterial.SetVector(BallPositionWSID, _lastKnownBallPositionWS);
        floorMaterial.SetVector(TrailOriginWSID, _lastKnownBallPositionWS);
        floorMaterial.SetFloat(TrailEffectActiveID, 0.0f);

    }

    // Public method to be called by the ball script right before it's destroyed
    public void NotifyBallDestroyed(Vector3 finalBallPosition)
    {
        if (_isTrailActive) // Only if a trail was active
        {
            _ballIsDestroyed = true;
            _lastKnownBallPositionWS = finalBallPosition;
            floorMaterial.SetVector(BallPositionWSID, _lastKnownBallPositionWS); // Set the final fixed end point
            Debug.Log($"BallTrailPainter: Ball destroyed. Trail end fixed at {_lastKnownBallPositionWS.ToString("F3")}", this);
        }
        else
        {
            // If trail wasn't active, just ensure it's visually off
            StopTrail();
        }
        ballTransform = null; // Nullify the reference
    }


    void Update()
    {
        if (floorMaterial == null || floorTransform == null) return; // ballTransform can be null if destroyed

        UpdateShaderEffectParameters();

        if (_ballIsDestroyed)
        {
            // If ball is destroyed, the trail is fixed. No more updates to _BallPositionWS.
            // _TrailEffectActive should still be 1.0, _TrailOriginWS is set,
            // and _BallPositionWS is set to _lastKnownBallPositionWS.
            return;
        }

        if (ballTransform == null) // Safety check if NotifyBallDestroyed wasn't called
        {
            if (!_ballIsDestroyed && _isTrailActive) // If trail was active but we lost the ball unexpectedly
            {
                Debug.LogWarning("BallTrailPainter: Ball transform became null unexpectedly while trail active. Stopping trail.", this);
                StopTrail(); // Or attempt to fix it to last known if you have it.
            }
            return;
        }

        Vector3 currentBallPosition = ballTransform.position;
        _lastKnownBallPositionWS = currentBallPosition; // Keep track of the latest position

        if (_awaitingFirstEffect)
        {
            float distanceToFloorPlane = Vector3.Dot(currentBallPosition - floorTransform.position, floorTransform.up);
            if (distanceToFloorPlane < (trailWidth + activationHeightOffset))
            {
                _trailOriginWS = currentBallPosition - (floorTransform.up * distanceToFloorPlane);
                _isTrailActive = true;
                _awaitingFirstEffect = false;

                floorMaterial.SetVector(TrailOriginWSID, _trailOriginWS);
                floorMaterial.SetFloat(TrailEffectActiveID, 1.0f);
                // Set current ball position as the initial end of the trail
                floorMaterial.SetVector(BallPositionWSID, currentBallPosition);
                Debug.Log($"BallTrailPainter: Trail started. Origin: {_trailOriginWS.ToString("F3")}, Ball at: {currentBallPosition.ToString("F3")}", this);
            }
        }

        if (_isTrailActive)
        {
            floorMaterial.SetVector(BallPositionWSID, currentBallPosition);
        }
    }

    void UpdateShaderEffectParameters()
    {
        // ... (same as before) ...
        if (floorMaterial == null) return;

        if (_prevTrailWidth != trailWidth)
        {
            floorMaterial.SetFloat(TrailWidthID, trailWidth);
            _prevTrailWidth = trailWidth;
        }
        if (_prevDentDepth != dentDepth)
        {
            floorMaterial.SetFloat(DentDepthID, dentDepth);
            _prevDentDepth = dentDepth;
        }
        if (_prevDentFalloff != dentFalloff)
        {
            floorMaterial.SetFloat(DentFalloffID, dentFalloff);
            _prevDentFalloff = dentFalloff;
        }
    }

    public void StopTrail()
    {
        _isTrailActive = false;
        _ballIsDestroyed = false; // Reset this too
        if (floorMaterial != null)
        {
            floorMaterial.SetFloat(TrailEffectActiveID, 0.0f);
        }
        // Debug.Log("BallTrailPainter: Trail stopped.", this);
    }

    public void ResetForNewTrail()
    {
        StopTrail();
        _awaitingFirstEffect = true;
        // ballTransform should be re-assigned if a new ball is created
        Debug.Log("BallTrailPainter: Reset for new trail. Awaiting first effect.", this);
    }

    // It's good practice to also handle the case where this manager object itself is destroyed
    void OnDestroy()
    {
        if (floorMaterial != null && !_ballIsDestroyed && _isTrailActive) // If trail was active and we are destroyed before ball
        {
            // If this manager is destroyed, turn off the effect on the material
            // to prevent a frozen trail if the material is shared or persists.
            floorMaterial.SetFloat(TrailEffectActiveID, 0.0f);
            Debug.Log("BallTrailPainter destroyed: Turning off trail effect in material.", this);
        }
    }

    public void AssignBall(Transform newBall, BulletType type)
    {
        ballTransform = newBall;
        _ballIsDestroyed = false;
        _isTrailActive = false;
        _awaitingFirstEffect = true;

        _lastKnownBallPositionWS = newBall.position + Vector3.down * 10000;
        floorMaterial.SetVector(BallPositionWSID, _lastKnownBallPositionWS);
        floorMaterial.SetFloat(TrailEffectActiveID, 0.0f);

        // Customize trail effect based on bullet type
        switch (type)
        {
            case BulletType.Fire:
                dentDepth = 1.15f;
                dentFalloff = 1.0f;
                floorMaterial.SetFloat("_EffectTransition", 0.3f);
                floorMaterial.SetFloat("_MagmaEmission", 3.0f);
                floorMaterial.SetFloat("_BulletType", 0.0f); // Set effect type for fire
                break;

            case BulletType.Water:
                dentDepth = 0.05f;
                dentFalloff = 2.0f;
                floorMaterial.SetFloat("_EffectTransition", 0.9f);
                floorMaterial.SetFloat("_MagmaEmission", 0.2f);
                floorMaterial.SetFloat("_BulletType", 1.0f); // Set effect type for water
                break;
        }

        Debug.Log($"BallTrailPainter: Assigned new {type} ball: {newBall.name}", this);
    }
    
    public void SetEffectType(float effectType)
    {
        floorMaterial.SetFloat("_EffectType", effectType);
    }



}