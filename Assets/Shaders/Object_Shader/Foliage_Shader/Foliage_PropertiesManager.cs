using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Foliage_PropertiesManager : MonoBehaviour
{
    MaterialPropertyBlock propertyBlock;
    public Color Color = new Color(22,108,0,1)/255;
    public Color AmbientColor= new Color(21, 142, 0,1)/255;

    public float FluffyScale=1.5f;
    public float BlendScale =1.5f;
    public float NormalRandom =1 ;
    public float TangentRandom =0 ;
    public float BitangentRandom=0 ;

    public float LocalWindAmplitude_Vertical = 0.2f;
    public float LocalWindAmplitude_Horizontal = 0.2f;
    public new Renderer renderer;

    MaterialPropertyBlock propertyBlockOnValidate;
    private void Start()
    {
        renderer = GetComponent<MeshRenderer>();

        propertyBlock = new MaterialPropertyBlock();

        propertyBlock.SetFloat("_FluffyScale", FluffyScale);
        propertyBlock.SetFloat("_BlendEffect", BlendScale);
        propertyBlock.SetFloat("_NormalRandom", NormalRandom);
        propertyBlock.SetFloat("_TangentRandom", TangentRandom);
        propertyBlock.SetFloat("_BitangentRandom", BitangentRandom);
        propertyBlock.SetColor("_Color", Color);
        propertyBlock.SetColor("_AmbientColor", AmbientColor);

        propertyBlock.SetFloat("_WaveLocalHorizontalAmplitude", LocalWindAmplitude_Horizontal);
        propertyBlock.SetFloat("_WaveLocalVerticalAmplitude", LocalWindAmplitude_Vertical);
        //propertyBlock.SetFloat("_WaveStrength", Random.Range(0.04f, 0.06f));
        //propertyBlock.SetFloat("_WaveSpeed", Random.Range(0.1f, 0.3f));

        renderer.SetPropertyBlock(propertyBlock);
    }

    private void OnValidate()
    {

        Renderer renderer = GetComponent<MeshRenderer>();
        if (propertyBlockOnValidate == null)
            propertyBlockOnValidate = new MaterialPropertyBlock();

        propertyBlockOnValidate.SetFloat("_FluffyScale", FluffyScale);
        propertyBlockOnValidate.SetFloat("_BlendEffect", BlendScale);
        propertyBlockOnValidate.SetFloat("_NormalRandom", NormalRandom);
        propertyBlockOnValidate.SetFloat("_TangentRandom", TangentRandom);
        propertyBlockOnValidate.SetFloat("_BitangentRandom", BitangentRandom);
        propertyBlockOnValidate.SetColor("_Color", Color);
        propertyBlockOnValidate.SetColor("_AmbientColor", AmbientColor);

        propertyBlockOnValidate.SetFloat("_WaveLocalHorizontalAmplitude", LocalWindAmplitude_Horizontal);
        propertyBlockOnValidate.SetFloat("_WaveLocalVerticalAmplitude", LocalWindAmplitude_Vertical);
        //propertyBlock.SetFloat("_WaveStrength", Random.Range(0.04f, 0.06f));
        //propertyBlock.SetFloat("_WaveSpeed", Random.Range(0.1f, 0.3f));

        renderer.SetPropertyBlock(propertyBlockOnValidate);
    }
}
