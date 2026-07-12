using UnityEngine;

public class InfiniteBackground : MonoBehaviour
{
    private Transform cam;
    private float tileSizeX;
    private float tileSizeY;

    void Start()
    {
        
        if (Camera.main != null)
        {
            cam = Camera.main.transform;
        }
        else
        {
           
            return;
        }

        
        SpriteRenderer spriteRenderer = GetComponent<SpriteRenderer>();
        if (spriteRenderer != null && spriteRenderer.sprite != null)
        {
            
            tileSizeX = spriteRenderer.sprite.bounds.size.x;
            tileSizeY = spriteRenderer.sprite.bounds.size.y;
        }
        else
        {
           
        }
    }

    void LateUpdate()
    {
        
        if (cam == null || tileSizeX == 0 || tileSizeY == 0) return;

        
        float snapX = Mathf.Round(cam.position.x / tileSizeX) * tileSizeX;
        float snapY = Mathf.Round(cam.position.y / tileSizeY) * tileSizeY;

        
        transform.position = new Vector3(snapX, snapY, transform.position.z);
    }
}