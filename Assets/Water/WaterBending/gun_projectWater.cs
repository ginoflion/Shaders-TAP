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
    public GameObject earthProjectile;
    public BallTrailPainter trailPainter;
    public Material wallMaterial;


    [Header("Sphere Settings")]
    public Material fireSphereMaterial;
    public Material waterSphereMaterial;
    public Material windSphereMaterial;

    public Material earthSphereMaterial;

    public GameObject Sphere;
    public Material sphereMaterial;

    public float speed = 200;

    public Renderer targetWallRenderer; 
    private Material _wallInstanceMaterial;

    void Start()
    {
        if (targetWallRenderer != null)
        {
            _wallInstanceMaterial = targetWallRenderer.material; 
        }
        else
        {
            Debug.LogError("Target Wall Renderer not assigned!");
        }
    }

    void Update()
    {
        if (_wallInstanceMaterial == null) return; 
        if (Input.GetKeyDown(KeyCode.Alpha1))
        {
            sphereMaterial = fireSphereMaterial;
            Sphere.GetComponent<Renderer>().material = sphereMaterial;
            _wallInstanceMaterial.SetFloat("_BulletType", 0.0f);
            projectile = fireProjectile;
            bulletType = BulletType.Fire;
        }
        else if (Input.GetKeyDown(KeyCode.Alpha2))
        {
            sphereMaterial = waterSphereMaterial;
            Sphere.GetComponent<Renderer>().material = sphereMaterial;
            _wallInstanceMaterial.SetFloat("_BulletType", 1.0f);
            projectile = waterProjectile;
            bulletType = BulletType.Water;
        }
        else if (Input.GetKeyDown(KeyCode.Alpha3))
        {
            sphereMaterial = windSphereMaterial;
            Sphere.GetComponent<Renderer>().material = sphereMaterial;
            _wallInstanceMaterial.SetFloat("_BulletType", 2.0f);
            projectile = windProjectile;
            bulletType = BulletType.Wind;
        }
        else if (Input.GetKeyDown(KeyCode.Alpha4))
        {
            sphereMaterial = earthSphereMaterial;
            Sphere.GetComponent<Renderer>().material = sphereMaterial;
            _wallInstanceMaterial.SetFloat("_BulletType", 3.0f);
            projectile = earthProjectile;
            bulletType = BulletType.Earth;
        }


        if (Input.GetKeyDown(KeyCode.Mouse0))
        {
            Quaternion spawnRotation = transform.rotation * Quaternion.Euler(0, 90, 0);
            GameObject instantiatedProjectile = Instantiate(projectile,
                                                           transform.position,
                                                           spawnRotation)
                as GameObject;

            instantiatedProjectile.GetComponent<Rigidbody>().velocity = transform.TransformDirection(new Vector3(0, 0, speed));

            TrailBall trailBall = instantiatedProjectile.GetComponent<TrailBall>();
            if (trailBall != null && trailPainter != null)
            {
                trailBall.Init(trailPainter, bulletType);
            }
        }
    }
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
        else if (projectile == earthProjectile)
        {
            bulletType = BulletType.Earth;
        }
        else
        {
            bulletType = BulletType.Water;
        }
        return bulletType;
    }
}
