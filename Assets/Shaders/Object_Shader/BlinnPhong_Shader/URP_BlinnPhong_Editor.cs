
using UnityEngine;
using UnityEngine.Rendering;

#if UNITY_EDITOR

using UnityEditor;
public class URP_BlinnPhong_Editor : ShaderGUI
{
    public enum ObjectType
    {
        Opaque, TransparentBlend, TransparentCutout
    }

    public enum FaceRenderingMode
    {
        FrontOnly, NoCulling, DoubleSided
    }

    public override void AssignNewShaderToMaterial(Material mat, Shader oldShader, Shader newShader)
    {
        base.AssignNewShaderToMaterial(mat, oldShader, newShader);
        if (newShader.name == "MyCustom_URP_Shader/URP_BlinnPhong")
        {
            ObjectTypeUpdate(mat);
            FaceModeUpdate(mat);
        }
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material mat = materialEditor.target as Material;

        var objectTypeProp = BaseShaderGUI.FindProperty("_ObjectType", properties, true);
        var FaceRenderingProp = BaseShaderGUI.FindProperty("_FaceRenderingMode", properties, true);

        EditorGUI.BeginChangeCheck();

        objectTypeProp.floatValue = (int)(ObjectType)EditorGUILayout.EnumPopup("Object type", (ObjectType)objectTypeProp.floatValue);
        FaceRenderingProp.floatValue = (int)(FaceRenderingMode)EditorGUILayout.EnumPopup("Face Rendering Mode", (FaceRenderingMode)FaceRenderingProp.floatValue);

        if (EditorGUI.EndChangeCheck())//do when user change value of objectTypeProp
        {
            ObjectTypeUpdate(mat);
            FaceModeUpdate(mat);
        }
        base.OnGUI(materialEditor, properties);
    }

    private void ObjectTypeUpdate(Material mat)
    {
        ObjectType type = (ObjectType)mat.GetFloat("_ObjectType");
        switch (type)
        {
            case ObjectType.Opaque:
                mat.renderQueue = (int)RenderQueue.Geometry;
                mat.SetOverrideTag("RenderType", "Opaque");
                break;
            case ObjectType.TransparentBlend:
                mat.renderQueue = (int)RenderQueue.Transparent;
                mat.SetOverrideTag("RenderType", "Transparent");
                break;
            case ObjectType.TransparentCutout:
                mat.renderQueue = (int)RenderQueue.AlphaTest;
                mat.SetOverrideTag("RenderType", "TransparentCutout");
                break;
        }

        switch (type)
        {
            case ObjectType.Opaque:
                mat.SetInt("_SrcBlend", (int)BlendMode.One);
                mat.SetInt("_DstBlend", (int)BlendMode.Zero);
                mat.SetInt("_ZWrite", 1);
                mat.SetShaderPassEnabled("ShadowCaster", true);
                mat.DisableKeyword("_ALPHA_CUTOUT");
                break;
            case ObjectType.TransparentBlend:
                mat.SetInt("_SrcBlend", (int)BlendMode.SrcAlpha);
                mat.SetInt("_DstBlend", (int)BlendMode.OneMinusSrcAlpha);
                mat.SetInt("_ZWrite", 0);
                mat.SetShaderPassEnabled("ShadowCaster", false);
                mat.DisableKeyword("_ALPHA_CUTOUT");
                break;
            case ObjectType.TransparentCutout:
                mat.SetInt("_SrcBlend", (int)BlendMode.One);
                mat.SetInt("_DstBlend", (int)BlendMode.Zero);
                mat.SetInt("_ZWrite", 1);
                mat.SetShaderPassEnabled("ShadowCaster", true);
                mat.EnableKeyword("_ALPHA_CUTOUT");
                break;

        }
    }

    private void FaceModeUpdate(Material mat)
    {
        FaceRenderingMode faceMode = (FaceRenderingMode)mat.GetFloat("_FaceRenderingMode");
        if (faceMode == FaceRenderingMode.FrontOnly)
        {
            mat.SetInt("_Cull", (int)CullMode.Back);
        }
        else
        {

            mat.SetInt("_Cull", (int)CullMode.Off);
        }

        if (faceMode == FaceRenderingMode.DoubleSided)
        {
            mat.EnableKeyword("_DOUBLE_SIDED_NORMALS");
        }
        else
        {
            mat.DisableKeyword("_DOUBLE_SIDED_NORMALS");
        }
    }
}
#endif

