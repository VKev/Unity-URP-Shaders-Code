using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

public class DrawObstructPass : ScriptableRenderPass
{

        RTHandle depth;
        readonly int drawDepthID;

        /*RTHandle customObstructTextureRT;
        readonly int customObstructTextureID;*/

        RTHandle customDepthObstructTextureRT;
        readonly int customDepthObstructTextureID;


        RendererListParams rendererListParams;
        RendererList rendererList;
        DrawingSettings obstructDrawingSettings;
        FilteringSettings obstructFilteringSettings;



        readonly List<ShaderTagId> shaderTagIdList;
        public DrawObstructPass(LayerMask obstructMask)
        {
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques;

            //customOpaqueTextureID = Shader.PropertyToID("_CustomOpaqueTexture");
            /*drawObstructID = Shader.PropertyToID("_DrawColorObstruct");*/
            drawDepthID = Shader.PropertyToID("_DrawDepthObstruct");
            /*customObstructTextureID = Shader.PropertyToID("_CustomColorObstructTexture");*/
            customDepthObstructTextureID = Shader.PropertyToID("_CustomDepthObstructTexture");


            obstructFilteringSettings = new FilteringSettings(RenderQueueRange.opaque, obstructMask);



            shaderTagIdList = new List<ShaderTagId> {
                    new ShaderTagId("UniversalForward"),
                    new ShaderTagId("UniversalForwardOnly"),
                    new ShaderTagId("LightweightForward"),
                    new ShaderTagId("SRPDefaultUnlit"),
                };
            

        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {

            /*cmd.GetTemporaryRT(drawObstructID, Screen.width, Screen.height, 32, FilterMode.Point, RenderTextureFormat.RGB565);
            obstruct = RTHandles.Alloc(new RenderTargetIdentifier(drawObstructID));*/

            cmd.GetTemporaryRT(drawDepthID, Screen.width, Screen.height, 32, FilterMode.Point, RenderTextureFormat.Depth);
            depth = RTHandles.Alloc(new RenderTargetIdentifier(drawDepthID));



            RenderTextureDescriptor customDepthTextureDescriptor = cameraTextureDescriptor;
            customDepthTextureDescriptor.depthBufferBits = 32;
            customDepthTextureDescriptor.colorFormat = RenderTextureFormat.RFloat;
            cmd.GetTemporaryRT(customDepthObstructTextureID, customDepthTextureDescriptor);
            customDepthObstructTextureRT = RTHandles.Alloc(new RenderTargetIdentifier(customDepthObstructTextureID));

            /*RenderTextureDescriptor customObstructTextureDescriptor = cameraTextureDescriptor;
            customObstructTextureDescriptor.colorFormat = RenderTextureFormat.RGB565;
            customObstructTextureDescriptor.depthStencilFormat = GraphicsFormat.None;
            customObstructTextureDescriptor.depthBufferBits = 0;
            cmd.GetTemporaryRT(customObstructTextureID, customObstructTextureDescriptor);
            customObstructTextureRT = RTHandles.Alloc(new RenderTargetIdentifier(customObstructTextureID));*/


            ConfigureTarget( depth);
            ConfigureClear(ClearFlag.All, Color.black);

        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();

            using (new ProfilingScope(cmd, new ProfilingSampler("Draw _Custom<Color,Depth>ObstructTexture")))
            {


                obstructDrawingSettings = CreateDrawingSettings(shaderTagIdList, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
                //obstructDrawingSettings.overrideMaterial = overrideMaterial;
                rendererListParams = new RendererListParams(renderingData.cullResults, obstructDrawingSettings, obstructFilteringSettings);
                rendererList = context.CreateRendererList(ref rendererListParams);
                cmd.DrawRendererList(rendererList);

                cmd.Blit(depth.nameID, customDepthObstructTextureRT.nameID);

                //cmd.Blit(obstruct.nameID, customObstructTextureRT.nameID);

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

            /*cmd.ReleaseTemporaryRT(drawObstructID);
            obstruct.Release();*/

            cmd.ReleaseTemporaryRT(drawDepthID);
            depth.Release();

            /*cmd.ReleaseTemporaryRT(customObstructTextureID);
            customObstructTextureRT.Release();*/

            cmd.ReleaseTemporaryRT(customDepthObstructTextureID);
            customDepthObstructTextureRT.Release();

        }
}
