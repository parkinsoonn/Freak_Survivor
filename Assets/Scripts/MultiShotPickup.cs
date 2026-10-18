using UnityEngine;

// Toplandığında oyuncunun bir atışta çıkardığı mermi sayısını 1 artırır (ölene kadar kalıcı)
public class MultiShotPickup : MonoBehaviour
{
    void OnTriggerEnter2D(Collider2D hitInfo)
    {
        if (hitInfo.CompareTag("Player"))
        {
            PlayerController player = hitInfo.GetComponent<PlayerController>();
            if (player != null)
            {
                player.AddBullet();
            }
            Destroy(gameObject);
        }
    }
}
