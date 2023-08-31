
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.Internal;
using UnityEngine.XR;

public class MyPostProcessRenderFeature : ScriptableRendererFeature
{

    class DrawOpaquesPass : ScriptableRenderPass
    {
        RTHandle source;
        readonly int drawOpaqueID;
        
        /*RTHandle customOpaqueTextureRT;
        readonly int customOpaqueTextureID;*/

        RTHandle customDepthTextureRT;
        readonly int customDepthTextureID;

        RendererListParams rendererListParams;
        RendererList rendererList;
        DrawingSettings drawingSettings;
        FilteringSettings filteringSettings;
        readonly List<ShaderTagId> shaderTagIdList;


        public DrawOpaquesPass( LayerMask layerMask)
        {
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
           
            //customOpaqueTextureID = Shader.PropertyToID("_CustomOpaqueTexture");
            drawOpaqueID = Shader.PropertyToID("_DrawOpaque");
            customDepthTextureID = Shader.PropertyToID("_CustomDepthTexture");

            filteringSettings = new FilteringSettings(RenderQueueRange.opaque, layerMask);
            shaderTagIdList = new List<ShaderTagId> {
                new ShaderTagId("UniversalForward"),
                new ShaderTagId("UniversalForwardOnly"),
                new ShaderTagId("LightweightForward"),
                new ShaderTagId("SRPDefaultUnlit")
            };


        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {

            cmd.GetTemporaryRT(drawOpaqueID, Screen.width,Screen.height, 32, FilterMode.Point, RenderTextureFormat.Depth);
            source = RTHandles.Alloc(new RenderTargetIdentifier(drawOpaqueID));

            //USE FOR COLOR COPY
            /*cmd.GetTemporaryRT(drawOpaqueID, Screen.width, Screen.height, 32, FilterMode.Point, RenderTextureFormat.RGB111110Float);
            source = RTHandles.Alloc(new RenderTargetIdentifier(drawOpaqueID));*/
            /*RenderTextureDescriptor customOpaqueTextureDescriptor = cameraTextureDescriptor;
            //customOpaqueTextureDescriptor.depthBufferBits = 32;
            //customOpaqueTextureDescriptor.colorFormat = RenderTextureFormat.RFloat;
            customOpaqueTextureDescriptor.colorFormat = RenderTextureFormat.RGB111110Float;
            customOpaqueTextureDescriptor.depthStencilFormat = GraphicsFormat.None;
            cmd.GetTemporaryRT(customOpaqueTextureID, customOpaqueTextureDescriptor);
            customOpaqueTextureRT = RTHandles.Alloc(new RenderTargetIdentifier(customOpaqueTextureID));*/

            RenderTextureDescriptor customDepthTextureDescriptor = cameraTextureDescriptor;
            customDepthTextureDescriptor.depthBufferBits = 32;
            //customDepthTextureDescriptor.colorFormat = RenderTextureFormat.RFloat;
            customDepthTextureDescriptor.colorFormat = RenderTextureFormat.RFloat;
            //customDepthTextureDescriptor.depthStencilFormat = GraphicsFormat.None;
            cmd.GetTemporaryRT(customDepthTextureID, customDepthTextureDescriptor);
            customDepthTextureRT = RTHandles.Alloc(new RenderTargetIdentifier(customDepthTextureID));

            ConfigureTarget(source);
            ConfigureClear(ClearFlag.All, Camera.main.backgroundColor);

        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();

            using (new ProfilingScope(cmd, new ProfilingSampler("Draw _CustomDepthTexture")))
            {


                drawingSettings = CreateDrawingSettings(shaderTagIdList, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
                rendererListParams = new RendererListParams(renderingData.cullResults, drawingSettings, filteringSettings);
                rendererList = context.CreateRendererList(ref rendererListParams);
                cmd.DrawRendererList(rendererList);

                cmd.Blit(source.nameID, customDepthTextureRT.nameID);

                /*cmd.SetGlobalTexture("_CameraDepthAttachment", source.nameID);
                Blitter.BlitTexture(cmd, source, customDepthTextureRT, new Material(Shader.Find("Hidden/Universal Render Pipeline/CopyDepth")),0);*/
            }
            //cmd.ClearRenderTarget(RTClearFlags.All, Color.black,1,0);
            context.ExecuteCommandBuffer(cmd);

            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            /*cmd.ReleaseTemporaryRT(customOpaqueTextureID);
            customOpaqueTextureRT.Release(); */
            cmd.ReleaseTemporaryRT(drawOpaqueID);
            cmd.ReleaseTemporaryRT(customDepthTextureID);
            customDepthTextureRT.Release();
            source.Release();
        }
    }

    /*class MyCopyDepth : ScriptableRenderPass
    {
        RTHandle source;
        RTHandle customDepthTextureRT;
        readonly int customDepthTextureID;
        readonly int drawOpaqueID;

        public MyCopyDepth()
        {
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques + 1;

            customDepthTextureID = Shader.PropertyToID("_CustomDepthTexture");
            drawOpaqueID = Shader.PropertyToID("_DrawOpaque");
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            RenderTextureDescriptor customDepthTextureDescriptor = cameraTextureDescriptor;
            customDepthTextureDescriptor.depthBufferBits = 32;
            customDepthTextureDescriptor.colorFormat = RenderTextureFormat.RFloat;
            customDepthTextureDescriptor.depthStencilFormat = GraphicsFormat.None;
            cmd.GetTemporaryRT(customDepthTextureID, customDepthTextureDescriptor);
            customDepthTextureRT = RTHandles.Alloc(new RenderTargetIdentifier(customDepthTextureID));

            source = RTHandles.Alloc(new RenderTargetIdentifier(drawOpaqueID));

            ConfigureTarget(source);
            //ConfigureClear(ClearFlag.DepthStencil, Color.black);
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, new ProfilingSampler("Custom copy Depth texture")))
            {
                
                cmd.Blit(source.nameID, customDepthTextureRT.nameID);
            }
            //cmd.ClearRenderTarget(RTClearFlags.All, Color.blue);
            context.ExecuteCommandBuffer(cmd);

            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(drawOpaqueID);
            cmd.ReleaseTemporaryRT(customDepthTextureID);
            source.Release();
            customDepthTextureRT.Release();
        }
    }*/

    class OutlineRenderPass : ScriptableRenderPass
    {
        RTHandle source;

        RTHandle tempRT;
        readonly int tempID;

        readonly Material outlineMat;
        OutlineVolumeSetting outlineVolumeSetting;

        public OutlineRenderPass(RenderPassEvent passEvent)
        {
            outlineMat = new Material(Shader.Find("MyCustom_URP_Shader/URP_OutlinePP"));
            this.renderPassEvent = passEvent;
            tempID = Shader.PropertyToID("_Temp");
        }
        public void SetTarget(RTHandle colorHandle)
        {
            source = colorHandle;
        }
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {

            cmd.GetTemporaryRT(tempID, cameraTextureDescriptor);
            tempRT = RTHandles.Alloc (new RenderTargetIdentifier(tempID));
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
                using (new ProfilingScope(cmd, new ProfilingSampler("Outline Post Processing")))
                {
                    outlineMat.SetFloat("_OutlineSize", (float)outlineVolumeSetting.outlineSize);
                    outlineMat.SetFloat("_DepthThreshold", (float)outlineVolumeSetting.depthThreshold);
                    outlineMat.SetFloat("_NormalThreshold", (float)outlineVolumeSetting.normalThreshold);
                    outlineMat.SetColor("_OutlineColor", (Color)outlineVolumeSetting.outlineColor);
                    
                    

                    cmd.Blit(tempRT.nameID, source.nameID, outlineMat);
                    //Blitter.BlitCameraTexture(cmd, source, source, outlineMat, 0);
                    //Blitter.BlitCameraTexture(cmd, source, source, outlineMat, 1);
                }
            }

            context.ExecuteCommandBuffer(cmd);

            cmd.Clear();
            CommandBufferPool.Release(cmd);

        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(tempID);
            tempRT.Release();
        }

    }

    OutlineRenderPass outlineRenderPass = null;
    DrawOpaquesPass drawOpaquesPass = null;
    //MyCopyDepth copyDepthPass = null;
    [SerializeField] private RenderPassEvent renderPassEvent;
    [SerializeField] private LayerMask layerMask;
    /// <inheritdoc/>
    public override void Create()
    {
        drawOpaquesPass = new DrawOpaquesPass(layerMask);
        outlineRenderPass = new OutlineRenderPass(renderPassEvent);

    }
    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            outlineRenderPass.SetTarget(renderer.cameraColorTargetHandle);
        }
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            renderer.EnqueuePass(drawOpaquesPass);
            renderer.EnqueuePass(outlineRenderPass);
        }
    }
    protected override void Dispose(bool disposing)
    {
        
    }
}


