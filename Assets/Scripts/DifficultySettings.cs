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

    public static float EnemySpeedMultiplier => Pick(0.85f, 1.1f, 1.4f);

    // Başlangıç ve minimum spawn aralığına uygulanır (küçük = daha sık düşman)
    public static float SpawnIntervalMultiplier => Pick(1.2f, 0.85f, 0.6f);

    public static float RampRateMultiplier => Pick(0.8f, 1.25f, 1.8f);

    public static float MultiShotDropChance => Pick(0.03f, 0.02f, 0.01f);

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
