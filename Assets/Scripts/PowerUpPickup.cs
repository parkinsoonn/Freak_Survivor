using UnityEngine;

public enum PowerUpType { MultiShot, Magnet, Saber }

// Düşmanlardan düşen item'lar; etkisi oyuncu ölene kadar kalır
public class PowerUpPickup : MonoBehaviour
{
    public PowerUpType type = PowerUpType.MultiShot;

    void OnTriggerEnter2D(Collider2D hitInfo)
    {
        if (!hitInfo.CompareTag("Player")) return;

        PlayerController player = hitInfo.GetComponent<PlayerController>();
        if (player != null)
        {
            switch (type)
            {
                case PowerUpType.MultiShot:
                    player.AddBullet();
                    break;
                case PowerUpType.Magnet:
                    foreach (XPCrystal crystal in FindObjectsByType<XPCrystal>())
                    {
                        crystal.Attract(player.transform);
                    }
                    break;
                case PowerUpType.Saber:
                    SaberOrbit orbit = player.GetComponent<SaberOrbit>();
                    if (orbit != null) orbit.AddSaber();
                    break;
            }
        }
        Destroy(gameObject);
    }
}
