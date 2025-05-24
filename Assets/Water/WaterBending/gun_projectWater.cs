using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class gun_projectWater : MonoBehaviour
{
    public GameObject projectile;
    public BallTrailPainter trailPainter;

    public float speed = 200;

    // Update is called once per frame
    void Update()
    {

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
                trailBall.Init(trailPainter);
            }

        }

    }
}
