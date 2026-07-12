using UnityEngine;

public class XPKristali : MonoBehaviour
{
    public int xpDegeri = 1; 
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
                gameManager.AddXP(xpDegeri);
            }
            Destroy(gameObject);
        }
    }
}
        
