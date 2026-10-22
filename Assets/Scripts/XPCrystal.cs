using UnityEngine;
using UnityEngine.Serialization;

public class XPCrystal : MonoBehaviour
{
    [FormerlySerializedAs("xpDegeri")] public int xpValue = 1;
    private GameManager gameManager;

    // Mıknatıs alınınca oyuncuya doğru hızlanarak uçar; toplama yine OnTriggerEnter2D ile olur
    private Transform attractTarget;
    private float attractSpeed = 4f;

    void Start()
    {
        gameManager = FindAnyObjectByType<GameManager>();
    }

    public void Attract(Transform target)
    {
        attractTarget = target;
    }

    void Update()
    {
        if (attractTarget == null) return;

        attractSpeed += 30f * Time.deltaTime;
        transform.position = Vector3.MoveTowards(transform.position, attractTarget.position, attractSpeed * Time.deltaTime);
    }

    void OnTriggerEnter2D(Collider2D hitInfo)
    {
        if (hitInfo.CompareTag("Player"))
        {
            if (gameManager != null)
            {
                gameManager.AddXP(xpValue);
            }
            Destroy(gameObject);
        }
    }
}
