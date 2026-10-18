using UnityEngine;

public class EnemyController : MonoBehaviour
{
    public float speed = 3f;

    [Tooltip("Oyuncudan bu mesafeden fazla uzaklaşan düşman silinir")]
    public float despawnDistance = 30f;

    // Aynı karede birden fazla mermi çarparsa ödülün tek kez verilmesi için
    [HideInInspector] public bool isDead = false;

    private Transform playerTransform;
    private Rigidbody2D rb2d;

    void Start()
    {
        rb2d = GetComponent<Rigidbody2D>();

        PlayerController player = FindAnyObjectByType<PlayerController>();
        if (player != null)
        {
            playerTransform = player.transform;
        }
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
