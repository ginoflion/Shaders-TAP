using UnityEngine;

public enum BulletType
{
    Fire,
    Water,
    Wind,
    Earth,
    None
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

    void OnCollisionEnter(Collision collision)
    {
        if (collision.gameObject.CompareTag("Player"))
        {
            Physics.IgnoreCollision(GetComponent<Collider>(), collision.collider);
        }
        if (collision.gameObject.CompareTag("Wall"))
        {
            Destroy(gameObject);
        }   
    }
}
