using UnityEngine;

public class EnemySpawner : MonoBehaviour
{
    public GameObject[] enemyPrefabs;

    [Header("Zorluk Ayarları")]
    public float spawnInterval = 2f;
    public float minSpawnInterval = 0.4f;
    public float spawnRadius = 15f;

    [Header("Mini Boss")]
    public GameObject miniBossPrefab;
    public float miniBossInterval = 60f;

    private float timer = 0f;
    private float bossTimer = 0f;
    private Transform player;
    private float startInterval;

    void Start()
    {
        GameObject playerObject = GameObject.FindGameObjectWithTag("Player");
        if (playerObject != null) player = playerObject.transform;

        // Seçilen zorluğa göre spawn sıklığını ölçekle
        startInterval = spawnInterval * DifficultySettings.StartIntervalMultiplier;
        minSpawnInterval *= DifficultySettings.MinIntervalMultiplier;
    }

    void Update()
    {
        // Oyun zamanı ilerledikçe (pause hariç) spawn aralığı minimuma doğru daralır
        spawnInterval = Mathf.Lerp(startInterval, minSpawnInterval, Time.timeSinceLevelLoad / DifficultySettings.RampDuration);

        timer += Time.deltaTime;
        if (timer >= spawnInterval)
        {
            SpawnEnemy();
            timer = 0f;
        }

        bossTimer += Time.deltaTime;
        if (bossTimer >= miniBossInterval)
        {
            Spawn(miniBossPrefab);
            bossTimer = 0f;
        }
    }

    void SpawnEnemy()
    {
        if (enemyPrefabs == null || enemyPrefabs.Length == 0) return;

        int randomEnemyIndex = Random.Range(0, enemyPrefabs.Length);
        Spawn(enemyPrefabs[randomEnemyIndex]);
    }

    void Spawn(GameObject prefab)
    {
        if (player == null || prefab == null) return;

        Vector2 randomDirection = Random.insideUnitCircle.normalized;
        Vector2 spawnPosition = (Vector2)player.position + (randomDirection * spawnRadius);

        Instantiate(prefab, spawnPosition, Quaternion.identity);
    }
}
