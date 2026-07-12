using UnityEngine;
using UnityEngine.SceneManagement;
using TMPro;

public class GameManager : MonoBehaviour
{
    [Header("UI Panelleri")]
    public GameObject gameOverPanel;
    public GameObject pausePanel; // YENİ: Pause panelimizi atayacağımız boşluk
    public GameObject levelUpPanel; // YENİ: Seviye atlama panelimiz

    [Header("Skor Sistemi")]
    public int score = 0;
    public TextMeshProUGUI scoreText;

    [Header("Ses Ayarları")]
    public AudioClip gameOverSound;
    private AudioSource bgmSource;

    // Oyun durumunu kontrol eden kilitler
    private bool isPaused = false;
    private bool isGameOver = false;

    [Header("XP ve Seviye Sistemi")]
    public int mevcutXP = 0;
    public int mevcutSeviye = 1;
    public int sonrakiSeviyeIcinGerekenXP = 5; // İlk seviye için 5 XP yetsin

    public TextMeshProUGUI seviyeYazisi; // Ekranda LEVEL: 1 yazması için

    [Header("Seviye Atlama Sesleri")]
    public AudioClip levelUpSound; // Seviye atlandığında çalacak şatafatlı ses

    void Start()
    {
        Time.timeScale = 1f;
        UpdateScoreText();
        bgmSource = GetComponent<AudioSource>();

        // YENİ: Oyuna girerken kaydedilmiş ses ayarını hafızadan çek ve uygula
        AudioListener.volume = PlayerPrefs.GetFloat("GameVolume", 1f);

        UpdateSeviyeText();

    }

    void Update()
    {
        // YENİ: Eğer oyun bitmişse (Game Over), ESC tuşu hiçbir işe yaramasın
        if (isGameOver) return;

        // YENİ: ESC tuşuna basıldığını algıla
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

    // YENİ: Oyunu Duraklatma Fonksiyonu
    public void PauseGame()
    {
        pausePanel.SetActive(true);
        Time.timeScale = 0f;
        isPaused = true;

        if (bgmSource != null) bgmSource.Pause();

        // YENİ: ESC menüsü açıldığında UI yazılarını gizle
        if (scoreText != null) scoreText.gameObject.SetActive(false);
        if (seviyeYazisi != null) seviyeYazisi.gameObject.SetActive(false);

        // YENİ: Pause menüsü açıldığında Dash UI'ı gizle
        FindAnyObjectByType<PlayerController>().SetDashUIVisibility(false);
    }

    public void ResumeGame()
    {
        pausePanel.SetActive(false);
        Time.timeScale = 1f;
        isPaused = false;

        if (bgmSource != null) bgmSource.UnPause();

        // YENİ: Oyuna devam edildiğinde UI yazılarını tekrar görünür yap
        if (scoreText != null) scoreText.gameObject.SetActive(true);
        if (seviyeYazisi != null) seviyeYazisi.gameObject.SetActive(true);

        // YENİ: Oyuna dönüldüğünde Dash UI'ı tekrar göster
        FindAnyObjectByType<PlayerController>().SetDashUIVisibility(true);
    }

    // YENİ: Ana Menüye Dönme Fonksiyonu
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
        isGameOver = true;
        gameOverPanel.SetActive(true);

        // YENİ: Oyun bittiğinde hem Skoru hem de Level'ı gizle
        if (scoreText != null) scoreText.gameObject.SetActive(false);
        if (seviyeYazisi != null) seviyeYazisi.gameObject.SetActive(false);

        // YENİ: Oyun bittiğinde Dash UI'ı gizle
        FindAnyObjectByType<PlayerController>().SetDashUIVisibility(false);

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

    
    public void AddXP(int miktar)
    {
        mevcutXP += miktar;

        
        UpdateSeviyeText();

        
        if (mevcutXP >= sonrakiSeviyeIcinGerekenXP)
        {
            SeviyeAtla();
        }
    }

    void SeviyeAtla()
    {
        
        mevcutXP -= sonrakiSeviyeIcinGerekenXP;
        mevcutSeviye++;
        sonrakiSeviyeIcinGerekenXP = mevcutSeviye * 5;

        UpdateSeviyeText();

        if (levelUpPanel != null)
        {
            levelUpPanel.SetActive(true);

            if (scoreText != null) scoreText.gameObject.SetActive(false);
            if (seviyeYazisi != null) seviyeYazisi.gameObject.SetActive(false);

            
            FindAnyObjectByType<PlayerController>().SetDashUIVisibility(false);

            
            if (bgmSource != null)
            {
                bgmSource.Pause(); 
            }

            if (levelUpSound != null)
            {
                
                AudioSource.PlayClipAtPoint(levelUpSound, Camera.main.transform.position);
            }

            Time.timeScale = 0f; 
        }
    }

    
    int comboHesapla()
    {
        return sonrakiSeviyeIcinGerekenXP;
    }

    void UpdateSeviyeText()
    {
        if (seviyeYazisi != null)
        {
            seviyeYazisi.text = "LEVEL: " + mevcutSeviye.ToString() + " (XP: " + mevcutXP + "/" + sonrakiSeviyeIcinGerekenXP + ")";
        }
    }

    
    public void ChooseSpeedUpgrade()
    {
        
        FindAnyObjectByType<PlayerController>().IncreaseSpeed(1f);
        ResumeAfterUpgrade();
    }

    
    public void ChooseFireRateUpgrade()
    {

        FindAnyObjectByType<PlayerController>().IncreaseFireRate(0.03f);
        ResumeAfterUpgrade();
    }

    
    public void ChooseHealUpgrade()
    {
        FindAnyObjectByType<PlayerHealth>().HealPlayer();

        ResumeAfterUpgrade();
    }

    
    void ResumeAfterUpgrade()
    {
        levelUpPanel.SetActive(false);

        if (scoreText != null) scoreText.gameObject.SetActive(true);
        if (seviyeYazisi != null) seviyeYazisi.gameObject.SetActive(true);

        
        FindAnyObjectByType<PlayerController>().SetDashUIVisibility(true);

        
        if (bgmSource != null)
        {
            bgmSource.UnPause();
        }

        Time.timeScale = 1f;
    }
}