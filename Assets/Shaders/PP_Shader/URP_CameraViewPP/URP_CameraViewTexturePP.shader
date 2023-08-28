Shader "MyCustom_URP_Shader/URP_CameraViewPP"
{
    Properties
    {
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

            #define _GBUFFER_NORMALS_OCT
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DynamicScaling.hlsl"

            

            #pragma vertex vert
            #pragma fragment frag



            uniform float4 _BlitScaleBias;

            struct Attributes
            {
                uint vertexID : SV_VertexID;

            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv   : TEXCOORD0;
            };


            Varyings vert(Attributes v)
            {
                Varyings o;
                //float depth = tex2D(_CameraDepthTexture,i.uv).r;//depth texture
                //float3 worldPos = ComputeWorldSpacePosition(i.uv, depth, UNITY_MATRIX_I_VP);//World Pos texture
                //float3 worldNormal = normalize(cross(ddx(worldPos), ddy(worldPos)));//Approximate worldnormal texture
                float4 pos = GetFullScreenTriangleVertexPosition(v.vertexID);
                float2 uv  = GetFullScreenTriangleTexCoord(v.vertexID);

                o.positionCS = pos;
                o.uv   = DYNAMIC_SCALING_APPLY_SCALEBIAS(uv);

                return o;
            }


            //sampler2D _CameraDepthTexture;
            sampler2D _CameraOpaqueTexture;
            //sampler2D _CameraNormalsTexture;
            
            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                
                //sampler2D _MainTex;
                float4 _ColorTone;
                
            CBUFFER_END


            //float3 _LightDirection;
            half4 frag(Varyings i) : SV_Target//get front face of object
            {
                //float4 mainTex = tex2D(_MainTex,i.uv);
                //float depth = tex2D(_CameraDepthTexture,i.uv).r;//depth texture
                //float3 worldPos = ComputeWorldSpacePosition(i.uv, depth, UNITY_MATRIX_I_VP);//World Pos texture
                //float3 worldNormal = normalize(cross(ddx(worldPos), ddy(worldPos)));//Approximate worldnormal texture
                float4 Col = tex2D(_CameraOpaqueTexture, i.uv);

                return Col;
                //return float4(depth.xxx,1);
                //return float4(worldNormal,1);
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }

            ENDHLSL
        }
        
    }
}
