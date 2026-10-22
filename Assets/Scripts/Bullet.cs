using UnityEngine;

public class Bullet : MonoBehaviour
{
    private bool hasHit = false;
    private GameManager gameManager;

    [Header("Ayarlar")]
    public float speed = 20f; // Merminin uçuş hızı
    private Rigidbody2D rb2d;

    void Start()
    {
        rb2d = GetComponent<Rigidbody2D>();
        rb2d.linearVelocity = transform.up * speed;

        gameManager = FindAnyObjectByType<GameManager>();
        Destroy(gameObject, 3f);
    }

    void OnTriggerEnter2D(Collider2D hitInfo)
    {
        if (hasHit || gameManager == null || !hitInfo.CompareTag("Enemy")) return;

        // Bu düşmanı aynı karede başka bir mermi zaten öldürdüyse mermi boşa harcanmasın
        if (gameManager.KillEnemy(hitInfo.GetComponent<EnemyController>()))
        {
            hasHit = true;
            Destroy(gameObject);
        }
    }
}
