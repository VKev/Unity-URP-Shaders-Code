Shader "MyCustom_URP_Shader/URP_TessellatedWater" {
    Properties{
        [Header(Tessellation option)]
        _FactorEdge1("Edge factors", Vector) = (3, 3, 3, 0)
        _FactorInside("Inside factor", Float) = 1

        [Header(Tessellation interact option)]
        _InteractFactorInside("Inside factor", Float) = 10
        _InteractTessellatedRange("Tessellated Range", float) = 1.5

        [Header(Color option)]
        _MainTex ("Texture", 2D) = "white" {}
        _TextureBlend("Texture blend Intensity",float) =1
        _Depth ("Depth", float) = 10
        _SurfaceColor("Surface Color",COLOR) = (0.4 ,0.9 ,1 ,0.27 )
        _BottomColor("Bottom Color",COLOR) = (0.1 ,0.1 ,0.5 ,1 )

        [Header(Wave animation option)]
        _WaveSpeed("Speed", float) = 0.5
        _WaveScale("Scale", float) = 15
        _WaveStrength("Damping", float) = 0.1
        _NoiseNormalStrength("Strength", float) = 0.1

        [Header(Foam animation option)]
        _FoamAmount("Amount",float) = 1
        _FoamCutoff("Cutoff",float) = 2.5
        _FoamSpeed("Speed",float) = 0.05
        _FoamScale("Scale",float) = 2
        _FoamColor("Color", COLOR) = (1,1,1,0.5)

        [Header(Lighting option)]
        _Gloss("Gloss", float) = 1
        _Smoothness("Smoothness",float)=1
        _SpecularIntensity("Specular Intensity",float) = 0.15
        _WaterShadow("Shadow Intensity",float) = -0.5


        [Header(Refraction option)]
        _RefractionCut("Refraction Cut", float) = 1

        [Header(Reflection option)]
        _ReflectionMap ("Reflection Map", Cube) = ""
        _ReflectionIntensity("Reflection Intensity", float) = 0.3
        _ReflectionNormalIntensity("Reflection Normal Intensity", float) = 0.3
    }
    SubShader{
        Tags{"RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 100
        ZWrite Off
        Cull Off
        Pass {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            
           
            HLSLPROGRAM
            #pragma target 5.0 // 5.0 required for tessellation

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #pragma vertex Vertex
            #pragma hull Hull
            #pragma domain Domain
            #pragma fragment Fragment

            #ifndef TESSELLATION_FACTORS_INCLUDED
            #define TESSELLATION_FACTORS_INCLUDED
            #define _SPECULAR_COLOR
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Assets/VkevShaderLib.hlsl"

            #include "TessellatedWater_VertHull.hlsl"
            #include "TessellatedWater_DomainFrag.hlsl"

            #endif
            ENDHLSL
        }
    }
}