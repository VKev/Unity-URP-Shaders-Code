using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Foliage_PropertiesManager : MonoBehaviour
{
    MaterialPropertyBlock propertyBlock;
    public Color Color = new Color(4,140,0,1)/255;
    public Color AmbientColor= new Color(23, 154, 0,1)/255;

    public float FluffyScale=1.5f;
    public float BlendScale =1.5f;
    public float RandomScatter =1 ;

    private void OnValidate()
    {

        Renderer renderer = GetComponent<Renderer>();

        if (propertyBlock == null)
            propertyBlock = new MaterialPropertyBlock();

        propertyBlock.SetFloat("_FluffyScale", FluffyScale);
        propertyBlock.SetFloat("_BlendEffect", BlendScale);
        propertyBlock.SetFloat("_Randomize", RandomScatter);
        propertyBlock.SetColor("_Color", Color);
        propertyBlock.SetColor("_AmbientColor", AmbientColor);
        //propertyBlock.SetFloat("_WaveStrength", Random.Range(0.04f, 0.06f));
        //propertyBlock.SetFloat("_WaveSpeed", Random.Range(0.1f, 0.3f));

        renderer.SetPropertyBlock(propertyBlock);
    }
}
