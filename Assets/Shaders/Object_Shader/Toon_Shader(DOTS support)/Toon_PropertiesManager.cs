using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Toon_PropertiesManager : MonoBehaviour
{
    MaterialPropertyBlock propertyBlock;
    public float Gloss = 1;
    public Color Color = new Color(200,200,200,1)/255;
    public Color AmbientColor = new Color(168,168,168,1)/255;

    public float RimSize;
    public float RimBlur;
    public float RimThreshold;

    private void Start()
    {
        Renderer renderer = GetComponent<Renderer>();

        if (propertyBlock == null)
            propertyBlock = new MaterialPropertyBlock();

        propertyBlock.SetFloat("_Gloss", Gloss);
        propertyBlock.SetColor("_AmbientColor", AmbientColor);
        propertyBlock.SetColor("_Color", Color);
        propertyBlock.SetFloat("_RimSize", RimSize);
        propertyBlock.SetFloat("_RimBlur", RimBlur);
        propertyBlock.SetFloat("_RimThreshold", RimThreshold);
        //propertyBlock.SetFloat("_WaveStrength", Random.Range(0.04f, 0.06f));
        //propertyBlock.SetFloat("_WaveSpeed", Random.Range(0.1f, 0.3f));

        renderer.SetPropertyBlock(propertyBlock);
    }
    private void OnValidate()
    {

        Renderer renderer = GetComponent<Renderer>();

        if (propertyBlock == null)
            propertyBlock = new MaterialPropertyBlock();

        propertyBlock.SetFloat("_Gloss", Gloss);
        propertyBlock.SetColor("_AmbientColor", AmbientColor);
        propertyBlock.SetColor("_Color", Color);
        propertyBlock.SetFloat("_RimSize", RimSize);
        propertyBlock.SetFloat("_RimBlur", RimBlur);
        propertyBlock.SetFloat("_RimThreshold", RimThreshold);
        //propertyBlock.SetFloat("_WaveStrength", Random.Range(0.04f, 0.06f));
        //propertyBlock.SetFloat("_WaveSpeed", Random.Range(0.1f, 0.3f));

        renderer.SetPropertyBlock(propertyBlock);
    }
}
