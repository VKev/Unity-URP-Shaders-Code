Shader "MyCustom_URP_Shader/URP_Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TextureBlend("Texture blend Intensity",float) =1
        _Depth ("Depth", float) = 10
        _SurfaceColor("Surface Color",COLOR) = (0.4 ,0.9 ,1 ,0.27 )
        _BottomColor("Bottom Color",COLOR) = (0.1 ,0.1 ,0.5 ,1 )

        _WaveSpeed("Wave speed", float) = 0.5
        _WaveScale("Wave scale", float) = 15
        _WaveStrength("Wave damping", float) = 0.1
        _NoiseNormalStrength("Wave strength", float) = 0.1
        _FoamAmount("Foam amount",float) = 1
        _FoamCutoff("Foam cutoff",float) = 2.5
        _FoamSpeed("Foam speed",float) = 0.05
        _FoamScale("Foam scale",float) = 2
        _FoamColor("Foam color", COLOR) = (1,1,1,0.5)
        _Gloss("Gloss", float) = 1
        _Smoothness("Smoothness",float)=1
        _SpecularIntensity("Specular Intensity",float) = 0.15
        _WaterShadow("Shadow Intensity",float) = -0.5
    }
    SubShader
    {
        Tags {  "RenderType" = "Transparent" 
                "Queue" = "Transparent"
                "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        ZWrite Off
        Cull Off
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #define _SPECULAR_COLOR

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/lighting.hlsl"
            #include "Assets/VkevShaderLib.hlsl"


            #include "Water_FowardLit_pass.hlsl"

            ENDHLSL
        }
    }
}
