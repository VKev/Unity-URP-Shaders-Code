using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Toon_PropertiesManager : MonoBehaviour
{
    MaterialPropertyBlock propertyBlock;
    public float Gloss = 1;
    public Color AmbientColor = new Color(168,168,168,1)/255;

    private void OnValidate()
    {

        Renderer renderer = GetComponent<Renderer>();

        if (propertyBlock == null)
            propertyBlock = new MaterialPropertyBlock();

        propertyBlock.SetFloat("_Gloss", Gloss);
        propertyBlock.SetColor("_AmbientColor", AmbientColor);
        //propertyBlock.SetFloat("_WaveStrength", Random.Range(0.04f, 0.06f));
        //propertyBlock.SetFloat("_WaveSpeed", Random.Range(0.1f, 0.3f));

        renderer.SetPropertyBlock(propertyBlock);
    }
}
