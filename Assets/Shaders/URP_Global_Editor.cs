
using UnityEngine;
using UnityEngine.Rendering;

#if UNITY_EDITOR

using UnityEditor;
public class URP_Global_Editor : ShaderGUI
{
    public enum RenderingPath
    {
        Foward, FowardPlus
    }
    public enum Pass
    {
        ShadowCast, NonShadowCast
    }


    public override void AssignNewShaderToMaterial(Material mat, Shader oldShader, Shader newShader)
    {
        base.AssignNewShaderToMaterial(mat, oldShader, newShader);
        RenderingPathUpdate(mat);
        PassUpdate(mat);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material mat = materialEditor.target as Material;

        var renderingPathProp = BaseShaderGUI.FindProperty("_RenderingPath", properties, true);
        var passProp = BaseShaderGUI.FindProperty("_Pass", properties, true);

        EditorGUI.BeginChangeCheck();

        renderingPathProp.floatValue = (int)(RenderingPath)EditorGUILayout.EnumPopup("Rendering Path", (RenderingPath)renderingPathProp.floatValue);
        passProp.floatValue = (int)(Pass)EditorGUILayout.EnumPopup("Pass", (Pass)passProp.floatValue);

        if (EditorGUI.EndChangeCheck())//do when user change value of objectTypeProp
        {
            RenderingPathUpdate(mat);
            PassUpdate(mat);
        }
        base.OnGUI(materialEditor, properties);
    }

    private void RenderingPathUpdate(Material mat)
    {
        RenderingPath type = (RenderingPath)mat.GetFloat("_RenderingPath");

        switch (type)
        {
            case RenderingPath.Foward:
                mat.DisableKeyword("_FORWARD_PLUS");
                break;
            case RenderingPath.FowardPlus:
                mat.EnableKeyword("_FORWARD_PLUS");
                break;
        }
    }
    private void PassUpdate(Material mat)
    {
        Pass type = (Pass)mat.GetFloat("_Pass");

        switch (type)
        {
            case Pass.ShadowCast:
                mat.SetShaderPassEnabled("ShadowCaster", true);
                break;
            case Pass.NonShadowCast:
                mat.SetShaderPassEnabled("ShadowCaster", false);
                break;
        }
    }

}
#endif

