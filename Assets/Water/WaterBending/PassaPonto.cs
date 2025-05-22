using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PassaPonto : MonoBehaviour
{
    private void OnCollisionEnter(Collision collision)
    {
        this.GetComponent<Renderer>().material.SetVector("pontoCSharp", collision.GetContact(0).point);
    }
}
