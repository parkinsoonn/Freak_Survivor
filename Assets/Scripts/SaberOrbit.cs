using System.Collections.Generic;
using UnityEngine;

// Toplanan her ışın kılıcı oyuncunun etrafında eşit aralıklarla döner
public class SaberOrbit : MonoBehaviour
{
    public GameObject saberPrefab;
    public float radius = 1.5f;
    public float rotateSpeed = 220f; // derece/sn
    public int maxSabers = 3;

    // Oyuncu fareye döndüğü için kılıçlar onun çocuğu değil, ayrı bir pivotun çocuğu
    private Transform pivot;
    private readonly List<Transform> sabers = new List<Transform>();

    public bool IsFull => sabers.Count >= maxSabers;

    public void AddSaber()
    {
        if (saberPrefab == null || IsFull) return;

        if (pivot == null)
        {
            pivot = new GameObject("SaberPivot").transform;
            pivot.position = transform.position;
        }

        sabers.Add(Instantiate(saberPrefab, pivot).transform);

        // Hepsini eşit açılarla yeniden diz, bıçaklar dışa baksın
        for (int i = 0; i < sabers.Count; i++)
        {
            float angle = 360f / sabers.Count * i;
            Quaternion rotation = Quaternion.Euler(0f, 0f, angle);
            sabers[i].localPosition = rotation * Vector3.up * radius;
            sabers[i].localRotation = rotation;
        }
    }

    void LateUpdate()
    {
        if (pivot == null) return;

        pivot.position = transform.position;
        pivot.Rotate(0f, 0f, -rotateSpeed * Time.deltaTime);
    }

    void OnDestroy()
    {
        if (pivot != null) Destroy(pivot.gameObject);
    }
}
