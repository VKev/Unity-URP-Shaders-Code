Shader "MyCustom_URP_Shader/URP_TessellatedWater" {
    Properties{
        _FactorEdge1("Edge factors", Vector) = (3, 3, 3, 0)

        _FactorInside("Inside factor", Float) = 1

        _InteractFactorInside("Interact_ Inside factor", Float) = 10
        _InteractTessellatedRange("Interact_ Tessellated Range", float) = 1.5
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

        _RefractionCut("Refraction Cut", float) = 1

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

            struct Attributes {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS: TANGENT;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct TessellationControlPoint {
                float3 positionWS : INTERNALTESSPOS;
                float3 inverseNormalDir: TEXCOORD4;
                float3 normalWS : NORMAL;
                float3 tangentWS:TANGENT;
                float3 biTangent: TEXCOORD1;
                float4 screenPosition: TEXCOORD3;
                float2 waterUV: TEXCOORD2;
                float2 foamUV: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct TessellationFactors {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            

            struct domaOut {
                float4 positionCS  : SV_POSITION;
                float2 waterUV:TEXCOORD0;
                float2 foamUV:TEXCOORD5;
                float4 screenPosition: TEXCOORD1;
                float4 screenPositionReal: TEXCOORD6;
                float3 normalWS: NORMAL;
                float3 tangentWS : TEXCOORD3;
                float3 biTangent : TEXCOORD2;
                float3 positionWS: TEXCOORD4;
                float3 inverseNormalDir: TEXCOORD7;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            float4x4 _Object2World;
            
            sampler2D _CameraOpaqueTexture;
            float4x4 _World2Object;
            CBUFFER_START(UnityPerMaterial)
                float3 _FactorEdge1;
                float _FactorInside;
                sampler2D _MainTex;
                float _TextureBlend;
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
                float _SpecularIntensity;
                float _Gloss;
                float _Smoothness;
                float _NoiseNormalStrength;
                float _WaterShadow;
                float _InteractFactorInside;
                float _InteractTessellatedRange;
                float _RefractionCut;
                float _ReflectionIntensity;
                float _ReflectionNormalIntensity;
                float4 _PlayerWpos;
                uniform samplerCUBE _ReflectionMap;
            CBUFFER_END

            float3 GetViewDirectionFromPosition(float3 positionWS) {
                return normalize(GetCameraPositionWS() - positionWS);
            }

            

            TessellationControlPoint Vertex(Attributes input) {
                TessellationControlPoint output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                _MainTex_ST.zw += _Time.y*_WaveSpeed;
                _MainTex_ST.xy *= _WaveScale;
                output.waterUV = TRANSFORM_TEX(input.uv, _MainTex);

                _MainTex_ST.zw += _Time.y*_FoamSpeed;
                _MainTex_ST.xy *= _FoamScale;
                output.foamUV = TRANSFORM_TEX(input.uv, _MainTex);

                VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                output.tangentWS = GetVertexNormalInputs(input.normalOS,input.tangentOS).tangentWS;
                output.normalWS = normalInputs.normalWS;
                output.biTangent = cross(output.normalWS, output.tangentWS)
                              * (input.tangentOS.w) 
                              * (unity_WorldTransformParams.w);
                
                output.inverseNormalDir = mul (input.normalOS, _World2Object);
                output.positionWS = posnInputs.positionWS;
                output.screenPosition = ComputeScreenPos(TransformObjectToHClip(input.positionOS.xyz));
                return output;
            }

            // The patch constant function runs once per triangle, or "patch"
            TessellationFactors PatchConstantFunction(
                InputPatch<TessellationControlPoint, 3> patch) {
                UNITY_SETUP_INSTANCE_ID(patch[0]); 

                float distance1 = distance(_PlayerWpos.xyz, patch[0].positionWS);
                float distance2 = distance(_PlayerWpos.xyz, patch[1].positionWS);
                float distance3 = distance(_PlayerWpos.xyz, patch[2].positionWS);
                float distance =  min(min(distance1, distance2), distance3);
                float distanceToPlayer1 = distance;
                distanceToPlayer1 = 1 - clamp(distanceToPlayer1,0,_InteractTessellatedRange)/_InteractTessellatedRange;

                TessellationFactors f;
                if(distanceToPlayer1 >0){
                    f.edge[0] = _FactorEdge1.x;
                    f.edge[1] = _FactorEdge1.y;
                    f.edge[2] = _FactorEdge1.z;
                    f.inside = _InteractFactorInside;
                }else{
                    f.edge[0] = _FactorEdge1.x;
                    f.edge[1] = _FactorEdge1.y;
                    f.edge[2] = _FactorEdge1.z;
                    f.inside = _FactorInside;
                }

                return f;
            }

            // The hull function runs once per vertex. You can use it to modify vertex
            [domain("tri")] // Signal we're inputting triangles
            [outputcontrolpoints(3)] // Triangles have three points
            [outputtopology("triangle_cw")] // Signal we're outputting triangles
            [patchconstantfunc("PatchConstantFunction")] // Register the patch constant function
             [partitioning("integer")]
            TessellationControlPoint Hull(
                InputPatch<TessellationControlPoint, 3> patch, 
                uint id : SV_OutputControlPointID) { 

                return patch[id];
            }

            // Call this macro to interpolate between a triangle patch, passing the field name
            #define BARYCENTRIC_INTERPOLATE(fieldName) \
		            patch[0].fieldName * barycentricCoordinates.x + \
		            patch[1].fieldName * barycentricCoordinates.y + \
		            patch[2].fieldName * barycentricCoordinates.z

            // The domain function runs once per vertex in the final, tessellated mesh
            [domain("tri")] 
            domaOut Domain(
                TessellationFactors factors, 
                OutputPatch<TessellationControlPoint, 3> patch, 
                float3 barycentricCoordinates : SV_DomainLocation) { 

                domaOut output;

                UNITY_SETUP_INSTANCE_ID(patch[0]);
                UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 positionWS = BARYCENTRIC_INTERPOLATE(positionWS);
                float3 normalWS = BARYCENTRIC_INTERPOLATE(normalWS);
                float3 inverseNormalDir = BARYCENTRIC_INTERPOLATE(inverseNormalDir);
                float3 tangentWS = BARYCENTRIC_INTERPOLATE(tangentWS);
                float2 waterUV = BARYCENTRIC_INTERPOLATE(waterUV);
                float2 foamUV = BARYCENTRIC_INTERPOLATE(foamUV);
                float4 screenPosition = BARYCENTRIC_INTERPOLATE(screenPosition);
                float3 biTangent = BARYCENTRIC_INTERPOLATE(biTangent);
                
                float waterGradientNoise;
                Unity_GradientNoise_float(waterUV, 1, waterGradientNoise);
                positionWS.y += _WaveStrength*(2*waterGradientNoise-1);

                output.waterUV = waterUV;
                output.foamUV = foamUV;
                output.screenPositionReal = ComputeScreenPos(TransformWorldToHClip(positionWS));
                output.screenPosition = screenPosition;
                output.tangentWS = tangentWS;
                output.positionCS = TransformWorldToHClip(positionWS);
                output.normalWS = normalWS;
                output.biTangent = biTangent;
                output.positionWS = positionWS;
                output.inverseNormalDir = inverseNormalDir;
                return output;
            }
            float DepthFade (float rawDepth,float strength, float4 screenPosition){
                float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                float depthFade = sceneEyeDepth;
                depthFade -= screenPosition.a;
                depthFade /= strength;
                depthFade = saturate(depthFade);
                return depthFade;
            }

 
            float4 Fragment(domaOut i) : SV_Target{
                UNITY_SETUP_INSTANCE_ID(i);
                float2 screenSpaceUV = i.screenPosition.xy/i.screenPosition.w;
                
                float rawDepth = SampleSceneDepth(screenSpaceUV);
                float depthFade = DepthFade(rawDepth,_Depth, i.screenPosition);
                float RefractionCut = depthFade <=0 ? 0:1;
                float4 waterDepthCol = lerp(_BottomColor,_SurfaceColor,(1-depthFade));
                



                float waterGradientNoise;
                Unity_GradientNoise_float(i.waterUV, 1, waterGradientNoise);

                float3 gradientNoiseNormal;
                float3x3 tangentMatrix = float3x3(i.tangentWS, i.biTangent,i.normalWS);
                Unity_NormalFromHeight_Tangent_float(waterGradientNoise, 0.1,i.positionWS,tangentMatrix,gradientNoiseNormal);
                gradientNoiseNormal *= _NoiseNormalStrength;

                gradientNoiseNormal += i.screenPosition.xyz ;

                float4 gradientNoiseScreenPos = float4(gradientNoiseNormal,i.screenPosition.w );

                float2 noiseScreenSpaceUV = gradientNoiseScreenPos.xy/gradientNoiseScreenPos.w;
                float noiseRawDepth = SampleSceneDepth(noiseScreenSpaceUV);
                float noiseRefractionCut = DepthFade(noiseRawDepth,_RefractionCut, gradientNoiseScreenPos) <1 ? 0:1;

                
                
                float4 waterDistortionCol = tex2Dproj(_CameraOpaqueTexture,gradientNoiseScreenPos);
                waterDistortionCol = lerp( tex2Dproj( _CameraOpaqueTexture, i.screenPositionReal ), waterDistortionCol, noiseRefractionCut);

                float3 viewDir = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float3 reflectedDir = reflect( -viewDir, i.inverseNormalDir);
                float4 reflectionCol = texCUBE(_ReflectionMap, reflectedDir);
                waterDistortionCol = lerp(waterDistortionCol ,reflectionCol, _ReflectionIntensity );


                float foamDepthFade = DepthFade(rawDepth,_FoamAmount, i.screenPosition);
                foamDepthFade *= _FoamCutoff;

                float foamGradientNoise;
                Unity_GradientNoise_float(i.foamUV, 1, foamGradientNoise);

                float foamCutoff = step(foamDepthFade, foamGradientNoise);
                foamCutoff *= _FoamColor.a*RefractionCut;
                
                float4 foamColor = lerp(waterDepthCol, _FoamColor, foamCutoff);


                float4 mainTex = tex2D(_MainTex,i.waterUV);
                float4 finalCol = lerp(waterDistortionCol, foamColor, foamColor.a);
                finalCol = lerp(mainTex,finalCol,_TextureBlend);




                float3 gradientNoiseNormalWS;
                Unity_NormalFromHeight_World_float(waterGradientNoise,0.1,i.positionWS,tangentMatrix,gradientNoiseNormalWS);

                InputData inputData = (InputData)0;
                inputData.normalWS = gradientNoiseNormalWS;
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(i.positionWS);

               
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = float3(1,1,1)*_WaterShadow;
                surfaceData.alpha = 1;
                surfaceData.specular = _Gloss;
                surfaceData.smoothness = _Smoothness;
                
                finalCol = finalCol + UniversalFragmentBlinnPhong(inputData , surfaceData)*_SpecularIntensity;
                //return texCUBE(_ReflectionMap, reflectedDir);
                return finalCol ;
                //return float4(normalize(input.normalWS),1);
            }

            #endif
            ENDHLSL
        }
    }
}