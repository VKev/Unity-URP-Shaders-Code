using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

internal class ColorToneRendererFeature : ScriptableRendererFeature
{
    //public float m_Intensity;

    Material outline_Material;

    ColorToneRenderPass outline_RenderPass = null;

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
            renderer.EnqueuePass(outline_RenderPass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer,
                                        in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            // Calling ConfigureInput with the ScriptableRenderPassInput.Color argument
            // ensures that the opaque texture is available to the Render Pass.
            //outline_RenderPass.ConfigureInput(ScriptableRenderPassInput.Color);
            outline_RenderPass.SetTarget(renderer.cameraColorTargetHandle);
        }
    }

    public override void Create()
    {
        outline_RenderPass = new ColorToneRenderPass(outline_Material);
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(outline_Material);
    }
}