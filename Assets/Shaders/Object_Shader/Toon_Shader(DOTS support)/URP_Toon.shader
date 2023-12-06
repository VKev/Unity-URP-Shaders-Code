Shader "MyCustom_URP_Shader/URP_Toon"
{
    Properties
    {
        [Header(Color options)]
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Base Color", COLOR) = (1, 1, 1, 1)

        [Header(Lighting options)]
        _AmbientColor("Ambient Color", COLOR) = (0,0,0,0)
        _Gloss("Glossity", float) = 1
        _GlossIntensity("Gloss Intensity", float) = 1
        _LightMaxIntensity("Light Max receiver Intensity", float) = 0.4
        _MainLightShadowIntensity("Main light shadow receiver intensity",float) = 1
        _ShadowReceiveBlur("Shadow receive blur", float) = 0.3
        _Fresnel("Fresnel effect", float) = 0

        [Header(Rim options)]
        _RimSize("Rim Size", Range(0,1))=0.2
        _RimBlur("Rim Blur", Range(0,0.1))= 0.01
        _RimThreshold("Rim Threshold", Range(0.01,10))= 2

        [HideInInspector] _Pass("Pass", float) = 0

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
        LOD 100

        Pass
        {
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]

            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM

            #pragma target 4.5
			#pragma multi_compile_instancing
			#pragma vertex vert
			#pragma fragment frag

			#define _SPECULAR_COLOR

            
            #define _LIGHT_COOKIES
            //cal light shadow for main light and enable cascade
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE

            //supprot multiple light
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #define ADDITIONAL_LIGHT_CALCULATE_SHADOWS
            #pragma multi_compile _ _FORWARD_PLUS

            //#define USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA

            //enable soft shadow
            #pragma multi_compile_fragment _ _SHADOWS_SOFT


            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Assets/VkevShaderLib.hlsl"
            
            #include "Toon_ForwardLit_Pass.hlsl"

            ENDHLSL
        }

        Pass{
            name "ShadowCaster"
            Tags{"LightMode"= "ShadowCaster"}
            ColorMask 0 // No color output, only depth
            

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Toon_ShadowCaster_Pass.hlsl"
            ENDHLSL
        }
    }
    CustomEditor "URP_BlinnPhong_Editor"
}
