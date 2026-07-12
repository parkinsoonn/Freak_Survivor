using UnityEngine;
using UnityEngine.UI;

public class PlayerHealth : MonoBehaviour
{
    public int maxHealth = 4;
    public int currentHealth;

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

    void OnCollisionEnter2D(Collision2D collision)
    {
        if (collision.gameObject.CompareTag("Enemy"))
        {
            TakeDamage(1);
        }
    }

    public void TakeDamage(int damageAmount)
    {
        if (isInvincible) return;

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
        
    }
}