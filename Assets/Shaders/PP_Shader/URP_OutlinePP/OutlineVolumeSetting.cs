using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable, VolumeComponentMenu("MyCustomPostProcess/Outline")]
public class OutlineVolumeSetting : VolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter outlineSize = new ClampedFloatParameter(2f,1f,5f);
    public ColorParameter outlineColor = new ColorParameter(Color.white);
    public ClampedFloatParameter depthThreshold = new ClampedFloatParameter(10f,0.001f,20f);
    public ClampedFloatParameter normalThreshold = new ClampedFloatParameter(0.7f, 0.001f, 5f);
    public BoolParameter seeThroughWall =  new BoolParameter(false);


    public bool IsActive() 
    {

        return outlineSize.overrideState && outlineColor.overrideState && (outlineColor.value.a >0);
           
    }
    public bool IsTileCompatible()
    {
        return false;
    }
}
