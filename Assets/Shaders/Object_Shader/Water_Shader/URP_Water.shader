Shader "MyCustom_URP_Shader/URP_Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Depth ("Depth", float) = 10
        _SurfaceColor("Surface Color",COLOR) = (0.1 ,0.1 ,0.7 ,1 )
        _BottomColor("Bottom Color",COLOR) = (0.1 ,0.1 ,0.5 ,1 )

        _WaveSpeed("Wave speed", float) = 0.5
        _WaveScale("Wave scale", float) = 15
        _WaveStrength("Wave damping", float) = 1
        _NoiseNormalStrength("Wave strength", float) = 0.1
        _FoamAmount("Foam amount",float) = 1
        _FoamCutoff("Foam cutoff",float) = 2.5
        _FoamSpeed("Foam speed",float) = 0.05
        _FoamScale("Foam scale",float) = 2
        _FoamColor("Foam color", COLOR) = (0,0,0,0.5)
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




            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/lighting.hlsl"
            #include "Assets/VkevShaderLib.hlsl"


            struct appdata
            {
                float4 positionOS   : POSITION;
                float4 tangentOS: TANGENT;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;
                float2 waterUV:TEXCOORD0;
                float2 foamUV:TEXCOORD5;
                float4 screenPosition: TEXCOORD1;
                float3 normalWS: NORMAL;
                float3 tangentWS : TEXCOORD3;
                float3 biTangent : TEXCOORD2;
                float3 positionWS: TEXCOORD4;
            };

 
            sampler2D _CameraOpaqueTexture;
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                float4 _MainTex_ST;
                half4 _BaseColor;
                half4 _FoamColor;
                half4 _SurfaceColor;
                half4 _BottomColor;
                float _Depth;
                float _WaveSpeed;
                float _WaveScale;
                float _WaveStrength;
                float _FoamAmount;
                float _FoamCutoff;
                float _FoamSpeed;
                float _FoamScale;
                float _NoiseNormalStrength;
                
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                vertOut o;

                _MainTex_ST.zw += _Time.y*_WaveSpeed;
                _MainTex_ST.xy *= _WaveScale;
                o.waterUV = TRANSFORM_TEX(v.uv, _MainTex);

                _MainTex_ST.zw += _Time.y*_FoamSpeed;
                _MainTex_ST.xy *= _FoamScale;
                o.foamUV = TRANSFORM_TEX(v.uv, _MainTex);

                float waterGradientNoise;
                Unity_GradientNoise_float(o.waterUV, 1, waterGradientNoise);
                v.positionOS.y += _WaveStrength*(2*waterGradientNoise-1);

                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                o.normalWS = GetVertexNormalInputs(v.normalOS).normalWS;//conver OS normal to WS normal
                o.tangentWS = GetVertexNormalInputs(v.normalOS,v.tangentOS).tangentWS;
                o.biTangent = cross(o.normalWS, o.tangentWS)
                              * (v.tangentOS.w) 
                              * (unity_WorldTransformParams.w);

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.screenPosition = ComputeScreenPos(o.positionCS);

                return o;
            }

            float DepthFade (float rawDepth,float strength, float4 screenPosition){
                float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                float depthFade = sceneEyeDepth;
                depthFade -= screenPosition.a;
                depthFade /= strength;
                depthFade = saturate(depthFade);
                return depthFade;
            }

            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                
                
                float2 screenSpaceUV = i.screenPosition.xy/i.screenPosition.w;
                
                float rawDepth = SampleSceneDepth(screenSpaceUV);
                float depthFade = DepthFade(rawDepth,_Depth, i.screenPosition);
                float4 waterDepthCol = lerp(_BottomColor,_SurfaceColor,1-depthFade);




                float waterGradientNoise;
                Unity_GradientNoise_float(i.waterUV, 1, waterGradientNoise);

                float3 gradientNoiseNormal;
                float3x3 tangentMatrix = float3x3(i.tangentWS, i.biTangent,i.normalWS);
                Unity_NormalFromHeight_Tangent_float(waterGradientNoise, 0.1,i.positionWS,tangentMatrix,gradientNoiseNormal);
                gradientNoiseNormal *= _NoiseNormalStrength;

                gradientNoiseNormal += i.screenPosition.xyz ;
                float4 gradientNoiseScreenPos = float4(gradientNoiseNormal,i.screenPosition.w );
                float4 waterDistortionCol = tex2Dproj(_CameraOpaqueTexture,gradientNoiseScreenPos);



                float foamDepthFade = DepthFade(rawDepth,_FoamAmount, i.screenPosition);
                foamDepthFade *= _FoamCutoff;

                float foamGradientNoise;
                Unity_GradientNoise_float(i.foamUV, 1, foamGradientNoise);

                float foamCutoff = step(foamDepthFade, foamGradientNoise);
                foamCutoff *= _FoamColor.a;

                float4 foamColor = lerp(waterDepthCol, _FoamColor, foamCutoff);

                float4 finalCol = lerp(waterDistortionCol, foamColor, foamColor.a);
                
                //return gradientNoise;
               return finalCol;
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }

            ENDHLSL
        }
    }
}
