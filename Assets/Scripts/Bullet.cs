using UnityEngine;

public class Bullet : MonoBehaviour
{
    public GameObject deathEffect;
    public AudioClip enemyDeathSound;
    private bool hasHit = false;

    private GameManager gameManager;
    private CameraController cameraController;

    [Header("XP Ayarı")]
    public GameObject xpKristalPrefab;

    [Header("Ayarlar")]
    public float speed = 20f; // YENİ: Merminin uçuş hızı
    private Rigidbody2D rb2d; // YENİ: Fizik motoru referansı



    void Start()
    {
        
        rb2d = GetComponent<Rigidbody2D>();

        
        rb2d.linearVelocity = transform.up * speed;

        
        gameManager = FindAnyObjectByType<GameManager>();
        cameraController = FindAnyObjectByType<CameraController>();
        Destroy(gameObject, 3f);
    }

    void OnTriggerEnter2D(Collider2D hitInfo)
    {
        if (hitInfo.CompareTag("Enemy") && !hasHit)
        {
            hasHit = true;

            
            if (gameManager != null)
            {
                gameManager.AddScore(10);
            }

            if (cameraController != null)
            {
                cameraController.TriggerShake(0.1f, 0.2f);
            }

            
            if (enemyDeathSound != null)
            {
                AudioSource.PlayClipAtPoint(enemyDeathSound, hitInfo.transform.position);
            }

            if (xpKristalPrefab != null)
            {
                Instantiate(xpKristalPrefab, hitInfo.transform.position, Quaternion.identity);
            }

            if (deathEffect != null)
            {
                Vector3 fxPosition = new Vector3(hitInfo.transform.position.x, hitInfo.transform.position.y, -1f);
                Instantiate(deathEffect, fxPosition, Quaternion.identity);
            }

            Destroy(hitInfo.gameObject);
            Destroy(gameObject);
        }
    }
}