Shader "MyCustom_URP_Shader/URP_StylizeGrass"
{
    Properties
    {
        //_Dither ("Dither texture", 2D) = "white" {}
        _TopColor("Top Color", COLOR) = (0.2,0.8,0.2,1)
        _WaveStrength("Wind Strength", float) = 0.4
        _WaveSpeed("Wave Speed", Range(0.1, 0.5)) = 0.2
        _Randomize("Random intensity", Range(1,20)) = 20
        _WaveDir("Wind direction", vector) = (0.7,0.7,0,0)
        _Gloss("Gloss", Range(0,1)) = 1
        _AmbientColor("Ambient Color", COLOR) = (0,0,0,0)
        _DarkThreshold("Dark Threshold",Range(0,1)) = 0.5
        _Luminosity("Luminosity",float) = 1
        _MinAdditionalLightIntensity("Min Additional light receive", Range(0,1)) = 1
        _MinMainLightIntensity("Min Main light receive", Range(0,1)) = 1

        _TerrainMap("Terrain map", 2D)= "white"{}
        _Terrain("Terrain Size and Offset", vector) = (0,0,0,0)
        _BlendIntensity("Blend intensity", Range(0,1)) = 0.2
        _TopIntensity("Top intensity",float) = 1.2
        _InteractGrassDistance("Interact with grass distance", float) = 1
        _InteractGrassStrength("Interact grass strength",float) = 5

    }
    SubShader
    {
        Tags {  "RenderType" = "Opaque" 
                //"Queue" = "Transparent"
                "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        Cull Off

        //Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS



            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/VkevShaderLib.hlsl"
            

            #include "StylizeGrass_ForwardLit_Pass.hlsl"

            ENDHLSL
        }
    }
}
