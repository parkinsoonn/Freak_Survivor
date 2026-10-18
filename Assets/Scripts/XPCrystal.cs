using UnityEngine;
using UnityEngine.Serialization;

public class XPCrystal : MonoBehaviour
{
    [FormerlySerializedAs("xpDegeri")] public int xpValue = 1;
    private GameManager gameManager;

    void Start()
    {
        gameManager = FindAnyObjectByType<GameManager>();
    }

    void OnTriggerEnter2D(Collider2D hitInfo)
    {
        if (hitInfo.CompareTag("Player"))
        {
            if (gameManager != null)
            {
                gameManager.AddXP(xpValue);
            }
            Destroy(gameObject);
        }
    }
}
