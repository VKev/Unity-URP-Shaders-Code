
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.UIElements;

public class MyPostProcessRenderFeature : ScriptableRendererFeature
{
    
    class OutlineRenderPass : ScriptableRenderPass
    {
        RTHandle source;
        RenderTargetIdentifier destination;
        int destID;
        //RTHandle temp;
        Material outlineMat;
        OutlineVolumeSetting outlineVolumeSetting;

        public OutlineRenderPass(RenderPassEvent passEvent)
        {

            outlineMat = new Material(Shader.Find("MyCustom_URP_Shader/URP_OutlinePP"));
            this.renderPassEvent = passEvent;
            destID = Shader.PropertyToID("_des");
        }
        public void SetTarget(RTHandle colorHandle)
        {
            source = colorHandle;
        }
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {

            cmd.GetTemporaryRT(destID, cameraTextureDescriptor);
            destination = new RenderTargetIdentifier(destID);
        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureTarget(source);
            
        }

        
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!outlineMat)
                return;
            CommandBuffer cmd = CommandBufferPool.Get();

            outlineVolumeSetting = VolumeManager.instance.stack.GetComponent<OutlineVolumeSetting>();
            if (outlineVolumeSetting.IsActive())
            {
                using (new ProfilingScope(cmd, new ProfilingSampler("Outline Post Process")))
                {
                    outlineMat.SetFloat("_OutlineSize", (float)outlineVolumeSetting.outlineSize);
                    outlineMat.SetFloat("_DepthThreshold", (float)outlineVolumeSetting.depthThreshold);
                    outlineMat.SetFloat("_NormalThreshold", (float)outlineVolumeSetting.normalThreshold);
                    outlineMat.SetColor("_OutlineColor", (Color)outlineVolumeSetting.outlineColor);
                    cmd.Blit(source.nameID, destination);
                    cmd.Blit(destination, source.nameID, outlineMat);
                    //Blitter.BlitCameraTexture(cmd, source, source, outlineMat, 0);
                    //Blitter.BlitCameraTexture(cmd, source, source, outlineMat, 1);
                }
            }

            context.ExecuteCommandBuffer(cmd);

            CommandBufferPool.Release(cmd);
            cmd.Clear();
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(destID);
        }

    }

    OutlineRenderPass outlineRenderPass = null;
    [SerializeField] private RenderPassEvent renderPassEvent;
    /// <inheritdoc/>
    public override void Create()
    {
        outlineRenderPass = new OutlineRenderPass(renderPassEvent);
        
    }
    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            // Calling ConfigureInput with the ScriptableRenderPassInput.Color argument
            // ensures that the opaque texture is available to the Render Pass.
            //outlineRenderPass.ConfigureInput(ScriptableRenderPassInput.Normal);
            outlineRenderPass.SetTarget(renderer.cameraColorTargetHandle);
        }
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(outlineRenderPass);
        }
    }
}


