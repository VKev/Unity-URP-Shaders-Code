Shader "MyCustom_URP_Shader/URP_Foliage"
{
    Properties
    {
        [Header(Rendering options)]
        _AnimationRenderDistance("Animation render distance", float) = 60

        [Header(Color options)]
        _Color("Color", COLOR) = (0.1,0.55,0,1 )
        _AmbientColor("Ambient color", COLOR) = (0.067,0.44,0,0)
        _Cutoff("Cutout Intensity", Range(0,1)) = 0.1

        [Header(Lighting options)]
        _Gloss("Gloss", Range(0,1)) = 1
        _SpecularIntensity("Specular Intensity", Range(0,1)) = 1
        _MinMainLightIntensity("Min main light receive", Range(0,1)) = 0.4
        _ShadowThreshold("Shadow threshold",float) = 0.2
        _ShadowIntensity("Shadow Intensity",float) = 1.5

        [Header(Texture options)]
        _MainTex ("Texture", 2D) = "white" {}
        _BlendEffect("Blend effect", Range(0,1)) = 1
        _FluffyScale("Fluffy scale",float) = 2
        _NormalRandom("Normal random scatter", float) = 1
        _TangentRandom("Tangent random scatter", float) = 1
        _BitangentRandom("Bitangent random scatter", float) = 1
        

        [Header(Local animation options)]
        _WaveLocalHorizontalAmplitude("Local wave horizontal amplitude", float) = 0.2
        _WaveLocalVerticalAmplitude("Local wave vertical amplitude", float) = 0.2
        _WaveLocalSpeed("Local wave speed", float) = 1
        _WaveLocalDir("Local wind direction", vector) = (0.7,0.2,0,0)
        
        [Header(World animation options)]
        _WaveWorldAmplitude("World wave amplitude", float) = 0.1
        _WaveWorldSpeed("World wave speed", float) = 1
        _WaveWorldDir("World wind direction", vector) = (0.4,0.4,0,0)

        [Header(Interact options)]
        _InteractDistance("Interact distance", float) = 1
        _InteractStrength("Interact strength", float) = 1
    }
    SubShader
    {
        Tags {  "RenderType" = "Opaque" 
                //"Queue" = "Transparent"
                "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Cull Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            


            #pragma multi_compile_instancing
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            //#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            //#pragma multi_compile_fragment _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/VkevShaderLib.hlsl"

           
            #include "Foliage_ForwardLit_Pass.hlsl"
            

            ENDHLSL
        }
        Pass {
            // The shadow caster pass, which draws to shadow maps
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ColorMask 0 // No color output, only depth
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/VkevShaderLib.hlsl"

            //#pragma shader_feature_local _ALPHA_CUTOUT
            //#pragma shader_feature_local _DOUBLE_SIDED_NORMALS
            #define _ALPHA_CUTOUT

            #include "Foliage_ShadowCaster_Pass.hlsl"

            ENDHLSL
        }
    }
}
