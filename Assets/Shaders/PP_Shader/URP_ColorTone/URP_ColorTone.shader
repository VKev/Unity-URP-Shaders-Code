Shader "MyCustom_URP_Shader/URP_Outline"
{
    Properties
    {
        _MainTex("Texture",2D) =  "White"{}
        _ColorTone("Color", COLOR) = (0.5625,0.5625,0.5625,1)
        //_NormalThreshold("Normal Threshold", Range(0,1))= 0.3
        //_DepthThreshold("Depth Threshold",float)= 0.05

    }
    SubShader
    {
        Tags {  "RenderType" = "Opaque" 
                //"Queue" = "Transparent"
                "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        

        Pass
        {
            
            //Cull Front
            HLSLPROGRAM


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // The Blit.hlsl file provides the vertex shader (Vert),
            // input structure (Attributes) and output strucutre (Varyings)
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #pragma vertex Vert
            #pragma fragment frag

            sampler2D _CameraDepthTexture;
            sampler2D _CameraOpaqueTexture;
            
            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                float4 _MainTex_ST;
                float4 _MainTex_TexelSize;
                float4 _ColorTone;
                
            CBUFFER_END


            //float3 _LightDirection;
            half4 frag(Varyings i) : SV_Target//get front face of object
            {
                float4 mainTex = tex2D(_MainTex,i.texcoord);
                
                float4 Col = tex2D(_CameraOpaqueTexture, i.texcoord);
                return Col*_ColorTone;
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }

            ENDHLSL
        }
        
    }
}
