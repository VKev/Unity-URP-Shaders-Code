
Shader "MyCustom_URP_Shader/URP_BlinnPhong"
{

    Properties
    {
        [Header(Surface options)]
        [NoScaleOffset][MainTexture] _MainTex("Main Tex",2D) = "White" {}
        [NoScaleOffset]_CutoutTex("Cutout Tex",2D) = "White"{}
        [NoScaleOffset][Normal]_NormalMap("Normal Map",2D) = "bump" {}
        _normalIntensity("Normal Intensity", Range(0,1)) = 1
        [NoScaleOffset]_EmissionMap("Emission Map",2D) = "White" {}
        [HDR] _EmissionColor("Emission Color",COLOR) = (0,0,0,0)
        [NoScaleOffset]_HeightMap("Height Map",2D) = "White" {}
        _HeightIntensity("Height Intensity", Range(0,1)) = 1
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _Cutoff("Cutout Intensity", Range(0,1)) = 0
        _SpecularSmoothness ("Specular Smoothness", float) = 0
        _Metalness("Metalness", Range(0,1)) = 0

        [HideInInspector] _Cull("Cull mode", float) = 2

        [HideInInspector] _SrcBlend("Src Blend",float) = 0
        [HideInInspector] _DstBlend("Dst Blend",float) = 0
        [HideInInspector] _ZWrite("ZWrite", float) = 0

        [HideInInspector] _ObjectType("Object Type", float) = 0
        [HideInInspector] _FaceRenderingMode("Face Rendering Mode", float) = 0
        
    }

    SubShader
    {
        Tags {  "RenderType" = "Opaque" 
                //"Queue" = "Transparent"
                "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            //specular of UniversalFragmentBlinnPhong only work with this define
            #define _SPECULAR_COLOR

            //cal light shadow for main light and enable cascade
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE

            //enable soft shadow
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #pragma shader_feature_local _ALPHA_CUTOUT
            #pragma shader_feature_local _DOUBLE_SIDED_NORMALS


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "ForwardLit_Pass.hlsl"

            ENDHLSL
        }

        Pass {
            // The shadow caster pass, which draws to shadow maps
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ColorMask 0 // No color output, only depth
            Cull [_Cull]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma shader_feature_local _ALPHA_CUTOUT
            #pragma shader_feature_local _DOUBLE_SIDED_NORMALS

            #include "ShadowCaster_Pass.hlsl"

            ENDHLSL
        }
            
    }
    CustomEditor "URP_BlinnPhong_Editor"
}