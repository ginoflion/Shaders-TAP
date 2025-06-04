using UnityEngine;

public enum BulletType
{
    Fire,
    Water,
    Wind
}


public class TrailBall : MonoBehaviour
{
    private BulletType bulletType;
    private BallTrailPainter trailPainter;

    public void Init(BallTrailPainter painter, BulletType type)
    {
        bulletType = type;
        trailPainter = painter;
        trailPainter.AssignBall(transform, bulletType);
    }

    void OnDestroy()
    {
        if (trailPainter != null)
        {
            trailPainter.NotifyBallDestroyed(transform.position);
        }
    }
}
