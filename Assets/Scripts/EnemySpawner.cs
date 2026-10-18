using UnityEngine;

public class EnemySpawner : MonoBehaviour
{
    public GameObject[] enemyPrefabs;

    [Header("Zorluk Ayarları")]
    public float spawnInterval = 2f;         
    public float minSpawnInterval = 0.4f;    
    public float difficultyRampRate = 0.02f; 
    public float spawnRadius = 15f;

    private float timer = 0f;
    private Transform player;

    void Start()
    {
        GameObject playerObject = GameObject.FindGameObjectWithTag("Player");
        if (playerObject != null) player = playerObject.transform;

        // Seçilen zorluğa göre spawn sıklığını ölçekle
        spawnInterval *= DifficultySettings.SpawnIntervalMultiplier;
        minSpawnInterval *= DifficultySettings.SpawnIntervalMultiplier;
        difficultyRampRate *= DifficultySettings.RampRateMultiplier;
    }

    void Update()
    {
        
        spawnInterval = Mathf.Max(minSpawnInterval, spawnInterval - difficultyRampRate * Time.deltaTime);

        timer += Time.deltaTime;
        if (timer >= spawnInterval)
        {
            SpawnEnemy();
            timer = 0f;
        }
    }

    void SpawnEnemy()
    {
        if (player == null || enemyPrefabs == null || enemyPrefabs.Length == 0) return;

        Vector2 randomDirection = Random.insideUnitCircle.normalized;
        Vector2 spawnPosition = (Vector2)player.position + (randomDirection * spawnRadius);

        int randomEnemyIndex = Random.Range(0, enemyPrefabs.Length);
        GameObject selectedEnemy = enemyPrefabs[randomEnemyIndex];

        Instantiate(selectedEnemy, spawnPosition, Quaternion.identity);
    }
}