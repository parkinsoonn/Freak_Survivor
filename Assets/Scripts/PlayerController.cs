using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using TMPro;

public class PlayerController : MonoBehaviour
{
    [Header("Hareket Ayarları")]
    public float moveSpeed = 5f;
    private Vector2 movement;
    private Vector2 mousePos;

    [Header("Ateş Etme Ayarları")]
    public float fireRate = 0.5f;
    private float nextFireTime = 0f;
    // Oyun durduğunda (menü butonuna tıklarken) basılı tutulan tık, bırakılana kadar ateş etmesin
    private bool fireLocked = false;

    [Header("Çoklu Atış")]
    public int bulletCount = 1;
    public float spreadAngle = 10f; // Mermiler arası açı
    public float maxSpreadAngle = 60f; // Yelpazenin toplam genişliği bunu geçmez

    public GameObject bulletPrefab;
    public Transform firePoint;
    public AudioClip shootSound;

    [Range(0f, 1f)] public float shootVolume = 0.5f;

    [Header("Dash Ayarları")]
    public float dashSpeed = 18f;
    public float dashDuration = 0.2f;
    public float dashCooldown = 1.5f;
    private bool isDashing = false;
    private float dashCooldownTimer = 0f;

    [Header("Dash UI Ayarları")]
    public Image dashIconImage;
    public TextMeshProUGUI dashCooldownText;
    public TrailRenderer dashTrail;

    [Header("Atom Bombası")]
    public float nukeCooldown = 60f;
    private float nukeCooldownTimer = 0f;
    public Image nukeIconImage;
    public TextMeshProUGUI nukeCooldownText;
    public Image nukeFlashImage; // Tam ekran beyaz flaş
    public GameObject nukeEffect;
    public AudioClip nukeSound;

    private GameManager gameManager;
    private CameraController cameraController;

    private Rigidbody2D rb2d;
    private PlayerHealth playerHealth;
    private Camera cam;

    private AudioSource audioSource;

    void Start()
    {
        rb2d = GetComponent<Rigidbody2D>();
        playerHealth = GetComponent<PlayerHealth>();
        cam = Camera.main;

        if (dashCooldownText != null) dashCooldownText.text = "";
        if (nukeCooldownText != null) nukeCooldownText.text = "";
        if (dashTrail != null) dashTrail.emitting = false;
        audioSource = GetComponent<AudioSource>();

        gameManager = FindAnyObjectByType<GameManager>();
        cameraController = FindAnyObjectByType<CameraController>();
    }

    void Update()
    {
        // Pause, seviye atlama ve Game Over ekranlarında oyuncu girdisi işlenmesin
        if (Time.timeScale == 0f)
        {
            fireLocked = true;
            return;
        }

        movement.x = Input.GetAxisRaw("Horizontal");
        movement.y = Input.GetAxisRaw("Vertical");

        if (cam != null)
        {
            mousePos = cam.ScreenToWorldPoint(Input.mousePosition);
        }

        bool fireHeld = Input.GetButton("Fire1");
        if (!fireHeld) fireLocked = false;

        if (fireHeld && !fireLocked && Time.time >= nextFireTime)
        {
            Shoot();
            nextFireTime = Time.time + fireRate;
        }

        if (dashCooldownTimer > 0)
        {
            dashCooldownTimer -= Time.deltaTime;
            UpdateDashUI();
        }

        if (Input.GetKeyDown(KeyCode.LeftShift) && !isDashing && dashCooldownTimer <= 0)
        {
            StartCoroutine(PerformDash());
        }

        if (nukeCooldownTimer > 0)
        {
            nukeCooldownTimer -= Time.deltaTime;
            UpdateCooldownUI(nukeCooldownTimer, nukeIconImage, nukeCooldownText);
        }

        if (Input.GetKeyDown(KeyCode.Q) && nukeCooldownTimer <= 0)
        {
            StartCoroutine(PerformNuke());
        }
    }

    void FixedUpdate()
    {
        if (!isDashing)
        {
            rb2d.linearVelocity = movement.normalized * moveSpeed;
        }

        Vector2 lookDir = mousePos - rb2d.position;
        float angle = Mathf.Atan2(lookDir.y, lookDir.x) * Mathf.Rad2Deg + 90f;
        rb2d.MoveRotation(angle);
    }

    IEnumerator PerformDash()
    {
        isDashing = true;
        dashCooldownTimer = dashCooldown;

        if (playerHealth != null) playerHealth.isInvincible = true;

        Vector2 dashDirection = movement.normalized;
        if (dashDirection == Vector2.zero)
        {
            dashDirection = transform.up;
        }

        if (dashTrail != null) dashTrail.emitting = true;

        // Hız dash boyunca yüksek kalır, sadece sonda yürüme hızına yumuşakça iner (ani durma yok)
        for (float t = 0f; t < dashDuration; t += Time.fixedDeltaTime)
        {
            float eased = Mathf.Pow(t / dashDuration, 3f);
            rb2d.linearVelocity = dashDirection * Mathf.Lerp(dashSpeed, moveSpeed, eased);
            yield return new WaitForFixedUpdate();
        }

        if (playerHealth != null) playerHealth.isInvincible = false;
        if (dashTrail != null) dashTrail.emitting = false;
        isDashing = false;
    }

    IEnumerator PerformNuke()
    {
        nukeCooldownTimer = nukeCooldown;

        if (gameManager != null)
        {
            foreach (EnemyController enemy in FindObjectsByType<EnemyController>())
            {
                gameManager.KillEnemy(enemy, false);
            }
        }

        // Tek tek ses/sarsıntı yerine tek büyük patlama
        if (cameraController != null) cameraController.TriggerShake(0.5f, 0.6f);
        if (nukeSound != null) AudioSource.PlayClipAtPoint(nukeSound, transform.position);
        if (nukeEffect != null)
        {
            GameObject fx = Instantiate(nukeEffect, new Vector3(transform.position.x, transform.position.y, -1f), Quaternion.identity);
            fx.transform.localScale *= 4f;
        }

        if (nukeFlashImage == null) yield break;

        nukeFlashImage.gameObject.SetActive(true);
        for (float t = 0f; t < 0.6f; t += Time.deltaTime)
        {
            nukeFlashImage.color = new Color(1f, 1f, 1f, 1f - t / 0.6f);
            yield return null;
        }
        nukeFlashImage.gameObject.SetActive(false);
    }

    public void IncreaseSpeed(float amount)
    {
        moveSpeed += amount;
    }

    public void AddBullet()
    {
        bulletCount++;
    }

    public void IncreaseFireRate(float amount)
    {
        fireRate -= amount;
        if (fireRate < 0.1f) fireRate = 0.1f;
    }

    public void SetDashUIVisibility(bool isVisible)
    {
        if (dashIconImage != null) dashIconImage.gameObject.SetActive(isVisible);
        if (dashCooldownText != null) dashCooldownText.gameObject.SetActive(isVisible);
        if (nukeIconImage != null) nukeIconImage.gameObject.SetActive(isVisible);
        if (nukeCooldownText != null) nukeCooldownText.gameObject.SetActive(isVisible);
    }

    void UpdateDashUI()
    {
        UpdateCooldownUI(dashCooldownTimer, dashIconImage, dashCooldownText);
    }

    void UpdateCooldownUI(float timer, Image icon, TextMeshProUGUI text)
    {
        bool onCooldown = timer > 0;

        if (text != null)
        {
            text.text = onCooldown ? timer.ToString("F1") + "s" : "READY";
        }

        if (icon != null)
        {
            icon.color = onCooldown ? new Color(0.3f, 0.3f, 0.3f, 0.6f) : Color.white;
        }
    }

    void Shoot()
    {
        if (bulletPrefab != null && firePoint != null)
        {
            // Mermi sayısı arttıkça aralarındaki açı daralır, yelpaze maxSpreadAngle'ı geçmez
            float step = bulletCount > 1 ? Mathf.Min(spreadAngle, maxSpreadAngle / (bulletCount - 1)) : 0f;
            for (int i = 0; i < bulletCount; i++)
            {
                float offset = (i - (bulletCount - 1) / 2f) * step;
                Instantiate(bulletPrefab, firePoint.position, firePoint.rotation * Quaternion.Euler(0f, 0f, offset));
            }

            if (shootSound != null && audioSource != null)
            {
                audioSource.PlayOneShot(shootSound, shootVolume);
            }
        }
    }
}
