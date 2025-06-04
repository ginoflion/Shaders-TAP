using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class gun_projectWater : MonoBehaviour
{
    public GameObject projectile;
    public BulletType bulletType;
    public GameObject fireProjectile;
    public GameObject waterProjectile;
    public GameObject windProjectile;
    public BallTrailPainter trailPainter;
    public Material wallMaterial;
    public float effectType;

    public float speed = 200;

     public Renderer targetWallRenderer; // Assign your wall's Renderer component in the Inspector
    private Material _wallInstanceMaterial; // To store the instance

    void Start()
    {
        if (targetWallRenderer != null)
        {
            _wallInstanceMaterial = targetWallRenderer.material; // Get the instance at the start
        }
        else
        {
            Debug.LogError("Target Wall Renderer not assigned!");
        }
    }

    void Update()
    {
        if (_wallInstanceMaterial == null) return; // Don't do anything if no material

        if (Input.GetKeyDown(KeyCode.Tab))
        {
            _wallInstanceMaterial.SetFloat("_BulletType", 0.0f);
            projectile = fireProjectile;
            bulletType = BulletType.Fire;
            effectType = 1.0f;
        }
        else if (Input.GetKeyDown(KeyCode.CapsLock))
        {
            _wallInstanceMaterial.SetFloat("_BulletType", 1.0f);
            projectile = waterProjectile;
            bulletType = BulletType.Water;
            effectType = 0.0f;
        }
        else if (Input.GetKeyDown(KeyCode.LeftShift))
        {
            _wallInstanceMaterial.SetFloat("_BulletType", 2.0f);
            projectile = windProjectile;
            bulletType = BulletType.Wind;
            effectType = 2.0f;
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
    // ... GetBulletType can remain as is, but it's not used in this script.
    public BulletType GetBulletType()
    {
        if (projectile == fireProjectile)
        {
            bulletType = BulletType.Fire;
        }
        else if (projectile == waterProjectile)
        {
            bulletType = BulletType.Water;
        }
        else if (projectile == windProjectile)
        {
            bulletType = BulletType.Wind;
        }
        else
        {
            bulletType = BulletType.Water; // Default to Water if no projectile is set
        }
        return bulletType;
    }
}
