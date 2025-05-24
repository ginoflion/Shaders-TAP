using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Contact : MonoBehaviour
{
    public Vector4[] pontosEmbate = new Vector4[1024];
    int contador = 0;
    void Start()
    {
        for (int i = 0; i < pontosEmbate.Length; i++)
        {
            pontosEmbate[i] = new Vector4(0, 0, 0, 1.0f);
        }
    }

    // Update is called once per frame
    void Update()
    {

    }

        void OnCollisionEnter(Collision collision)
    {
        Vector3 worldPos = collision.GetContact(0).point;

        if (contador < pontosEmbate.Length)
        {
            pontosEmbate[contador] = new Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0f);
            GetComponent<Renderer>().material.SetVectorArray("_PontoEmbateArray", pontosEmbate);
            contador++;
        }
    }
}