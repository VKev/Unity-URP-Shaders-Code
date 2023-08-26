using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable, VolumeComponentMenu("MyCustomPostProcess/ColorTone")]
public class ColorToneVolumeSetting : VolumeComponent, IPostProcessComponent
{
    public ColorParameter col = new ColorParameter(Color.white);


    public bool IsActive() 
    {

        return col.overrideState;
           
    }
    public bool IsTileCompatible()
    {
        return false;
    }
}
