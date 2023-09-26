Shader "MyCustom_URP_Shader/URP_Unlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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


            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/VkevShaderLib.hlsl"

            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float4 tangentOS: TANGENT;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;// HCS: H CLIP SPACE
                float2 uv:TEXCOORD0;
                float3 positionWS:TEXCOORD2;
            };

            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                half4 _BaseColor;
                
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                vertOut o;
                o.uv = v.uv;
                float4 modifiedPos = v.positionOS;

                modifiedPos.x +=sin(v.positionOS.y+_Time.y)+1;

                o.positionWS = GetVertexPositionInputs(modifiedPos.xyz).positionWS;

               // o.normalWS = GetVertexNormalInputs(normalize(modifiedNormal)).normalWS;
                v.positionOS = modifiedPos;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                

                return o;
            }

            

            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                
                float3 ddxPos = ddx(i.positionWS);
                float3 ddyPos = ddy(i.positionWS)  * _ProjectionParams.x;
                float3 normalWS = normalize( cross(ddxPos, ddyPos));

                InputData inputData = (InputData)0;//declare InputData struct
                inputData.normalWS = normalWS;// if front face return 1 else return -1
                inputData.positionWS = i.positionWS;
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(i.positionWS);//get view dir base on positionWS
                inputData.shadowCoord = TransformWorldToShadowCoord(i.positionWS);//get shadowcoord base on position WS

                

                SurfaceData surfaceData = (SurfaceData)0;//declare SurfaceData 
                surfaceData.albedo = normalWS;
                surfaceData.alpha = 1;
                surfaceData.specular = 1;
                //return float4 (_LightDirection,1);
                return  UniversalFragmentBlinnPhong(inputData , surfaceData);
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }

            ENDHLSL
        }
    }
}
