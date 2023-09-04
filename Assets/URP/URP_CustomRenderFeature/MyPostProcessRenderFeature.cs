
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.Internal;
using UnityEngine.XR;

public class MyPostProcessRenderFeature : ScriptableRendererFeature
{

    class DrawOpaquesDepthPass : ScriptableRenderPass
    {
        RTHandle depth;
        readonly int drawDepthID;

        RTHandle customDepthTextureRT;
        readonly int customDepthTextureID;


        RendererListParams rendererListParams;
        RendererList rendererList;
        DrawingSettings depthDrawingSettings;
        FilteringSettings depthFilteringSettings;

        


        readonly List<ShaderTagId> shaderTagIdList;
        public DrawOpaquesDepthPass( LayerMask outlineMask)
        {
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques;

            //customOpaqueTextureID = Shader.PropertyToID("_CustomOpaqueTexture");
            drawDepthID = Shader.PropertyToID("_DrawOutlineDepth");
            customDepthTextureID = Shader.PropertyToID("_CustomOutlineDepthTexture");


            depthFilteringSettings = new FilteringSettings(RenderQueueRange.opaque, outlineMask);



            shaderTagIdList = new List<ShaderTagId> {
                new ShaderTagId("UniversalForward"),
                new ShaderTagId("UniversalForwardOnly"),
                new ShaderTagId("LightweightForward"),
                new ShaderTagId("SRPDefaultUnlit")
            };

            

        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            //render depth to depth RThandle
            cmd.GetTemporaryRT(drawDepthID, Screen.width,Screen.height, 32, FilterMode.Point, RenderTextureFormat.Depth);
            depth = RTHandles.Alloc(new RenderTargetIdentifier(drawDepthID));


            RenderTextureDescriptor customDepthTextureDescriptor = cameraTextureDescriptor;
            customDepthTextureDescriptor.depthBufferBits = 32;
            customDepthTextureDescriptor.colorFormat = RenderTextureFormat.RFloat;
            cmd.GetTemporaryRT(customDepthTextureID, customDepthTextureDescriptor);
            customDepthTextureRT = RTHandles.Alloc(new RenderTargetIdentifier(customDepthTextureID));


            ConfigureTarget(depth);
            ConfigureClear(ClearFlag.All, Camera.main.backgroundColor);

        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();

            using (new ProfilingScope(cmd, new ProfilingSampler("Draw _CustomOutlineDepthTexture")))
            {


                depthDrawingSettings = CreateDrawingSettings(shaderTagIdList, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
                rendererListParams = new RendererListParams(renderingData.cullResults, depthDrawingSettings, depthFilteringSettings);
                rendererList = context.CreateRendererList(ref rendererListParams);
                cmd.DrawRendererList(rendererList);

                cmd.Blit(depth.nameID, customDepthTextureRT.nameID);

                //cmd.ClearRenderTarget(RTClearFlags.All, Color.black, 1, 0);

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

            cmd.ReleaseTemporaryRT(drawDepthID);
            cmd.ReleaseTemporaryRT(customDepthTextureID);
            customDepthTextureRT.Release();
            depth.Release();
        }
    }

    class DrawOpaquesObstructPass : ScriptableRenderPass
    {
        RTHandle obstruct;
        readonly int drawObstructID;

        RTHandle depth;
        readonly int drawDepthID;

        RTHandle customObstructTextureRT;
        readonly int customObstructTextureID;

        RTHandle customDepthObstructTextureRT;
        readonly int customDepthObstructTextureID;


        RendererListParams rendererListParams;
        RendererList rendererList;
        DrawingSettings obstructDrawingSettings;
        FilteringSettings obstructFilteringSettings;
        Material overrideMaterial;



        readonly List<ShaderTagId> shaderTagIdList;
        public DrawOpaquesObstructPass(LayerMask obstructMask, Material cullOffMat)
        {
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques;

            //customOpaqueTextureID = Shader.PropertyToID("_CustomOpaqueTexture");
            drawObstructID = Shader.PropertyToID("_DrawColorObstruct");
            drawDepthID = Shader.PropertyToID("_DrawDepthObstruct");
            customObstructTextureID = Shader.PropertyToID("_CustomColorObstructTexture");
            customDepthObstructTextureID = Shader.PropertyToID("_CustomDepthObstructTexture");


            obstructFilteringSettings = new FilteringSettings(RenderQueueRange.opaque, obstructMask);



            shaderTagIdList = new List<ShaderTagId> {
                new ShaderTagId("UniversalForward"),
                new ShaderTagId("UniversalForwardOnly"),
                new ShaderTagId("LightweightForward"),
                new ShaderTagId("SRPDefaultUnlit"),
            };
            overrideMaterial = cullOffMat;

        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            
            cmd.GetTemporaryRT(drawObstructID, Screen.width, Screen.height, 32, FilterMode.Point, RenderTextureFormat.RGB565);
            obstruct = RTHandles.Alloc(new RenderTargetIdentifier(drawObstructID));
            
            cmd.GetTemporaryRT(drawDepthID, Screen.width, Screen.height, 32, FilterMode.Point, RenderTextureFormat.Depth);
            depth = RTHandles.Alloc(new RenderTargetIdentifier(drawDepthID));



            RenderTextureDescriptor customDepthTextureDescriptor = cameraTextureDescriptor;
            customDepthTextureDescriptor.depthBufferBits = 32;
            customDepthTextureDescriptor.colorFormat = RenderTextureFormat.RFloat;
            cmd.GetTemporaryRT(customDepthObstructTextureID, customDepthTextureDescriptor);
            customDepthObstructTextureRT = RTHandles.Alloc(new RenderTargetIdentifier(customDepthObstructTextureID));

            RenderTextureDescriptor customObstructTextureDescriptor = cameraTextureDescriptor;
            customObstructTextureDescriptor.colorFormat = RenderTextureFormat.RGB565;
            customObstructTextureDescriptor.depthStencilFormat = GraphicsFormat.None;
            customObstructTextureDescriptor.depthBufferBits = 0;
            cmd.GetTemporaryRT(customObstructTextureID, customObstructTextureDescriptor);
            customObstructTextureRT = RTHandles.Alloc(new RenderTargetIdentifier(customObstructTextureID));


            ConfigureTarget(obstruct, depth);
            ConfigureClear(ClearFlag.All, Color.black);

        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();

            using (new ProfilingScope(cmd, new ProfilingSampler("Draw _Custom<Color,Depth>ObstructTexture")))
            {


                obstructDrawingSettings = CreateDrawingSettings(shaderTagIdList, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
                obstructDrawingSettings.overrideMaterial = overrideMaterial;
                rendererListParams = new RendererListParams(renderingData.cullResults, obstructDrawingSettings, obstructFilteringSettings);
                rendererList = context.CreateRendererList(ref rendererListParams);
                cmd.DrawRendererList(rendererList);

                cmd.Blit(depth.nameID, customDepthObstructTextureRT.nameID);

                cmd.Blit(obstruct.nameID, customObstructTextureRT.nameID);

                //cmd.ClearRenderTarget(RTClearFlags.All, Color.black, 1, 0);

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

            cmd.ReleaseTemporaryRT(drawObstructID);
            obstruct.Release();

            cmd.ReleaseTemporaryRT(drawDepthID);
            depth.Release();

            cmd.ReleaseTemporaryRT(customObstructTextureID);
            customObstructTextureRT.Release();

            cmd.ReleaseTemporaryRT(customDepthObstructTextureID);
            customDepthObstructTextureRT.Release();

        }
    }

    class OutlineRenderPass : ScriptableRenderPass
    {
        RTHandle source;

        RTHandle tempRT;
        readonly int tempID;

        Material outlineMat;
        OutlineVolumeSetting outlineVolumeSetting;

        public OutlineRenderPass(RenderPassEvent passEvent, Material outlineMaterial)
        {
            outlineMat = outlineMaterial;
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
                    if ((bool)outlineVolumeSetting.seeThroughWall)
                        outlineMat.SetFloat("_SeeThroughWall", 1f);
                    else
                        outlineMat.SetFloat("_SeeThroughWall", 0f);


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
    DrawOpaquesDepthPass drawOpaquesDepthPass = null;
    DrawOpaquesObstructPass drawOpaquesObstructPass = null;
    //MyCopyDepth copyDepthPass = null;
    [SerializeField] private RenderPassEvent renderPassEvent;
    [SerializeField] private LayerMask outlineLayerMask;
    [SerializeField] private LayerMask obstructLayerMask;
    [SerializeField] public Material outlineMat;
    [SerializeField] public Material cullOffMat;
    /// <inheritdoc/>
    public override void Create()
    {
        if (outlineMat==null)
            outlineMat = new Material(Shader.Find("MyCustom_URP_Shader/URP_OutlinePP"));

        if(cullOffMat==null)
            cullOffMat = new Material(Shader.Find("MyCustom_URP_Shader/URP_CullOff"));
         
        drawOpaquesDepthPass = new DrawOpaquesDepthPass(outlineLayerMask);
        drawOpaquesObstructPass = new DrawOpaquesObstructPass(obstructLayerMask,cullOffMat);
        outlineRenderPass = new OutlineRenderPass(renderPassEvent, outlineMat);

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
            renderer.EnqueuePass(drawOpaquesDepthPass);
            if(outlineMat != null && outlineMat.GetFloat("_SeeThroughWall") == 0)
                renderer.EnqueuePass(drawOpaquesObstructPass);
            renderer.EnqueuePass(outlineRenderPass);
        }
    }
}


