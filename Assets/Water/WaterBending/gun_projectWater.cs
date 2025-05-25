using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class gun_projectWater : MonoBehaviour
{
    public GameObject projectile;
    public BulletType bulletType;
    public GameObject fireProjectile;
    public GameObject waterProjectile;
    public BallTrailPainter trailPainter;
    public float effectType;

    public float speed = 200;

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Tab))
        {
            projectile = fireProjectile;
            bulletType = BulletType.Fire;
            effectType = 1.0f; // Set effect type for fire
        }
        else if (Input.GetKeyDown(KeyCode.CapsLock))
        {
            projectile = waterProjectile;
            bulletType = BulletType.Water;
            effectType = 0.0f; // Set effect type for water
        }

        if (Input.GetKeyDown(KeyCode.Mouse0))
        {
            GameObject instantiatedProjectile = Instantiate(projectile,
                                                           transform.position,
                                                           transform.rotation)
                as GameObject;

            instantiatedProjectile.GetComponent<Rigidbody>().velocity = transform.TransformDirection(new Vector3(0, 0, speed));

            TrailBall trailBall = instantiatedProjectile.GetComponent<TrailBall>();
            if (trailBall != null && trailPainter != null)
            {
                trailBall.Init(trailPainter, bulletType);
                trailPainter.SetEffectType(effectType);
            }

        }

    }

    public void GetBulletType()
    {
        if (projectile == fireProjectile)
        {
            bulletType = BulletType.Fire;
        }
        else if (projectile == waterProjectile)
        {
            bulletType = BulletType.Water;
        }
        else
        {
            bulletType = BulletType.Water; // Default to Water if no projectile is set
        }
    }
}
