            
            
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
                float2 _WaveLocalDir;


                float _WaveWorldSpeed,_WaveWorldStrength;
                float _RandomWorldLength;
                float2 _WaveWorldDir;


                float _Gloss;
                half4 _AmbientColor;
                float _TopIntensity;
                float _Luminosity,_DarkThreshold;
                float _MinAdditionalLightIntensity,_MinMainLightIntensity;
                
                sampler2D _TerrainMap;
                float4 _Terrain;
                float _BlendIntensity;
                float _InteractGrassStrength;
                
                float _InteractGrassDistance;
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
                
                    float3 dir = normalize( _PlayerWpos.xyz - o.positionWS.xyz);

                    float distanceToInteractGrass = distance(_PlayerWpos.xyz, o.positionWS);
                    distanceToInteractGrass = 1 - clamp(distanceToInteractGrass,0,_InteractGrassDistance)/_InteractGrassDistance;


                    float3 wPos = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                    float random = ( abs(wPos.x+wPos.z)*_Randomize ) ;

                    v.positionOS.xz += _WaveLocalStrength*(o.uv.y*normalize(_WaveLocalDir.xy)*sin( ( _Time.y + cos( random ) )*_WaveLocalSpeed*2*PI )  +  cos( random)*_RandomLocalLength );

                    float3 positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;

                    positionWS.xz -=  dir.xz*distanceToInteractGrass*o.uv.y*_InteractGrassStrength;

                    if (length(_WaveWorldDir.xy)>0 )
                        positionWS.xz +=  _WaveWorldStrength*( sin( ( _Time.y + (wPos.x)  )*_WaveWorldSpeed*2*PI )*o.uv.y*normalize( _WaveWorldDir.xy) +  cos( random)*_RandomWorldLength );

                    o.positionCS = TransformWorldToHClip(positionWS);
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