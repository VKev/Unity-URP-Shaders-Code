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
                float3 tangentWS = BARYCENTRIC_INTERPOLATE(tangentWS);
                float2 waterUV = BARYCENTRIC_INTERPOLATE(waterUV);
                float2 foamUV = BARYCENTRIC_INTERPOLATE(foamUV);
                float4 screenPosition = BARYCENTRIC_INTERPOLATE(screenPosition);
                float3 biTangent = BARYCENTRIC_INTERPOLATE(biTangent);
                
                float waterGradientNoise;
                Unity_GradientNoise_float(waterUV, 1, waterGradientNoise);
                positionWS += _WaveStrength*(2*waterGradientNoise-1)*normalWS;

                output.waterUV = waterUV;
                output.foamUV = foamUV;
                output.screenPositionReal = ComputeScreenPos(TransformWorldToHClip(positionWS));
                output.screenPosition = screenPosition;
                output.tangentWS = tangentWS;
                output.positionCS = TransformWorldToHClip(positionWS);
                output.normalWS = normalWS;
                output.biTangent = biTangent;
                output.positionWS = positionWS;
                output.distanceToCam = dot(normalWS,  _WorldSpaceCameraPos - positionWS) >0? length( _WorldSpaceCameraPos - positionWS):  -length( _WorldSpaceCameraPos - positionWS) ;
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
                float2 screenSpaceUV = i.screenPositionReal.xy/i.screenPositionReal.w;

                float rawDepth = SampleSceneDepth(screenSpaceUV);
                float depthFade;
                if(i.distanceToCam >=0){
                    depthFade = DepthFade(rawDepth,_Depth, i.screenPositionReal);
                }else{
                    rawDepth = 1- rawDepth;
                    depthFade = DepthFade(rawDepth,-_Depth, i.screenPositionReal);
                }
                float4 normalWaterDepthCol = lerp(_BottomColor,_SurfaceColor, (1 - depthFade));


                float waterGradientNoise;
                Unity_GradientNoise_float(i.waterUV, 1, waterGradientNoise);




                float3 gradientNoiseNormal;
                float3x3 tangentMatrix = float3x3(i.tangentWS, i.biTangent,i.normalWS);

                Unity_NormalFromHeight_Tangent_float(waterGradientNoise, 0.1,i.positionWS,tangentMatrix,gradientNoiseNormal);
                gradientNoiseNormal *= _NoiseNormalStrength;
                gradientNoiseNormal += i.screenPosition.xyz ;
                float4 gradientNoiseScreenPos = float4(gradientNoiseNormal,i.screenPosition.w);
                float2 noiseScreenSpaceUV = gradientNoiseScreenPos.xy/gradientNoiseScreenPos.w;
                float noiseRawDepth = SampleSceneDepth(noiseScreenSpaceUV);
                float noiseRefractionCut = DepthFade(noiseRawDepth,_RefractionCut, gradientNoiseScreenPos) <1 ? 0:1;



                float noiseRefractionDepthFade;
                if(i.distanceToCam >=0){
                    noiseRefractionDepthFade = DepthFade(noiseRawDepth,_Depth, gradientNoiseScreenPos);
                }else{
                    noiseRawDepth = 1-noiseRawDepth;
                    noiseRefractionDepthFade = DepthFade(noiseRawDepth,-_Depth, gradientNoiseScreenPos) ;
                }
                float4 waterDepthCol = lerp(_BottomColor,_SurfaceColor, (1 - noiseRefractionDepthFade));
                waterDepthCol = lerp( normalWaterDepthCol, waterDepthCol, noiseRefractionCut);


                float4 waterDistortionCol = tex2Dproj(_CameraOpaqueTexture,gradientNoiseScreenPos);
                waterDistortionCol = lerp( tex2Dproj( _CameraOpaqueTexture, i.screenPositionReal  ), waterDistortionCol, noiseRefractionCut);
                




                float3 gradientNoiseNormalWS;
                Unity_NormalFromHeight_World_float(waterGradientNoise,0.1,i.positionWS,tangentMatrix,gradientNoiseNormalWS);




                float3 viewDir = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float3 reflectedDir = reflect( -viewDir, normalize( i.normalWS)*(1-_ReflectionNormalIntensity) +
                                                normalize( gradientNoiseNormalWS)*_ReflectionNormalIntensity);
                float4 reflectionCol = texCUBE(_ReflectionMap, reflectedDir);



                waterDistortionCol = lerp(waterDistortionCol ,reflectionCol, _ReflectionIntensity );


                float foamDepthFade;
                if(i.distanceToCam >=0){
                    foamDepthFade = DepthFade(rawDepth,_FoamAmount, i.screenPosition);
                }else{
                    foamDepthFade = DepthFade(1-rawDepth,_FoamAmount, i.screenPosition);
                }
                float foamRefractionCut = foamDepthFade <=0? 0:1;
                foamDepthFade *= _FoamCutoff;

                float foamGradientNoise;
                Unity_GradientNoise_float(i.foamUV, 1, foamGradientNoise);

                float foamCutoff = step(foamDepthFade, foamGradientNoise);
                foamCutoff *= _FoamColor.a;
                
                float4 foamColor = lerp(waterDepthCol, _FoamColor, foamCutoff);
                foamColor = lerp(float4(_BottomColor.xyz,0.3)*normalWaterDepthCol, foamColor, foamRefractionCut);
               





                float4 mainTex = tex2D(_MainTex,i.waterUV);
                float4 finalCol = lerp(waterDistortionCol, foamColor, foamColor.a);
                finalCol = lerp(mainTex,finalCol,_TextureBlend);




                //float3 gradientNoiseNormalWS;
                //Unity_NormalFromHeight_World_float(waterGradientNoise,0.1,i.positionWS,tangentMatrix,gradientNoiseNormalWS);

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
                return (finalCol) ;
                //return float4(normalize(input.normalWS),1);
            }