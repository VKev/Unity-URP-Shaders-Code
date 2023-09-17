using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

public class DrawOpaquesDepthPass : ScriptableRenderPass
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
        public DrawOpaquesDepthPass(LayerMask outlineMask)
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
            cmd.GetTemporaryRT(drawDepthID, Screen.width, Screen.height, 32, FilterMode.Point, RenderTextureFormat.Depth);
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
