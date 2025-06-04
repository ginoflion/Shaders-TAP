using UnityEngine;

public class BallTrailPainter : MonoBehaviour
{
    public Transform ballTransform;
    public Material floorMaterial;
    public Transform floorTransform;
    public float activationHeightOffset = 0.1f;
    public float trailWidth = 1.0f;

    private Vector3 _trailOriginWS;
    private Vector3 _lastKnownBallPositionWS; 
    private bool _awaitingFirstEffect = true;

    void Start()
    {
        if (floorMaterial == null)
        {
            Debug.LogError("BallTrailPainter: Floor Material not assigned!");
            return;
        }

        if (floorTransform == null)
        {
            Debug.LogError("BallTrailPainter: Floor Transform not assigned!");
            return;
        }


        _lastKnownBallPositionWS = Vector3.down * 10000;
        floorMaterial.SetVector("_BallPositionWS", _lastKnownBallPositionWS);
        floorMaterial.SetVector("_TrailOriginWS", _lastKnownBallPositionWS);
        floorMaterial.SetFloat("_TrailEffectActive", 0.0f);

    }

    void Update()
    {
        if (ballTransform == null)  return;
        

        Vector3 currentBallPosition = ballTransform.position;
        _lastKnownBallPositionWS = currentBallPosition; 

        if (_awaitingFirstEffect)
        {
            float distanceToFloorPlane = Vector3.Dot(currentBallPosition - floorTransform.position, floorTransform.up);
            if (distanceToFloorPlane < (trailWidth + activationHeightOffset))
            {
                _trailOriginWS = currentBallPosition - (floorTransform.up * distanceToFloorPlane);
                _awaitingFirstEffect = false;

                floorMaterial.SetVector("_TrailOriginWS", _trailOriginWS);
                floorMaterial.SetFloat("_TrailEffectActive", 1.0f);
            }
        }
        else
        {
            floorMaterial.SetVector("_BallPositionWS", currentBallPosition);
        }
    }

    public void AssignBall(Transform newBall, BulletType type)
    {
        ballTransform = newBall;
        _awaitingFirstEffect = true;

        _lastKnownBallPositionWS = newBall.position + Vector3.down * 10000;
        floorMaterial.SetVector("_BallPositionWS", _lastKnownBallPositionWS);
        floorMaterial.SetFloat("_TrailEffectActive", 0.0f);

        switch (type)
        {
            case BulletType.Fire:
                floorMaterial.SetFloat("_BulletType", 0.0f);
                break;

            case BulletType.Water:
                floorMaterial.SetFloat("_BulletType", 1.0f);
                break;
            case BulletType.Wind:
                floorMaterial.SetFloat("_BulletType", 2.0f);
                break;
            case BulletType.Earth:
                floorMaterial.SetFloat("_BulletType", 3.0f);
                break;
        }
    }
}