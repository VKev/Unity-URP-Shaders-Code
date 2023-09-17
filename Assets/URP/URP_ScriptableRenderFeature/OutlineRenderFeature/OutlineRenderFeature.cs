
using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.Internal;
using UnityEngine.XR;

public class OutlineRenderFeature : ScriptableRendererFeature
{


    OutlineBlitPass outlineRenderPass = null;
    DrawDepthPass drawOpaquesDepthPass = null;
    DrawObstructPass drawOpaquesObstructPass = null;
    //MyCopyDepth copyDepthPass = null;
    [SerializeField] private RenderPassEvent renderPassEvent;
    [SerializeField] private LayerMask outlineLayerMask;
    [SerializeField] private LayerMask obstructLayerMask;
    [SerializeField] public Material outlineMat;
    /// <inheritdoc/>
    public override void Create()
    {
        if (outlineMat==null)
            outlineMat = new Material(Shader.Find("MyCustom_URP_Shader/URP_OutlinePP"));

         
        drawOpaquesDepthPass = new DrawDepthPass(outlineLayerMask);
        drawOpaquesObstructPass = new DrawObstructPass(obstructLayerMask);
        outlineRenderPass = new OutlineBlitPass(renderPassEvent, outlineMat);

    }
    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (renderingData.cameraData.camera == Camera.main)
        {
            outlineRenderPass.SetTarget(renderer.cameraColorTargetHandle);
        }
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.camera == Camera.main)
        {
            renderer.EnqueuePass(drawOpaquesDepthPass);
            if(outlineMat != null && outlineMat.GetFloat("_SeeThroughWall") == 0)
                renderer.EnqueuePass(drawOpaquesObstructPass);
            renderer.EnqueuePass(outlineRenderPass);
        }
    }
}


