Shader "MyCustom_URP_Shader/URP_Toon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _DeffuseBlur("Deffuse Blur",Range(0,1))= 0
        _SpecularBlur("Specular Blur",Range(0.05,1)) = 0.06
        _AmbientColor("Ambient Color", Color) = (0, 0, 0, 0)
        _RimSize("Rim Size", Range(0,1))=0.2
        _RimBlur("Rim Blur", Range(0,0.1))= 0.01
        _RimThreshold("Rim Threshold", Range(0.01,10))= 2
        _ShadowBlur("Shadow Blur",Range(0,1)) = 0
        _ShadowThreshold("Shadow Threshold", Range(0,1)) = 0
        _ShadowIntensity("Shadow intensity",float) = 1
        _SpecularSmoothness("Specular Smooth", float) = 0
        _Metalness("Metalness", Range(0,1)) = 0
    }
    SubShader
    {
        Tags {  "RenderType" = "Opaque" 
                //"Queue" = "Transparent"
                "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            //specular of UniversalFragmentBlinnPhong only work with this define
            #define _SPECULAR_COLOR

            //cal light shadow for main light and enable cascade
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE

            //supprot multiple light
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS

            //enable soft shadow
            #pragma multi_compile_fragment _ _SHADOWS_SOFT


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "CustomCore.hlsl"

            #include "ForwardToon_Pass.hlsl"

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
            //supprot multiple light
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS

            #include "ShadowToon_Pass.hlsl"

            ENDHLSL
        }
    }
}
