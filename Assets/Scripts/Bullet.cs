using UnityEngine;
using UnityEngine.Serialization;

public class Bullet : MonoBehaviour
{
    public GameObject deathEffect;
    public AudioClip enemyDeathSound;
    private bool hasHit = false;

    private GameManager gameManager;
    private CameraController cameraController;

    [Header("XP Ayarı")]
    [FormerlySerializedAs("xpKristalPrefab")] public GameObject xpCrystalPrefab;

    [Header("Ayarlar")]
    public float speed = 20f; // Merminin uçuş hızı
    private Rigidbody2D rb2d;

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
        if (hasHit || !hitInfo.CompareTag("Enemy")) return;

        // Bu düşmanı aynı karede başka bir mermi zaten öldürdüyse ödülü tekrar verme
        EnemyController enemy = hitInfo.GetComponent<EnemyController>();
        if (enemy != null)
        {
            if (enemy.isDead) return;
            enemy.isDead = true;
        }

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

        if (xpCrystalPrefab != null)
        {
            Instantiate(xpCrystalPrefab, hitInfo.transform.position, Quaternion.identity);
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
