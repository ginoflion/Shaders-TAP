using UnityEngine;

public class TrailBall : MonoBehaviour
{
    private BallTrailPainter trailPainter;

    public void Init(BallTrailPainter painter)
    {
        trailPainter = painter;
        trailPainter.AssignBall(transform);
    }

    void OnDestroy()
    {
        if (trailPainter != null)
        {
            trailPainter.NotifyBallDestroyed(transform.position);
        }
    }
}
