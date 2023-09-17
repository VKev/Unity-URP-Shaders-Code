Shader "MyCustom_URP_Shader/URP_Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Depth ("Depth", float) = 0
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




            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


            struct appdata
            {
                float4 positionOS   : POSITION;
                
                float2 uv : TEXCOORD0;
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;
                float2 uv:TEXCOORD0;
                float4 screenPosition: TEXCOORD1;
            };

 
            sampler2D _CameraOpaqueTexture;
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                half4 _BaseColor;
                float _Depth;
                
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                vertOut o;
                o.uv = v.uv;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.screenPosition = ComputeScreenPos(o.positionCS);

                return o;
            }

            

            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                float2 screenSpaceUV = i.screenPosition.xy/i.screenPosition.w;
                //i.screenPosition.a -= _Depth;
                float depth = SampleSceneDepth(screenSpaceUV);
                //depth = lerp (0,1,depth);
                //return float4 (_LightDirection,1);
                return float4( depth.xxx,0);
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }

            ENDHLSL
        }
    }
}
