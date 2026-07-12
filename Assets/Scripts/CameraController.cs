using UnityEngine;

public class CameraController : MonoBehaviour
{
    public Transform target;
    public Vector3 offset = new Vector3(0f, 0f, -10f);
    public float smoothSpeed = 10f;

    private float currentShakeDuration = 0f;
    private float currentShakeMagnitude = 0f;

    
    private Vector3 basePosition;

    void Start()
    {
        
        basePosition = transform.position;
    }

    public void TriggerShake(float duration, float magnitude)
    {
        currentShakeDuration = duration;
        currentShakeMagnitude = magnitude;
    }

    
    void LateUpdate()
    {
        if (target != null)
        {
            Vector3 desiredPosition = target.position + offset;
            basePosition = Vector3.Lerp(basePosition, desiredPosition, smoothSpeed * Time.deltaTime);

            Vector3 shakeOffset = Vector3.zero;
            if (currentShakeDuration > 0)
            {
                shakeOffset = (Vector3)Random.insideUnitCircle * currentShakeMagnitude;
                currentShakeDuration -= Time.deltaTime;
            }

            transform.position = basePosition + shakeOffset;
        }
    }
}
