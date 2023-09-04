using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassPropertiesController : MonoBehaviour
{
    MaterialPropertyBlock propertyBlock;
    public Color topColor;
    public Color bottomColor;

    private void OnValidate()
    {
        
        Renderer renderer = GetComponent<Renderer>();

        if(propertyBlock == null)
            propertyBlock = new MaterialPropertyBlock();
        
        propertyBlock.SetColor("_TopColor", topColor);
        propertyBlock.SetColor("_BottomColor", bottomColor);
        //propertyBlock.SetFloat("_WaveStrength", Random.Range(0.04f, 0.06f));
        //propertyBlock.SetFloat("_WaveSpeed", Random.Range(0.1f, 0.3f));

        renderer.SetPropertyBlock(propertyBlock);
    }
}
