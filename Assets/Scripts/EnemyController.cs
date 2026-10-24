using UnityEngine;

public class EnemyController : MonoBehaviour
{
    public float speed = 3f;

    [Tooltip("Oyuncudan bu mesafeden fazla uzaklaşan düşman silinir")]
    public float despawnDistance = 30f;

    [Tooltip("Ölmesi için gereken mermi sayısı")]
    public int health = 1;

    [Tooltip("Ölünce düşen XP kristalinin değeri")]
    public int xpReward = 1;

    // Aynı karede birden fazla mermi çarparsa ödülün tek kez verilmesi için
    [HideInInspector] public bool isDead = false;

    private Transform playerTransform;
    private Rigidbody2D rb2d;
    private SpriteRenderer spriteRenderer;

    void Start()
    {
        rb2d = GetComponent<Rigidbody2D>();
        spriteRenderer = GetComponent<SpriteRenderer>();

        // Zorluk çarpanı + oyun ilerledikçe artan hız bonusu
        float minutes = Time.timeSinceLevelLoad / 60f;
        float timeBonus = Mathf.Min(DifficultySettings.MaxSpeedBonus, DifficultySettings.SpeedGrowthPerMinute * minutes);
        speed *= DifficultySettings.EnemySpeedMultiplier * (1f + timeBonus);

        PlayerController player = FindAnyObjectByType<PlayerController>();
        if (player != null)
        {
            playerTransform = player.transform;
        }
    }

    // Mermi isabeti: canı 1 azaltır, ölmediyse kısa kırmızı yanıp sönme; öldüyse true döner
    public bool TakeHit()
    {
        health--;
        if (health > 0)
        {
            if (spriteRenderer != null) StartCoroutine(HitFlash());
            return false;
        }
        return true;
    }

    System.Collections.IEnumerator HitFlash()
    {
        spriteRenderer.color = new Color(1f, 0.4f, 0.4f);
        yield return new WaitForSeconds(0.1f);
        spriteRenderer.color = Color.white;
    }

    void FixedUpdate()
    {
        if (playerTransform != null)
        {
            Vector2 toPlayer = (Vector2)playerTransform.position - rb2d.position;

            if (toPlayer.sqrMagnitude > despawnDistance * despawnDistance)
            {
                Destroy(gameObject);
                return;
            }

            Vector2 direction = toPlayer.normalized;
            rb2d.linearVelocity = direction * speed;

            float angle = Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg + 90f;
            rb2d.rotation = angle;
        }
    }
}
