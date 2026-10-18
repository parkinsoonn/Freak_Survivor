using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.Serialization;
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

    private PlayerController playerController;
    private PlayerHealth playerHealth;

    void Start()
    {
        Time.timeScale = 1f;
        UpdateScoreText();
        bgmSource = GetComponent<AudioSource>();

        playerController = FindAnyObjectByType<PlayerController>();
        playerHealth = FindAnyObjectByType<PlayerHealth>();

        // Oyuna girerken kaydedilmiş ses ayarını hafızadan çek ve uygula
        AudioListener.volume = PlayerPrefs.GetFloat("GameVolume", 1f);

        UpdateLevelText();
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

        if (bgmSource != null) bgmSource.UnPause();

        // Oyuna devam edildiğinde HUD'u tekrar görünür yap
        SetHUDVisibility(true);
    }

    // Ana Menüye Dönme Fonksiyonu
    public void LoadMainMenu()
    {
        Time.timeScale = 1f; // ÇOK ÖNEMLİ: Zamanı normale döndürmezsek ana menü de donuk kalır!
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

    public void AddXP(int amount)
    {
        currentXP += amount;

        UpdateLevelText();

        if (currentXP >= xpToNextLevel)
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
        if (playerController != null) playerController.IncreaseFireRate(0.03f);
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
    }

    // Skor, Level ve Dash UI'ını birlikte gösterip gizler
    void SetHUDVisibility(bool isVisible)
    {
        if (scoreText != null) scoreText.gameObject.SetActive(isVisible);
        if (levelText != null) levelText.gameObject.SetActive(isVisible);
        if (playerController != null) playerController.SetDashUIVisibility(isVisible);
    }
}
