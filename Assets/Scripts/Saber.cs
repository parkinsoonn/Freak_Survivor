using UnityEngine;

// Dönen ışın kılıcı; değdiği düşmanı öldürür
public class Saber : MonoBehaviour
{
    private GameManager gameManager;

    void Start()
    {
        gameManager = FindAnyObjectByType<GameManager>();
    }

    void OnTriggerEnter2D(Collider2D hitInfo)
    {
        if (gameManager != null && hitInfo.CompareTag("Enemy"))
        {
            gameManager.KillEnemy(hitInfo.GetComponent<EnemyController>());
        }
    }
}
