            
            
            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID//GPU instancing
            };



            struct vertOut
            {
                float4 positionCS  : SV_POSITION;// HCS: H CLIP SPACE
                float2 uv:TEXCOORD0;
                //float4 screenPos : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 positionWS: TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID//GPU instancing
            };


            
            
            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _TerrainMap;
                float4 _Terrain;
                half4 _BaseColor,_TopColor;
                half4 _AmbientColor;
                float2 _WaveDir;
                float _WaveSpeed,_WaveStrength,_Randomize;
                float _Gloss;
                float _Luminosity,_DarkThreshold;
                float _MinAdditionalLightIntensity,_MinMainLightIntensity;
                float _TopIntensity,_BlendIntensity;
                //float4 _Time;
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                
                vertOut o;
                UNITY_SETUP_INSTANCE_ID(v);//GPU instancing
                UNITY_TRANSFER_INSTANCE_ID(v,o);//GPU instancing
                o.uv = v.uv;

                    float3 wPos = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                    float random = ( abs(wPos.x+wPos.z)*_Randomize ) ;
                    v.positionOS.x += sin( ( _Time.y + cos( random ) )*_WaveSpeed*2*PI )*o.uv.y*_WaveStrength*_WaveDir.x;
                    v.positionOS.z += sin( ( _Time.y + cos( random ) )*_WaveSpeed*2*PI )*o.uv.y*_WaveStrength*_WaveDir.y;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS);
                o.normalWS = normalInput.normalWS;
                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                //o.screenPos = ComputeScreenPos(o.positionCS);


                return o;
            }


            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                UNITY_SETUP_INSTANCE_ID(i);//GPU instancing


                //float4 terrainHeightTexture = tex2D(_TerrainHeightMap,i.uv);

                //float2 screenUV = i.screenPos.xy / i.screenPos.w;


                InputData inputdata = (InputData)0;
                float4 shadowMask = CalculateShadowMask(inputdata);
                float4 shadowcoord = TransformWorldToShadowCoord(i.positionWS);


                Light mainLight = GetMainLight(shadowcoord);



                float3 mainSpecularLight = SpecularLight(i.normalWS,i.positionWS,1-_Gloss,mainLight);
                mainSpecularLight = clamp(mainSpecularLight,_DarkThreshold,1) *_Luminosity;


                float4 terrainTex = tex2D(_TerrainMap, (i.positionWS.xz-_Terrain.zw)/_Terrain.xy);
                float4 gradientColor = lerp(terrainTex/float4( mainSpecularLight,1),  terrainTex*_TopIntensity+_TopColor, saturate( i.uv.y-_BlendIntensity));

                LightingData lightingData = (LightingData)0;
                float3 baseColor = gradientColor.rgb
                                   * mainLight.color
                                   * mainLight.shadowAttenuation 
                                   * mainSpecularLight
                                   * _AmbientColor.xyz
                                   * min( mainLight.distanceAttenuation,_MinMainLightIntensity);



                lightingData.mainLightColor  += baseColor;


                #if defined(_ADDITIONAL_LIGHTS)
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0; lightIndex < pixelLightCount; lightIndex++)
                    {
                        Light AddLight = GetAdditionalLight(lightIndex,i.positionWS,shadowMask);


                        float3 addSpecularLight = SpecularLight(i.normalWS,i.positionWS,1-_Gloss,AddLight);
                        addSpecularLight = clamp(addSpecularLight,_DarkThreshold,1) *_Luminosity;


                        float3 additionalColor = gradientColor.rgb
                                                * AddLight.color
                                                * AddLight.shadowAttenuation 
                                                * addSpecularLight
                                                * _AmbientColor.xyz
                                                * min(AddLight.distanceAttenuation,_MinAdditionalLightIntensity);


                        lightingData.additionalLightsColor += additionalColor;
                        
                    }
                #endif



                
                //return  2*i.uv.yyyy-1;
                return  CalculateFinalColor(lightingData,1);
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }