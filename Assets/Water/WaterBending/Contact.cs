using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Contact : MonoBehaviour
{
    public Vector4[] pontosEmbateFire = new Vector4[1024];
    public Vector4[] pontosEmbateWind = new Vector4[1024];
    public Vector4[] pontosEmbateWater = new Vector4[1024];
    public Vector4[] pontosEmbateEarth = new Vector4[1024];
    int contadorFire = 0;
    int contadorWind = 0;
    int contadorWater = 0;
    int contadorEarth = 0;
    [SerializeField] private gun_projectWater gunProjectWater;
    public BulletType bulletType;
    void Start()
    {
        for (int i = 0; i < pontosEmbateFire.Length; i++)
        {
            pontosEmbateFire[i] = new Vector4(0, 0, 0, 1.0f);
        }
        for (int i = 0; i < pontosEmbateWind.Length; i++)
        {
            pontosEmbateWind[i] = new Vector4(0, 0, 0, 1.0f);
        }
        for (int i = 0; i < pontosEmbateWater.Length; i++)
        {
            pontosEmbateWater[i] = new Vector4(0, 0, 0, 1.0f);
        }
        for (int i = 0; i < pontosEmbateEarth.Length; i++)
        {
            pontosEmbateEarth[i] = new Vector4(0, 0, 0, 1.0f);
        }

        gunProjectWater = FindAnyObjectByType<gun_projectWater>();
    }

    void Update()
    {
        if (gunProjectWater == null)
        {
            Debug.LogError("gun_projectWater component not found on this GameObject.");
        }
        bulletType = gunProjectWater.bulletType;
    }

    void OnCollisionEnter(Collision collision)
    {
        Vector3 worldPos = collision.GetContact(0).point;
        if (bulletType == BulletType.Fire)
        {
            if (contadorFire < pontosEmbateFire.Length)
            {
                pontosEmbateFire[contadorFire] = new Vector4(worldPos.x, worldPos.y, worldPos.z, Time.time);
                GetComponent<Renderer>().material.SetVectorArray("_PontoEmbateFireArray", pontosEmbateFire);
                contadorFire++;
            }
        }
        else if (bulletType == BulletType.Wind)
        {
            if (contadorWind < pontosEmbateWind.Length)
            {
                pontosEmbateWind[contadorWind] = new Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0f);
                GetComponent<Renderer>().material.SetVectorArray("_PontoEmbateWindArray", pontosEmbateWind);
                contadorWind++;
            }
        }
        else if (bulletType == BulletType.Water)
        {
            if (contadorWater < pontosEmbateWater.Length)
            {
                pontosEmbateWater[contadorWater] = new Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0f);
                GetComponent<Renderer>().material.SetVectorArray("_PontoEmbateWaterArray", pontosEmbateWater);
                contadorWater++;
            }
        }
        else
        {
            if (contadorEarth < pontosEmbateEarth.Length)
            {
                pontosEmbateEarth[contadorEarth] = new Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0f);
                GetComponent<Renderer>().material.SetVectorArray("_PontoEmbateEarthArray", pontosEmbateEarth);
                contadorEarth++;
            }
        }
    }
}