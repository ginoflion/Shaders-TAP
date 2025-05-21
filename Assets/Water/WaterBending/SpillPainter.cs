using UnityEngine;

public class SpillPainter : MonoBehaviour
{
    public Texture2D brush;
    public Material drawMaterial; // Material using "Hidden/DrawBrush"
    public RenderTexture spillMask;

    [Range(0.01f, 0.2f)]
    public float brushSize = 0.05f;

    private void OnTriggerEnter(Collider other)
    {
        if (!other.CompareTag("Ground")) return;

        Ray ray = new Ray(transform.position, Vector3.down);
        if (Physics.Raycast(ray, out RaycastHit hit))
        {
            if (hit.collider is MeshCollider)
            {
                Vector2 uv = hit.textureCoord;
                DrawAtUV(uv);
            }
        }
    }

    void DrawAtUV(Vector2 uv)
    {
        // Ensure the temporary texture matches format and size
        RenderTexture temp = RenderTexture.GetTemporary(spillMask.width, spillMask.height, 0, spillMask.format);
        temp.filterMode = FilterMode.Bilinear;

        // Copy current mask into temporary RT
        Graphics.Blit(spillMask, temp);

        // Set brush and parameters on the draw material
        drawMaterial.SetTexture("_MainTex", brush);
        drawMaterial.SetVector("_UV", new Vector4(uv.x, uv.y, 0, 0));
        drawMaterial.SetFloat("_BrushSize", brushSize);

        // Paint into the actual mask
        Graphics.Blit(temp, spillMask, drawMaterial);

        // Clean up
        RenderTexture.ReleaseTemporary(temp);
    }
}
