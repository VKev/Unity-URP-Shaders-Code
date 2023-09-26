
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

            UNITY_INSTANCING_BUFFER_START(props)
                UNITY_DEFINE_INSTANCED_PROP(float, _Gloss)
                UNITY_DEFINE_INSTANCED_PROP(float, _RimSize)
                UNITY_DEFINE_INSTANCED_PROP(float, _RimThreshold)
                UNITY_DEFINE_INSTANCED_PROP(float, _RimBlur)
                UNITY_DEFINE_INSTANCED_PROP(float4, _AmbientColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_INSTANCING_BUFFER_END(props)

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
                
                float _LightMaxIntensity;
                float _MainLightShadowIntensity;
            CBUFFER_END

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

                float gloss = UNITY_ACCESS_INSTANCED_PROP(props, _Gloss);
                float4 ambientColor = UNITY_ACCESS_INSTANCED_PROP(props, _AmbientColor);
                float4 Col = UNITY_ACCESS_INSTANCED_PROP(props, _Color);
                float rimSize = UNITY_ACCESS_INSTANCED_PROP(props, _RimSize);
                float rimBlur = UNITY_ACCESS_INSTANCED_PROP(props, _RimBlur);
                float rimThreshold = UNITY_ACCESS_INSTANCED_PROP(props, _RimThreshold);

                float4 mainTex = tex2D(_MainTex,i.uv);
                float3 N = normalize(i.normalWS);
                float3 wPos = i.positionWS;
                float3 V = GetWorldSpaceNormalizeViewDir(wPos);


                InputData inputdata = (InputData)0;
                float4 shadowMask = CalculateShadowMask(inputdata);

                
                float4 shadowcoord = TransformWorldToShadowCoord(wPos);
                Light mainLight = GetMainLight(shadowcoord);
                mainLight.shadowAttenuation *= _MainLightShadowIntensity;



                float3 baseColor = Col.rgb*mainTex.xyz*generateToonLightBlinnPhong(N,wPos,V,mainLight,ambientColor,gloss,rimSize,rimBlur,rimThreshold);
                


                LightingData lightingData = (LightingData)0;
                lightingData.mainLightColor  += baseColor;

                #if defined(_ADDITIONAL_LIGHTS)
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0; lightIndex < pixelLightCount; lightIndex++)
                    {
                        Light AddLight = GetAdditionalLight(lightIndex,wPos,shadowMask);
                        
                        float3 additionalColor = Col.rgb*mainTex.xyz*generateToonLightBlinnPhong(N,wPos,V,AddLight,ambientColor,gloss,rimSize,rimBlur,rimThreshold);
                        lightingData.additionalLightsColor += additionalColor;
                        
                    }
                #endif
                


                //return float4(additionalColor,1) ;
                return CalculateFinalColor(lightingData,1);
            }