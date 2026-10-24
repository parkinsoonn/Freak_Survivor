using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.Serialization;
using UnityEngine.UI;
using TMPro;

public class GameManager : MonoBehaviour
{
    [Header("UI Panelleri")]
    public GameObject gameOverPanel;
    public GameObject pausePanel; // Pause panelimizi atayacağımız boşluk
    public GameObject levelUpPanel; // Seviye atlama panelimiz

    [Header("Skor Sistemi")]
    public int score = 0;
    public TextMeshProUGUI scoreText;

    [Header("ESC Menüsü")]
    public Slider volumeSlider;

    [Header("Ses Ayarları")]
    public AudioClip gameOverSound;
    private AudioSource bgmSource;

    // Oyun durumunu kontrol eden kilitler
    private bool isPaused = false;
    private bool isGameOver = false;
    private bool isLevelingUp = false;

    [Header("XP ve Seviye Sistemi")]
    [FormerlySerializedAs("mevcutXP")] public int currentXP = 0;
    [FormerlySerializedAs("mevcutSeviye")] public int currentLevel = 1;
    [FormerlySerializedAs("sonrakiSeviyeIcinGerekenXP")] public int xpToNextLevel = 5; // İlk seviye için 5 XP yetsin

    [FormerlySerializedAs("seviyeYazisi")] public TextMeshProUGUI levelText; // Ekranda LEVEL: 1 yazması için

    [Header("Seviye Atlama Sesleri")]
    public AudioClip levelUpSound; // Seviye atlandığında çalacak şatafatlı ses

    [Header("Düşman Ölümü ve Drop'lar")]
    public GameObject deathEffect;
    public AudioClip enemyDeathSound;
    public GameObject xpCrystalPrefab;
    public GameObject multiShotPickupPrefab;
    public GameObject magnetPickupPrefab;
    public GameObject saberPickupPrefab;

    [Header("İmleç")]
    public Texture2D crosshairCursor;

    private PlayerController playerController;
    private PlayerHealth playerHealth;
    private CameraController cameraController;
    private SaberOrbit saberOrbit;

    void Start()
    {
        Time.timeScale = 1f;
        UpdateScoreText();
        // Hotspot nişangahın ortası
        if (crosshairCursor != null) Cursor.SetCursor(crosshairCursor, new Vector2(crosshairCursor.width / 2, crosshairCursor.height / 2), CursorMode.Auto);
        bgmSource = GetComponent<AudioSource>();

        playerController = FindAnyObjectByType<PlayerController>();
        playerHealth = FindAnyObjectByType<PlayerHealth>();
        cameraController = FindAnyObjectByType<CameraController>();
        saberOrbit = FindAnyObjectByType<SaberOrbit>();

        if (bgmSource != null) bgmSource.loop = true; // Müzik hiç bitmesin

        // Oyuna girerken kaydedilmiş ses ayarını hafızadan çek ve uygula
        AudioListener.volume = PlayerPrefs.GetFloat("GameVolume", 1f);
        if (volumeSlider != null) volumeSlider.SetValueWithoutNotify(AudioListener.volume);

        UpdateLevelText();
    }

    // ESC menüsündeki ses slider'ı; ana menüyle aynı ayarı kullanır
    public void SetVolume(float volume)
    {
        AudioListener.volume = volume;
        PlayerPrefs.SetFloat("GameVolume", volume);
    }

    void Update()
    {
        // Oyun bitmişse ya da seviye atlama ekranı açıksa ESC hiçbir işe yaramasın
        if (isGameOver || isLevelingUp) return;

        if (Input.GetKeyDown(KeyCode.Escape))
        {
            if (isPaused)
            {
                ResumeGame(); // Açıksa kapat
            }
            else
            {
                PauseGame(); // Kapalıysa aç
            }
        }
    }

    // Oyunu Duraklatma Fonksiyonu
    public void PauseGame()
    {
        if (pausePanel != null) pausePanel.SetActive(true);
        Time.timeScale = 0f;
        isPaused = true;

        if (bgmSource != null) bgmSource.Pause();

        // ESC menüsü açıldığında HUD'u gizle
        SetHUDVisibility(false);
    }

    public void ResumeGame()
    {
        if (pausePanel != null) pausePanel.SetActive(false);
        Time.timeScale = 1f;
        isPaused = false;
        PlayerPrefs.Save();

        if (bgmSource != null) bgmSource.UnPause();

        // Oyuna devam edildiğinde HUD'u tekrar görünür yap
        SetHUDVisibility(true);
    }

    // Ana Menüye Dönme Fonksiyonu
    public void LoadMainMenu()
    {
        Time.timeScale = 1f; // ÇOK ÖNEMLİ: Zamanı normale döndürmezsek ana menü de donuk kalır!
        PlayerPrefs.Save();
        Cursor.SetCursor(null, Vector2.zero, CursorMode.Auto); // Ana menüde normal imleç
        SceneManager.LoadScene("MainMenu"); // Ana menü sahnesini yükle
    }

    public void AddScore(int points)
    {
        score += points;
        UpdateScoreText();
    }

