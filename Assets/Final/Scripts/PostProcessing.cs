using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PostProcessing : MonoBehaviour
{
    public Material WaterMaterial;
    public Material EarthMaterial;
    public Material WindMaterial; 
    public Material FireMaterial;
    public Material DefaultMaterial;
    public Material mat;
    [SerializeField] public gun_projectWater gun;
    private BulletType currentBulletType;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        currentBulletType = gun.bulletType;
        switch (currentBulletType)
        {
            case BulletType.Fire:
                mat = FireMaterial;
                break;
            case BulletType.Water:
                mat = WaterMaterial;
                break;
            case BulletType.Wind:
                mat = WindMaterial;
                break;
            case BulletType.Earth:
                mat = EarthMaterial;
                break;
            case BulletType.None:
                mat = DefaultMaterial;
                break;
            default:
                mat = null; 
                break;
        }
        Graphics.Blit(source, destination, mat);
    }
}