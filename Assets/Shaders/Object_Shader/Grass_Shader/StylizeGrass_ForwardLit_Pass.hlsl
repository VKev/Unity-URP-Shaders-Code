            
            
            struct appdata
            {
                float4 positionOS   : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID//GPU instancing
            };



            struct vertOut
            {
                float4 positionCS  : SV_POSITION;
                float2 uv:TEXCOORD0;
                float3 normalWS : TEXCOORD2;
                float3 positionWS: TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID//GPU instancing
            };

            //UNITY_INSTANCING_BUFFER_START(props)
                //UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            //UNITY_INSTANCING_BUFFER_END(props)
            

            CBUFFER_START(UnityPerMaterial)
                
                float _AnimationRenderDistance;

                half4 _TopColor,_BottomColor;
                sampler2D _MainTex;

                float _WaveLocalSpeed,_WaveLocalStrength;
                float _Randomize,_RandomLocalLength;
                float4 _WaveLocalDir;


                float _WaveWorldSpeed,_WaveWorldStrength;
                float _RandomWorldLength;
                float4 _WaveWorldDir;


                float _Gloss;
                half4 _AmbientColor;
                float _TopIntensity;
                float _Luminosity,_DarkThreshold;
                float _MinAdditionalLightIntensity,_MinMainLightIntensity;
                
                sampler2D _TerrainMap;
                float4 _Terrain;
                float _BlendIntensity;
                float _InteractStrength;
                float _InteractDistance;
                float4 _PlayerWpos;
            CBUFFER_END

     

            vertOut vert(appdata v)
            {
                
                vertOut o;
                UNITY_SETUP_INSTANCE_ID(v);//GPU instancing
                UNITY_TRANSFER_INSTANCE_ID(v,o);//GPU instancing

                o.uv = v.uv;
                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;


                float distanceToCamera = length(_WorldSpaceCameraPos - o.positionWS);
                if(distanceToCamera < _AnimationRenderDistance){
                
                    float3 directionToPlayer = normalize( _PlayerWpos.xyz - o.positionWS.xyz);

                    float distanceToPlayer = distance(_PlayerWpos.xyz, o.positionWS);
                    distanceToPlayer = 1 - clamp(distanceToPlayer,0,_InteractDistance)/_InteractDistance;


                    float3 wPos = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                    float random = Random(wPos,_Randomize) ;

                    v.positionOS.xz += WindHorizontalOS(v.uv, random, _WaveLocalSpeed,_WaveLocalStrength,_WaveLocalDir).xz;

                    float3 finalPositionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;

                    finalPositionWS.xz -=  directionToPlayer.xz*distanceToPlayer*o.uv.y*_InteractStrength;
                    finalPositionWS.y -=  directionToPlayer.y*distanceToPlayer*o.uv.y*1;

                    finalPositionWS.xz +=  WindHorizontalWS(v.uv, random, _WaveWorldSpeed,_WaveWorldStrength,_WaveWorldDir).xz;

                    o.positionCS = TransformWorldToHClip(finalPositionWS);
                }
                else{
                    o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                }


                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS);
                o.normalWS = normalInput.normalWS;
                //o.screenPos = ComputeScreenPos(o.positionCS);


                return o;
            }


            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                UNITY_SETUP_INSTANCE_ID(i);//GPU instancing
                //float4 col = UNITY_ACCESS_INSTANCED_PROP(props, _Color);

                //float4 terrainHeightTexture = tex2D(_TerrainHeightMap,i.uv);

                //float2 screenUV = i.screenPos.xy / i.screenPos.w;
                float distanceToCamera = length(_WorldSpaceCameraPos - i.positionWS);
                

                InputData inputdata = (InputData)0;
                float4 shadowMask = CalculateShadowMask(inputdata);
                float4 shadowcoord = TransformWorldToShadowCoord(i.positionWS);


                Light mainLight = GetMainLight(shadowcoord);

                float4 mainTex = tex2D(_MainTex,i.uv);

                float3 mainSpecularLight = SpecularLight(i.normalWS,i.positionWS,1-_Gloss,mainLight);
                mainSpecularLight = clamp(mainSpecularLight,_DarkThreshold,1) *_Luminosity;


                float4 terrainTex = tex2D(_TerrainMap, (i.positionWS.xz-_Terrain.zw)/_Terrain.xy);
                float4 gradientColor = lerp(terrainTex*mainTex/float4( mainSpecularLight,1) + _BottomColor,  (terrainTex*mainTex*_TopIntensity+_TopColor)*float4( mainLight.color,1), saturate( i.uv.y-_BlendIntensity));

                LightingData lightingData = (LightingData)0;
                float3 baseColor = gradientColor.rgb
                                   
                                   * mainLight.shadowAttenuation 
                                   * mainSpecularLight
                                   * min( mainLight.distanceAttenuation,_MinMainLightIntensity)

                                   * _AmbientColor.xyz;
                                   



                lightingData.mainLightColor  += baseColor;

                if(distanceToCamera < _AnimationRenderDistance){
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
                }



                
                //return  float4( distanceToInteractGrass.xxx,1);
                return  CalculateFinalColor(lightingData,1);
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }