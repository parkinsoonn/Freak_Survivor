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
        audioSource = GetComponent<AudioSource>();
    }

    void Update()
    {
        
        movement.x = Input.GetAxisRaw("Horizontal");
        movement.y = Input.GetAxisRaw("Vertical");

        if (cam != null)
        {
            mousePos = cam.ScreenToWorldPoint(Input.mousePosition);
        }

        if (Input.GetButton("Fire1") && Time.time >= nextFireTime)
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

        
        Vector2 lookDir = mousePos - rb2d.position;
        
        float angle = Mathf.Atan2(lookDir.y, lookDir.x) * Mathf.Rad2Deg + 90f;
        rb2d.rotation = angle;
    }

    void FixedUpdate()
    {
        
        if (!isDashing)
        {
            rb2d.linearVelocity = movement.normalized * moveSpeed;
        }
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

        rb2d.linearVelocity = dashDirection * dashSpeed;
        yield return new WaitForSeconds(dashDuration);

        if (playerHealth != null) playerHealth.isInvincible = false;
        isDashing = false;
        rb2d.linearVelocity = Vector2.zero;
    }

    public void IncreaseSpeed(float amount)
    {
        moveSpeed += amount;
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
    }

    void UpdateDashUI()
    {
        if (dashCooldownTimer > 0)
        {
            dashCooldownText.text = dashCooldownTimer.ToString("F1") + "s";
            dashIconImage.color = new Color(0.3f, 0.3f, 0.3f, 0.6f);
        }
        else
        {
            dashCooldownText.text = "READY";
            dashIconImage.color = Color.white;
        }
    }

    void Shoot()
    {
        if (bulletPrefab != null && firePoint != null)
        {
            Instantiate(bulletPrefab, firePoint.position, firePoint.rotation);

            
            if (shootSound != null && audioSource != null)
            {
                audioSource.PlayOneShot(shootSound, shootVolume);
            }
        }
    }
}