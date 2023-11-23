
            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float3 normalOS : NORMAL;
                float4 tangentOS: TANGENT;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID//GPU instancing
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;// HCS: H CLIP SPACE
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD3;
                float2 uv:TEXCOORD0;
                float3 positionWS: TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID//GPU instancing
            };
            vertOut vert(appdata v)
            {
                vertOut o;
                UNITY_SETUP_INSTANCE_ID(v);//GPU instancing
                UNITY_TRANSFER_INSTANCE_ID(v,o);//GPU instancing
                o.uv = v.uv;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = normalInput.normalWS;//conver OS normal to WS normal
                o.tangentWS = float4(normalInput.tangentWS,v.tangentOS.w);

                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS; // convert OS position to WS position

                return o;
            }

            CBUFFER_START(UnityPerMaterial)
                float _LightMaxIntensity;
                float _MainLightShadowIntensity;
                float _Gloss;
                float _RimSize;
                float _RimThreshold;
                float _RimBlur;
                float4 _AmbientColor;
                float4 _Color;
            CBUFFER_END

            #if defined(UNITY_DOTS_INSTANCING_ENABLED)
                

                UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
					UNITY_DOTS_INSTANCED_PROP(float, _Gloss)
					UNITY_DOTS_INSTANCED_PROP(float, _LightMaxIntensity)
					UNITY_DOTS_INSTANCED_PROP(float, _MainLightShadowIntensity)
					UNITY_DOTS_INSTANCED_PROP(float, _RimSize)
                    UNITY_DOTS_INSTANCED_PROP(float, _RimThreshold)
                    UNITY_DOTS_INSTANCED_PROP(float, _RimBlur)
                    UNITY_DOTS_INSTANCED_PROP(float4, _AmbientColor)
                    UNITY_DOTS_INSTANCED_PROP(float4, _Color)
				UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
                #define _Gloss UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _Gloss)
                #define _LightMaxIntensity UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _LightMaxIntensity)
                #define _MainLightShadowIntensity UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _MainLightShadowIntensity)
                #define _RimSize UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _RimSize)
                #define _RimThreshold UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _RimThreshold)
                #define _RimBlur UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _RimBlur)
                #define _AmbientColor UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _AmbientColor)
                #define _Color UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _Color)


			#endif

            

            
            sampler2D _MainTex;

            float3 generateToonLightBlinnPhong(float3 N, float3 wPos, float3 V,Light light, float4 ambientColor, float gloss, float rimSize, float rimBlur, float rimThreshold){

                float3 L = normalize(light.direction); 
                float3 fresnel = 1-saturate(dot(N,V));//float3 L = normalize(GetAdditionalLight(0,N).direction); 

                float3 LightColor = light.color * min(light.distanceAttenuation , _LightMaxIntensity);

                float3 rim = smoothstep((1-rimSize) - rimBlur, (1-rimSize) +rimBlur, fresnel);
                rim *= fresnel*pow( saturate(dot(N,L)),rimThreshold);


                float3 deffuseLight = DeffuseLight(N,light);
                deffuseLight = smoothstep(0,0.01, deffuseLight );
                

                float3 specularLight = SpecularLight(N,wPos,gloss,light);
                specularLight = smoothstep(0.005,0.006,specularLight);

                

                //return float4(lambert.xxx,1) ;
                float3 Col = LightColor*( 
                deffuseLight *light.shadowAttenuation 
                + specularLight*light.shadowAttenuation 
                + ambientColor.rgb 
                + rim*light.shadowAttenuation );

                return Col;
            };
            
            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float gloss = _Gloss;
                float4 ambientColor = _AmbientColor;
                float4 Col = _Color;
                float rimSize = _RimSize;
                float rimBlur = _RimBlur;
                float rimThreshold = _RimThreshold;

                float4 mainTex = tex2D(_MainTex,i.uv);
                float3 N = normalize(i.normalWS);
                float3 wPos = i.positionWS;
                float3 V = GetWorldSpaceNormalizeViewDir(wPos);


                InputData inputData = (InputData)0;
                float4 shadowMask = CalculateShadowMask(inputData);

                
                float4 shadowcoord = TransformWorldToShadowCoord(wPos);
                Light mainLight = GetMainLight(shadowcoord);
                mainLight.shadowAttenuation *= _MainLightShadowIntensity;



                float3 baseColor = Col.rgb*mainTex.xyz*generateToonLightBlinnPhong(N,wPos,V,mainLight,ambientColor,gloss,rimSize,rimBlur,rimThreshold);
                


                LightingData lightingData = (LightingData)0;
                lightingData.mainLightColor  += baseColor;
                
                #if defined(_ADDITIONAL_LIGHTS)
                uint pixelLightCount = GetAdditionalLightsCount();

                #if USE_FORWARD_PLUS
                for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
                {
                    FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

                    Light AddLight = GetAdditionalLight(lightIndex, wPos, shadowMask);
                    float3 additionalColor = Col.rgb*mainTex.xyz*generateToonLightBlinnPhong(N,wPos,V,AddLight,ambientColor,gloss,rimSize,rimBlur,rimThreshold);
                    lightingData.additionalLightsColor += additionalColor;
                }
                #endif

                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light AddLight = GetAdditionalLight(lightIndex, wPos, shadowMask);
                    float3 additionalColor = Col.rgb*mainTex.xyz*generateToonLightBlinnPhong(N,wPos,V,AddLight,ambientColor,gloss,rimSize,rimBlur,rimThreshold);
                    lightingData.additionalLightsColor += additionalColor;
                LIGHT_LOOP_END
                #endif
                        //Light AddLight = GetAdditionalLight(lightIndex,wPos,shadowMask);
                        
                        ///float3 additionalColor = Col.rgb*mainTex.xyz*generateToonLightBlinnPhong(N,wPos,V,AddLight,ambientColor,gloss,rimSize,rimBlur,rimThreshold);
                        //lightingData.additionalLightsColor += additionalColor;

                


                //return float4(test,1) ;
                return CalculateFinalColor(lightingData,1);
            }