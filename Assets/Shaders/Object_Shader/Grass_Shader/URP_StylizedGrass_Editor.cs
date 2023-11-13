
using UnityEngine;
using UnityEngine.Rendering;

#if UNITY_EDITOR

using UnityEditor;
public class URP_StylizedGrass_Editor : ShaderGUI
{
    public enum RenderingPath
    {
        Foward, FowardPlus
    }


    public override void AssignNewShaderToMaterial(Material mat, Shader oldShader, Shader newShader)
    {
        base.AssignNewShaderToMaterial(mat, oldShader, newShader);
        RenderingPathUpdate(mat);
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material mat = materialEditor.target as Material;

        var renderingPathProp = BaseShaderGUI.FindProperty("_RenderingPath", properties, true);

        EditorGUI.BeginChangeCheck();

        renderingPathProp.floatValue = (int)(RenderingPath)EditorGUILayout.EnumPopup("Rendering Path", (RenderingPath)renderingPathProp.floatValue);

        if (EditorGUI.EndChangeCheck())//do when user change value of objectTypeProp
        {
            RenderingPathUpdate(mat);
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

}
#endif

