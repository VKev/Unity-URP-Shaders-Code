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
    public ClampedFloatParameter outlineSize = new ClampedFloatParameter(1f,1f,4f);
    public ClampedFloatParameter depthThreshold = new ClampedFloatParameter(0.05f,0.001f,1f);
    public ClampedFloatParameter normalThreshold = new ClampedFloatParameter(0.3f, 0.001f, 1f);
    public ColorParameter outlineColor = new ColorParameter(Color.white);


    public bool IsActive() 
    {

        return outlineSize.overrideState && outlineColor.overrideState;
           
    }
    public bool IsTileCompatible()
    {
        return false;
    }
}
