
Shader "MyCustom_URP_Shader/URP_BlinnPhong"
{

    Properties
    {
        _MainTex("Main Tex",2D) = "White" {}
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _SpecularSmoothness ("Specular Smoothness", float) = 0
        
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            //specular of UniversalFragmentBlinnPhong only work with this define
            #define _SPECULAR_COLOR

            //cal light shadow for main light and enable cascade
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE

            //enable soft shadow
            #pragma multi_compile_fragment _ _SHADOWS_SOFT


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

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "ShadowCaster_Pass.hlsl"

            ENDHLSL
        }
            
    }
}