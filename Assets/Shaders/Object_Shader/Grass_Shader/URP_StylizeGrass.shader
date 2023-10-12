Shader "MyCustom_URP_Shader/URP_StylizeGrass"
{
    Properties
    {
        [Header(Rendering options)]
        _AnimationRenderDistance("Animation render distance", float) = 60

        [Header(Color options)]
        _MainTex("Texture", 2D) = "white"{}
        _TopColor("Top color", COLOR) = (0.2,0.8,0.2,1)
        _BottomColor("Bottom color", COLOR) = (0,0,0,1)

        [Header(Local animation options)]
        _WaveLocalStrength("Local wind strength", float) = 0.4
        _WaveLocalSpeed("Local wave speed", float) = 0.2
        _Randomize("Local cycle random intensity", Range(1,20)) = 20
        _WaveLocalDir("Local wind direction", vector) = (0.7,0.7,0,0)

        [Header(World animation options)]
        _WindTexture("Wind texture", 2D) = "bump"{}
        _WindTextureScale("Wind Texture Scale", float) = 0.01
        _WindTextureStrength("Wind Texture Strength", float) = 0.05
        _WindTextureSpeed("Wind Texture Speed", float) = 1
        [Header(.                                                                     .)]
        _WaveWorldSpeed("World wave speed",float) = 0.3
        _WaveWorldStrength("World wind strength", float) = 0.05
        _WaveWorldDir("World wind direction", vector) = (1,0,0,0)

        [Header(Lighting options)]
        _Gloss("Specular gloss", Range(0,1)) = 1
        _DayTimeAmbientColor("Day ambient color", COLOR) = (0,0,0,1)
        _NightTimeAmbientColor("Night ambient color",COLOR) = (0.5,0.5,0.5,1)
        _NightAmbientThreshold("Night ambient threshold",float) = 0.5
        _DarkThreshold("Dark threshold",Range(0,1)) = 0.6
        _Luminosity("Luminosity",float) = 1
        _TopIntensity("Grass top color intensity",float) = 1.2
        _MinAdditionalLightIntensity("Min additional light receive", Range(0,1)) = 1
        _MinMainLightIntensity("Min main light receive", Range(0,1)) = 1
        
        [Header(Terrain options)]
        _TerrainMap("Terrain map", 2D)= "white"{}
        //_TerranID("Terrain ID", Int) = 0
        _Terrain("Terrain size and offset", vector) = (0,0,0,0)
        _BlendIntensity("Blend intensity", Range(0,1)) = 0.2
        _InteractDistance("Interact with grass distance", float) = 1
        _InteractStrength("Interact grass strength",float) = 5

    }
    SubShader
    {
        Tags {  "RenderType" = "Opaque" 
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
