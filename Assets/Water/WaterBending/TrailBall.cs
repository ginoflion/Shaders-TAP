using UnityEngine;

public enum BulletType
{
    Fire,
    Water,
    Wind,
    Earth
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
}
