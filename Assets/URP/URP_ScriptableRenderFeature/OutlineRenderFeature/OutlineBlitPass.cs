using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

public class OutlineBlitPass : ScriptableRenderPass
{
        RTHandle source;

        RTHandle tempRT;
        readonly int tempID;

        Material outlineMat;
        OutlineVolumeSetting outlineVolumeSetting;

        public OutlineBlitPass(RenderPassEvent passEvent, Material outlineMaterial)
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
            tempRT = RTHandles.Alloc(new RenderTargetIdentifier(tempID));


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
