Shader "MyCustom_URP_Shader/URP_OutlinePP"
{
    Properties
    {
        
        _OutlineSize ("Scale", float) = 1
        _OutlineColor("Outline Color", COLOR) = (0.5625,0.5625,0.5625,1)
        _NormalThreshold("Normal Threshold", Range(0,1))= 0.3
        _DepthThreshold("Depth Threshold",float)= 0.05

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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
           
            

            #pragma vertex vert
            #pragma fragment frag


            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv: TEXCOORD0;

            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv   : TEXCOORD0;
            };


            Varyings vert(Attributes v)
            {
                Varyings o;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv   = v.uv;

                return o;
            }


            sampler2D _CameraDepthTexture;
            sampler2D _CameraOpaqueTexture;
            float4 _CameraOpaqueTexture_TexelSize;
            float4 _OutlineColor;
            float _OutlineSize,_NormalThreshold,_DepthThreshold;
            //sampler2D _CameraNormalsTexture;
            
            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                float4 _ColorTone;
                
            CBUFFER_END

            float3 sampleWorldNormal(float2 uv)
            {
                float2 uv0 = uv; // center
                float2 uv1 = uv + float2(_CameraOpaqueTexture_TexelSize.x, 0); // right 
                float2 uv2 = uv + float2(0, _CameraOpaqueTexture_TexelSize.y); // top

                float depthCenter = tex2D(_CameraDepthTexture,uv0).r;
                float depthRight = tex2D(_CameraDepthTexture,uv1).r;
                float depthUp = tex2D(_CameraDepthTexture,uv2).r;

                float3 P0 = ComputeWorldSpacePosition(uv0, depthCenter, UNITY_MATRIX_I_VP);
                float3 P1 = ComputeWorldSpacePosition(uv1, depthRight, UNITY_MATRIX_I_VP);
                float3 P2 = ComputeWorldSpacePosition(uv2, depthUp, UNITY_MATRIX_I_VP);

                return normalize(cross(P2 - P0, P1 - P0));

            }

            //float3 _LightDirection;
            half4 frag(Varyings i) : SV_Target//get front face of object
            {
                //float4 mainTex = tex2D(_MainTex,i.uv);
                float cameraDepthTexture = tex2D(_CameraDepthTexture,i.uv).r;//depth texture
                float4 cameraColorTexture = tex2D(_CameraOpaqueTexture,i.uv);//SampleSceneNormals( i.uv);
                float3 cameraWorldNormalTexture = sampleWorldNormal(i.uv);
                //float depth = SampleSceneDepth(i.uv);//depth texture
                float3 worldPos = ComputeWorldSpacePosition(i.uv, cameraDepthTexture, UNITY_MATRIX_I_VP);//World Pos texture
                float3 V = GetWorldSpaceNormalizeViewDir(worldPos);
                float2 screenSpaceUV = i.uv;
                float fresnel = 1-saturate(dot(V,cameraWorldNormalTexture));
                //world normal tex improve 
                
                
                float normalThreshold = (1 + fresnel)*(1-_NormalThreshold);
                float depthThreshold = _DepthThreshold*( 1 + fresnel) ;


                float halfScaleFloor = floor(_OutlineSize * 0.5);
                float halfScaleCeil = ceil(_OutlineSize * 0.5);
                float2 bottomLeftScreenUV = screenSpaceUV - float2(_CameraOpaqueTexture_TexelSize.x, _CameraOpaqueTexture_TexelSize.y) * halfScaleFloor;
                float2 topRightScreenUV =screenSpaceUV + float2(_CameraOpaqueTexture_TexelSize.x, _CameraOpaqueTexture_TexelSize.y) * halfScaleCeil;  
                float2 bottomRightScreenUV = screenSpaceUV + float2(_CameraOpaqueTexture_TexelSize.x * halfScaleCeil, -_CameraOpaqueTexture_TexelSize.y * halfScaleFloor);
                float2 topLeftScreenUV = screenSpaceUV + float2(-_CameraOpaqueTexture_TexelSize.x * halfScaleFloor, _CameraOpaqueTexture_TexelSize.y * halfScaleCeil);

                
                //get neighbor depth value
                float depth0 = tex2D(_CameraDepthTexture,bottomLeftScreenUV).r;
                float depth1 = tex2D(_CameraDepthTexture,topRightScreenUV).r;
                float depth2 = tex2D(_CameraDepthTexture,bottomRightScreenUV).r;
                float depth3 = tex2D(_CameraDepthTexture,topLeftScreenUV).r;

                //compare depth different between 2 oposite pixel
                float depthFiniteDifference0 = depth1 - depth0;
                float depthFiniteDifference1 = depth3 - depth2;
                float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
               
                //set depth value in only 1 and 0
                edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

                float edge;
                if(cameraDepthTexture>0){
                    
                    float3 screenSpaceNormal0 = sampleWorldNormal( bottomLeftScreenUV);
                    float3 screenSpaceNormal1 = sampleWorldNormal(  topRightScreenUV);
                    float3 screenSpaceNormal2 = sampleWorldNormal( bottomRightScreenUV);
                    float3 screenSpaceNormal3 = sampleWorldNormal(  topLeftScreenUV);

                    //compare normal different between 2 oposite pixel
                    float3 normalFiniteDifference0 = screenSpaceNormal1 - screenSpaceNormal0;
                    float3 normalFiniteDifference1 = screenSpaceNormal3 - screenSpaceNormal2;
                    float edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
               

                    //set edge normal to onlyy 1 and 0
                    edgeNormal = edgeNormal > normalThreshold ? 1 : 0;
                    edge = max(edgeDepth, edgeNormal);
                }else{
                    edge = edgeDepth;
                }

                float4 finalColor = lerp(cameraColorTexture ,_OutlineColor, edge.xxxx);
                //float3 worldNormal = normalize(cross(ddx(worldPos), ddy(worldPos)));//Approximate worldnormal texture

                //return Col*_ColorTone;
                return finalColor;
                //return float4(Col,1);
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }

            ENDHLSL
        }
        
    }
}