    void UpdateScoreText()
    {
        if (scoreText != null)
        {
            scoreText.text = "SCORE: " + score.ToString();
        }
    }

    public void ShowGameOver()
    {
        if (isGameOver) return;

        isGameOver = true;
        if (gameOverPanel != null) gameOverPanel.SetActive(true);

        // Oyun bittiğinde Skor, Level ve Dash UI'ı gizle
        SetHUDVisibility(false);

        if (bgmSource != null)
        {
            bgmSource.Stop();
            if (gameOverSound != null)
            {
                bgmSource.PlayOneShot(gameOverSound);
            }
        }

        Time.timeScale = 0f;
    }

    public void RestartGame()
    {
        Time.timeScale = 1f;
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
    }

    // Mermi ve kılıç isabeti: canı 1 azaltır, bittiyse öldürür. Düşman zaten öldüyse false döner.
    public bool HitEnemy(EnemyController enemy)
    {
        if (enemy == null || enemy.isDead) return false;
        if (enemy.TakeHit()) KillEnemy(enemy);
        return true;
    }

    // Mermi, kılıç ve bombanın ortak öldürme yolu. Düşman zaten öldüyse false döner.
    public bool KillEnemy(EnemyController enemy, bool feedback = true)
    {
        if (enemy == null || enemy.isDead) return false;
        enemy.isDead = true;

        Vector3 position = enemy.transform.position;
        AddScore(10);

        if (feedback)
        {
            if (cameraController != null) cameraController.TriggerShake(0.08f, 0.08f);
            if (enemyDeathSound != null) AudioSource.PlayClipAtPoint(enemyDeathSound, position);
        }

        if (xpCrystalPrefab != null) Instantiate(xpCrystalPrefab, position, Quaternion.identity).GetComponent<XPCrystal>().xpValue = enemy.xpReward;

        TryDrop(multiShotPickupPrefab, DifficultySettings.MultiShotDropChance, position);
        TryDrop(magnetPickupPrefab, DifficultySettings.MagnetDropChance, position);
        // Kılıçlar doluysa (3) kılıç item'ı artık düşmesin
        if (saberOrbit == null || !saberOrbit.IsFull) TryDrop(saberPickupPrefab, DifficultySettings.SaberDropChance, position);

        if (deathEffect != null) Instantiate(deathEffect, new Vector3(position.x, position.y, -1f), Quaternion.identity);

        Destroy(enemy.gameObject);
        return true;
    }

    void TryDrop(GameObject prefab, float chance, Vector3 position)
    {
        if (prefab == null || Random.value >= chance) return;
        // XP kristaliyle üst üste binmesin diye biraz kaydır
        Instantiate(prefab, position + (Vector3)(Random.insideUnitCircle.normalized * 0.5f), Quaternion.identity);
    }

    public void AddXP(int amount)
    {
        currentXP += amount;

        UpdateLevelText();

        // Seviye ekranı açıkken gelen XP birikir; seçim yapılınca ResumeAfterUpgrade tekrar kontrol eder
        if (!isLevelingUp && currentXP >= xpToNextLevel)
        {
            LevelUp();
        }
    }

    void LevelUp()
    {
        currentXP -= xpToNextLevel;
        currentLevel++;
        xpToNextLevel = currentLevel * 5;

        UpdateLevelText();

        if (levelUpPanel != null)
        {
            isLevelingUp = true;
            levelUpPanel.SetActive(true);

            SetHUDVisibility(false);

            if (bgmSource != null)
            {
                bgmSource.Pause();
            }

            if (levelUpSound != null && Camera.main != null)
            {
                AudioSource.PlayClipAtPoint(levelUpSound, Camera.main.transform.position);
            }

            Time.timeScale = 0f;
        }
    }

    void UpdateLevelText()
    {
        if (levelText != null)
        {
            levelText.text = "LEVEL: " + currentLevel.ToString() + " (XP: " + currentXP + "/" + xpToNextLevel + ")";
        }
    }

    public void ChooseSpeedUpgrade()
    {
        if (playerController != null) playerController.IncreaseSpeed(1f);
        ResumeAfterUpgrade();
    }

    public void ChooseFireRateUpgrade()
    {
        if (playerController != null) playerController.IncreaseFireRate(0.015f);
        ResumeAfterUpgrade();
    }

    public void ChooseHealUpgrade()
    {
        if (playerHealth != null) playerHealth.HealPlayer();
        ResumeAfterUpgrade();
    }

    void ResumeAfterUpgrade()
    {
        isLevelingUp = false;
        if (levelUpPanel != null) levelUpPanel.SetActive(false);

        SetHUDVisibility(true);

        if (bgmSource != null)
        {
            bgmSource.UnPause();
        }

        Time.timeScale = 1f;

        if (currentXP >= xpToNextLevel) LevelUp();
    }

    // Skor, Level ve Dash UI'ını birlikte gösterip gizler
    void SetHUDVisibility(bool isVisible)
    {
        if (scoreText != null) scoreText.gameObject.SetActive(isVisible);
        if (levelText != null) levelText.gameObject.SetActive(isVisible);
        if (playerController != null) playerController.SetDashUIVisibility(isVisible);
    }
}
