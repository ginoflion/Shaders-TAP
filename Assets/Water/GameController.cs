using UnityEngine;

public class GameController : MonoBehaviour
{
    [SerializeField] private Rigidbody waterSphereRigidbody;
    public void SendWaterDown(){
        waterSphereRigidbody.useGravity = true;
    }
}
