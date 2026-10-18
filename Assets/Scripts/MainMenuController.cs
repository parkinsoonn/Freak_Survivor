using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class MainMenuController : MonoBehaviour
{
    [Header("Ayarlar")]
    public Slider volumeSlider;

    private bool isMuted = false;
    private float lastVolume = 1f; 

    void Start()
    {
        float savedVolume = PlayerPrefs.GetFloat("GameVolume", 1f);
        AudioListener.volume = savedVolume;

        if (volumeSlider != null)
        {
            volumeSlider.value = savedVolume;
        }

        
        if (savedVolume == 0f) isMuted = true;
        else lastVolume = savedVolume;
    }

    public void SetVolume(float volume)
    {
        AudioListener.volume = volume;
        PlayerPrefs.SetFloat("GameVolume", volume);

        
        if (volume > 0f)
        {
            isMuted = false;
            lastVolume = volume;
        }
        else
        {
            isMuted = true;
        }
    }

    
    public void ToggleMute()
    {
        if (isMuted)
        {
            
            isMuted = false;
            AudioListener.volume = lastVolume;
            if (volumeSlider != null) volumeSlider.value = lastVolume;
        }
        else
        {
            
            isMuted = true;
            lastVolume = AudioListener.volume > 0f ? AudioListener.volume : 1f;
            AudioListener.volume = 0f;
            if (volumeSlider != null) volumeSlider.value = 0f;
        }

       
        PlayerPrefs.SetFloat("GameVolume", AudioListener.volume);
    }

    public void PlayGame()
    {
        Time.timeScale = 1f;
        PlayerPrefs.Save();
        SceneManager.LoadScene("Game");
    }

    public void QuitGame()
    {
        PlayerPrefs.Save();
        Application.Quit();

#if UNITY_EDITOR
        UnityEditor.EditorApplication.isPlaying = false;
#endif
    }
}