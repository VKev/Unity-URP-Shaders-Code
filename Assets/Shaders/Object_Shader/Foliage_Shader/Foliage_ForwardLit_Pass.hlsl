struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float2 uv : TEXCOORD0;
                float4 tangentOS: TANGENT;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;// HCS: H CLIP SPACE
                float2 uv:TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 tangentWS : TEXCOORD3;
                float3 biTangent : TEXCOORD2;
                float3 positionWS: TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            UNITY_INSTANCING_BUFFER_START(props)
                UNITY_DEFINE_INSTANCED_PROP(float, _FluffyScale)
                 UNITY_DEFINE_INSTANCED_PROP(float, _BlendEffect)
                 UNITY_DEFINE_INSTANCED_PROP(float, _NormalRandom)
                 UNITY_DEFINE_INSTANCED_PROP(float, _TangentRandom)
                 UNITY_DEFINE_INSTANCED_PROP(float, _BitangentRandom)
                 UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                 UNITY_DEFINE_INSTANCED_PROP(float4, _AmbientColor)
                 UNITY_DEFINE_INSTANCED_PROP(float, _WaveLocalHorizontalAmplitude)
                 UNITY_DEFINE_INSTANCED_PROP(float, _WaveLocalVerticalAmplitude)
            UNITY_INSTANCING_BUFFER_END(props)

            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                float _WaveWorldAmplitude;
                float4 _WaveLocalDir,_WaveWorldDir;
                float _WaveLocalSpeed,_WaveWorldSpeed;
                float _WaveSpeed;
                float _Gloss;
                float _Cutoff;
                float _AnimationRenderDistance;
                float _MinMainLightIntensity;
                float _InteractDistance;
                float _InteractStrength;
                sampler2D _MainTex;
                float4 _PlayerWpos;
            CBUFFER_END
            
            //***************************************  
            

            vertOut vert(appdata v)
            {
                vertOut o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);

                float fluffyScale = UNITY_ACCESS_INSTANCED_PROP(props, _FluffyScale);
                float blendEffect = UNITY_ACCESS_INSTANCED_PROP(props, _BlendEffect);
                float normalRandom = UNITY_ACCESS_INSTANCED_PROP(props, _NormalRandom);
                float tangentRandom = UNITY_ACCESS_INSTANCED_PROP(props, _TangentRandom);
                float bitangentRandom = UNITY_ACCESS_INSTANCED_PROP(props, _BitangentRandom);
                float waveLocalHorizontalAmplitude = UNITY_ACCESS_INSTANCED_PROP(props, _WaveLocalHorizontalAmplitude);
                float waveLocalVerticalAmplitude = UNITY_ACCESS_INSTANCED_PROP(props, _WaveLocalVerticalAmplitude);



                o.uv = v.uv;
                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                o.normalWS = GetVertexNormalInputs(v.normalOS).normalWS;//conver OS normal to WS normal
                o.tangentWS = GetVertexNormalInputs(v.normalOS,v.tangentOS).tangentWS;
                o.biTangent = cross(o.normalWS, o.tangentWS)
                              * (v.tangentOS.w) 
                              * (unity_WorldTransformParams.w);


                    
               
                normalRandom =  Random(o.positionWS, normalRandom) ;
                tangentRandom =  Random(o.positionWS, tangentRandom)  ;
                bitangentRandom =  Random(o.positionWS, bitangentRandom)  ;



                float3x3 transposeTangent = TransposeTangent((sin(bitangentRandom)+1)*o.tangentWS,
                                                             (sin(tangentRandom)+1)*o.biTangent, 
                                                             (sin(normalRandom))*o.normalWS);
                float3 quadScatter = QuadScatter(transposeTangent, o.uv, normalRandom, blendEffect, fluffyScale);
                v.positionOS.xyz += quadScatter;


                float distanceToCamera = length(_WorldSpaceCameraPos - o.positionWS);
                if(distanceToCamera < _AnimationRenderDistance){

                    v.positionOS += WindHorizontalOS( o.uv,normalRandom, _WaveLocalSpeed, waveLocalHorizontalAmplitude, _WaveLocalDir);
                    v.positionOS += WindVerticalOS( o.uv, normalRandom, _WaveLocalSpeed, waveLocalVerticalAmplitude);



                    float3 finalPositionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                    finalPositionWS+= WindHorizontalWS(o.uv, normalRandom, _WaveWorldSpeed, _WaveWorldAmplitude, _WaveWorldDir );

                    float distanceToPlayer = distance(_PlayerWpos.xyz, o.positionWS);
                    float3 directionToPlayer = normalize( _PlayerWpos.xyz - o.positionWS);
                    distanceToPlayer = 1 - clamp(distanceToPlayer,0,_InteractDistance)/_InteractDistance;

                    finalPositionWS -= directionToPlayer*distanceToPlayer*_InteractStrength;

                    o.positionCS = TransformWorldToHClip(finalPositionWS);
                }
                else{
                    o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                }

                return o;
            }

            float3 lightingCalculate( float3 N,float3 wPos ,float gloss, Light light){
                float3 deffuseLight = DeffuseLight(N, light);
                float3 specularLight = SpecularLight(N,wPos,gloss, light);
                return deffuseLight+ specularLight;
            }
            

            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                UNITY_SETUP_INSTANCE_ID(i);
                //sampler2D _mainTex = UNITY_ACCESS_INSTANCED_PROP(props, _MainTex);
                float4 Col = UNITY_ACCESS_INSTANCED_PROP(props, _Color);
                float4 AmbientCol = UNITY_ACCESS_INSTANCED_PROP(props, _AmbientColor);

                float4 mainTex = tex2D(_MainTex,i.uv);
                float3 N = normalize(i.normalWS);
                float3 wPos = i.positionWS;

                float4 shadowcoord = TransformWorldToShadowCoord(wPos);
                Light mainLight = GetMainLight(shadowcoord);

                float3 mainCol =lightingCalculate(N,wPos,1-_Gloss,mainLight)
                                *Col.rgb
                                * mainLight.color
                                * mainLight.shadowAttenuation
                                * min( mainLight.distanceAttenuation,_MinMainLightIntensity) 

                                + AmbientCol.rgb
                                * mainLight.color;
                LightingData lightingData = (LightingData)0;
                lightingData.mainLightColor += mainCol;

                clip(mainTex.r-_Cutoff);
                return CalculateFinalColor(lightingData,1);
                //return mainTex;
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }
