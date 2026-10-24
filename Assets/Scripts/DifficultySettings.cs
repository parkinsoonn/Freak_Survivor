using UnityEngine;

public enum Difficulty { Easy, Normal, Hard }

// Ana menüde seçilen zorluk; inspector değerleri temel kabul edilip bu çarpanlarla ölçeklenir
public static class DifficultySettings
{
    private const string PrefsKey = "Difficulty";

    public static Difficulty Current
    {
        get { return (Difficulty)Mathf.Clamp(PlayerPrefs.GetInt(PrefsKey, (int)Difficulty.Normal), 0, 2); }
        set { PlayerPrefs.SetInt(PrefsKey, (int)value); }
    }

    public static string DisplayName(Difficulty difficulty)
    {
        switch (difficulty)
        {
            case Difficulty.Easy: return "KOLAY";
            case Difficulty.Hard: return "ZOR";
            default: return "NORMAL";
        }
    }

    // Oyun başındaki düşman hızı; zamanla SpeedGrowthPerMinute kadar artar (MaxSpeedBonus'a kadar)
    public static float EnemySpeedMultiplier => Pick(0.85f, 1.05f, 1.15f);
    public static float SpeedGrowthPerMinute => Pick(0.05f, 0.1f, 0.15f);
    public static float MaxSpeedBonus => Pick(0.25f, 0.5f, 0.6f);

    // Spawn aralığı başlangıçtan minimuma RampDuration saniyede iner (küçük = daha sık düşman)
    public static float StartIntervalMultiplier => Pick(1.4f, 1.15f, 1f);
    public static float MinIntervalMultiplier => Pick(1.3f, 1f, 0.7f);
    public static float RampDuration => Pick(300f, 180f, 120f);

    public static float MultiShotDropChance => Pick(0.03f, 0.02f, 0.01f);

    public static float MagnetDropChance => Pick(0.0225f, 0.015f, 0.0075f);

    public static float SaberDropChance => Pick(0.015f, 0.01f, 0.005f);

    private static float Pick(float easy, float normal, float hard)
    {
        switch (Current)
        {
            case Difficulty.Easy: return easy;
            case Difficulty.Hard: return hard;
            default: return normal;
        }
    }
}
