using UnityEngine;

// Dönen ışın kılıcı; her teması mermi gibi 1 vuruş sayılır
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
            gameManager.HitEnemy(hitInfo.GetComponent<EnemyController>());
        }
    }
}
