
            
            
            half3 calBP(Light light, InputData inputData, SurfaceData surfaceData)
            {
                half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
                half3 lightDiffuseColor = LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);

                half3 lightSpecularColor = half3(0,0,0);
                #if defined(_SPECGLOSSMAP) || defined(_SPECULAR_COLOR)
                half smoothness = exp2(10 * surfaceData.smoothness + 1);

                lightSpecularColor += LightingSpecular(attenuatedLightColor, light.direction, inputData.normalWS, inputData.viewDirectionWS, half4(surfaceData.specular, 1), smoothness);
                #endif

            #if _ALPHAPREMULTIPLY_ON
                return lightDiffuseColor * surfaceData.albedo * surfaceData.alpha + lightSpecularColor;
            #else
                return lightDiffuseColor * surfaceData.albedo + lightSpecularColor;
            #endif
            }

            half4 UFBP(InputData inputData, SurfaceData surfaceData)
            {

                uint meshRenderingLayers = GetMeshRenderingLayer();
                half4 shadowMask = CalculateShadowMask(inputData);
                AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
                Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

                MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, aoFactor);

                inputData.bakedGI *= surfaceData.albedo;

                LightingData lightingData = CreateLightingData(inputData, surfaceData);
                lightingData.mainLightColor += calBP(mainLight, inputData, surfaceData);

                #if defined(_ADDITIONAL_LIGHTS)
                    uint pixelLightCount = GetAdditionalLightsCount();

                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
                    lightingData.additionalLightsColor += calBP(light, inputData, surfaceData);
                LIGHT_LOOP_END
                #endif

                #if defined(_ADDITIONAL_LIGHTS_VERTEX)
                    lightingData.vertexLightingColor += inputData.vertexLighting * surfaceData.albedo;
                #endif

                return CalculateFinalColor(lightingData, surfaceData.alpha);
            }