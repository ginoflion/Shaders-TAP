using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class Contact : MonoBehaviour
{
    // Para Fire (Tipo 0 - Impacto Emissivo): w = Time.time do impacto
    public Vector4[] pontosEmbateFire = new Vector4[1024];
    // Para Wind (Tipo 2 - Deforma��o): w = intensidade (ex: 1.0f)
    public Vector4[] pontosEmbateWind = new Vector4[1024];
    // Para Water (Tipo 1 - Polui��o): w = intensidade (ex: 1.0f)
    public Vector4[] pontosEmbateWater = new Vector4[1024];
    // O array pontosEmbateEarth pode n�o ser mais necess�rio se o seu BulletType.Earth (tipo 3)
    // n�o tiver um efeito dedicado ou se voc� n�o tiver mais um tipo 3.
    // Vou mant�-lo aqui caso voc� tenha outros planos para ele.
    public Vector4[] pontosEmbateEarth = new Vector4[1024];

    int contadorFire = 0;
    int contadorWind = 0;
    int contadorWater = 0;
    int contadorEarth = 0;

    [SerializeField] private gun_projectWater gunProjectWater;
    public BulletType currentBulletType; // Vem do script da arma

    private Material objectMaterial;

    void Start()
    {
        Renderer rend = GetComponent<Renderer>();
        if (rend != null)
        {
            objectMaterial = rend.material;
        }
        else
        {
            Debug.LogError("Objeto n�o possui Renderer!", this);
            this.enabled = false;
            return;
        }

        // Inicializa��o:
        // Para Fire (impacto emissivo), w = 0.0f significa inativo.
        for (int i = 0; i < pontosEmbateFire.Length; i++) { pontosEmbateFire[i] = Vector4.zero; }
        // Para Wind/Water, w = 0.0f significa sem intensidade ou inativo.
        for (int i = 0; i < pontosEmbateWind.Length; i++) { pontosEmbateWind[i] = Vector4.zero; }
        for (int i = 0; i < pontosEmbateWater.Length; i++) { pontosEmbateWater[i] = Vector4.zero; }
        for (int i = 0; i < pontosEmbateEarth.Length; i++) { pontosEmbateEarth[i] = Vector4.zero; }

        if (gunProjectWater == null)
        {
            gunProjectWater = FindAnyObjectByType<gun_projectWater>();
        }
        if (gunProjectWater == null)
        {
            Debug.LogError("gun_projectWater n�o encontrado na cena.", this);
        }

        if (objectMaterial != null)
        {
            // Enviar arrays inicializados para o shader
            objectMaterial.SetVectorArray("_PontoEmbateFireArray", pontosEmbateFire);
            objectMaterial.SetVectorArray("_PontoEmbateWindArray", pontosEmbateWind);
            objectMaterial.SetVectorArray("_PontoEmbateWaterArray", pontosEmbateWater);
            objectMaterial.SetVectorArray("_PontoEmbateEarthArray", pontosEmbateEarth);
        }
    }

    void Update()
    {
        if (gunProjectWater != null)
        {
            currentBulletType = gunProjectWater.bulletType;
        }

        if (objectMaterial != null)
        {
            objectMaterial.SetFloat("_BulletType", (float)currentBulletType);
        }
    }

    void OnCollisionEnter(Collision collision)
    {
        if (objectMaterial == null) return;

        ContactPoint contactPoint = collision.GetContact(0);
        Vector3 worldPos = contactPoint.point;

        // Seu enum BulletType define os valores num�ricos.
        // Supondo que BulletType.Fire seja 0, BulletType.Water seja 1, etc.
        switch (currentBulletType)
        {
            case BulletType.Fire: // Este � o TIPO 0 - Impacto Emissivo
                pontosEmbateFire[contadorFire] = new Vector4(worldPos.x, worldPos.y, worldPos.z, Time.time);
                objectMaterial.SetVectorArray("_PontoEmbateFireArray", pontosEmbateFire);
                contadorFire = (contadorFire + 1) % pontosEmbateFire.Length;
                break;

            case BulletType.Wind: // Este � o TIPO 2 - Deforma��o Vento
                pontosEmbateWind[contadorWind] = new Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0f); // w = intensidade
                objectMaterial.SetVectorArray("_PontoEmbateWindArray", pontosEmbateWind);
                contadorWind = (contadorWind + 1) % pontosEmbateWind.Length;
                break;

            case BulletType.Water: // Este � o TIPO 1 - Polui��o �gua
                pontosEmbateWater[contadorWater] = new Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0f); // w = intensidade
                objectMaterial.SetVectorArray("_PontoEmbateWaterArray", pontosEmbateWater);
                contadorWater = (contadorWater + 1) % pontosEmbateWater.Length;
                break;

            case BulletType.Earth:
                pontosEmbateEarth[contadorEarth] = new Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0f);
                objectMaterial.SetVectorArray("_PontoEmbateEarthArray", pontosEmbateEarth);
                contadorEarth = (contadorEarth + 1) % pontosEmbateEarth.Length;
                break;
        }
    }
}