using UnityEngine;
using UnityEngine.UI;

public class PlayerHealth : MonoBehaviour
{
    public int maxHealth = 4;
    public int currentHealth;

    [Tooltip("Hasar aldıktan sonra tekrar hasar alınmayan süre (saniye)")]
    public float hitInvincibilityDuration = 0.5f;
    private float invincibleUntil = 0f;

    [Header("UI Ayarları")]
    public Image healthBarImage;
    public Sprite[] healthSprites;

    [HideInInspector] public bool isInvincible = false;

    private GameManager gameManager;

    void Start()
    {
        currentHealth = maxHealth;
        UpdateHealthUI();

        gameManager = FindAnyObjectByType<GameManager>();
    }

    // Stay: düşman oyuncuya yapışık kaldıkça (i-frame bitince) hasar vermeye devam etsin
    void OnCollisionEnter2D(Collision2D collision) => HandleEnemyContact(collision);
    void OnCollisionStay2D(Collision2D collision) => HandleEnemyContact(collision);

    void HandleEnemyContact(Collision2D collision)
    {
        if (collision.gameObject.CompareTag("Enemy"))
        {
            TakeDamage(1);
        }
    }

    public void TakeDamage(int damageAmount)
    {
        if (isInvincible || currentHealth <= 0 || Time.time < invincibleUntil) return;

        invincibleUntil = Time.time + hitInvincibilityDuration;

        currentHealth -= damageAmount;
        currentHealth = Mathf.Clamp(currentHealth, 0, maxHealth);
        UpdateHealthUI();

        if (currentHealth <= 0)
        {
            if (gameManager != null)
            {
                gameManager.ShowGameOver();
            }
            Die();
        }
    }

    public void HealPlayer()
    {
        currentHealth = maxHealth;
        UpdateHealthUI();
    }

    void UpdateHealthUI()
    {
        if (healthBarImage != null && healthSprites != null && currentHealth < healthSprites.Length)
        {
            healthBarImage.sprite = healthSprites[currentHealth];
        }
    }

    void Die()
    {
        // Oyuncu kontrolünü kapat ve yerinde durdur
        PlayerController controller = GetComponent<PlayerController>();
        if (controller != null) controller.enabled = false;

        Rigidbody2D rb2d = GetComponent<Rigidbody2D>();
        if (rb2d != null) rb2d.linearVelocity = Vector2.zero;
    }
}
