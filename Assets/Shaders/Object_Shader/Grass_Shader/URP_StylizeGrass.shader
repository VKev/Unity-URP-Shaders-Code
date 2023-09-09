Shader "MyCustom_URP_Shader/URP_StylizeGrass"
{
    Properties
    {
        [Header(Rendering options)]
        _AnimationRenderDistance("Animation render distance", float) = 60

        
        //_Dither ("Dither texture", 2D) = "white" {}
        [Header(Color options)]
        _MainTex("Grass texture", 2D) = "white"{}
        _TopColor("Grass top color", COLOR) = (0.2,0.8,0.2,1)
        _BottomColor("Grass bottom color", COLOR) = (0,0,0,1)

        [Header(Local animation options)]
        _WaveLocalStrength("Local wind strength", float) = 0.4
        _WaveLocalSpeed("Local wave speed", Range(0.1, 0.5)) = 0.2
        _Randomize("Local random intensity", Range(1,20)) = 20
        _WaveLocalDir("Local wind direction", vector) = (0.7,0.7,0,0)

        [Header(World animation options)]
        _WaveWorldSpeed("World wave speed", Range(0.1, 0.5)) = 0.2
        _WaveWorldStrength("World wind strength", float) = 0.4
        _WaveWorldDir("World wind direction", vector) = (0.2,0.4,0,0)

        [Header(Lighting options)]
        _Gloss("Specular gloss", Range(0,1)) = 1
        _AmbientColor("Ambient color", COLOR) = (0,0,0,0)
        _DarkThreshold("Dark threshold",Range(0,1)) = 0.6
        _Luminosity("Luminosity",float) = 1
        _TopIntensity("Grass top color intensity",float) = 1.2
        _MinAdditionalLightIntensity("Min additional light receive", Range(0,1)) = 1
        _MinMainLightIntensity("Min main light receive", Range(0,1)) = 1
        
        [Header(Terrain options)]
        _TerrainMap("Terrain map", 2D)= "white"{}
        _Terrain("Terrain size and offset", vector) = (0,0,0,0)
        _BlendIntensity("Blend intensity", Range(0,1)) = 0.2
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
