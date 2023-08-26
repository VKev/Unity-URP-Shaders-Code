using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

internal class ColorToneRenderPass : ScriptableRenderPass
{
    //ProfilingSampler m_ProfilingSampler = new ProfilingSampler("OutlineShader");
    Material m_Material;
    RTHandle m_CameraColorTarget;
    ColorToneVolumeSetting outlineVolumeSetting;
    float m_Intensity;

    public ColorToneRenderPass(Material material)
    {
        m_Material = new Material(Shader.Find("MyCustom_URP_Shader/URP_ColorTone"));


        renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public void SetTarget(RTHandle colorHandle)
    {
        m_CameraColorTarget = colorHandle;
    }


    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        ConfigureTarget(m_CameraColorTarget);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cameraData = renderingData.cameraData;
        if (cameraData.camera.cameraType != CameraType.Game)
            return;


        VolumeStack volumes = VolumeManager.instance.stack;
        outlineVolumeSetting = volumes.GetComponent<ColorToneVolumeSetting>();
        CommandBuffer cmd = CommandBufferPool.Get("ColorToneRendererFeature");
        if (outlineVolumeSetting.IsActive() && m_Material!= null) {
            m_Material.SetColor("_ColorTone", (Color)outlineVolumeSetting.col);
            Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material,0);
        }

        context.ExecuteCommandBuffer(cmd);

        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }
}