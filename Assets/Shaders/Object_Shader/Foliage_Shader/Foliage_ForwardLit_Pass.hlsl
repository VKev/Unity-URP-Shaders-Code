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
                 UNITY_DEFINE_INSTANCED_PROP(float, _Randomize)
                 UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                 UNITY_DEFINE_INSTANCED_PROP(float4, _AmbientColor)
            UNITY_INSTANCING_BUFFER_END(props)

            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                float _WaveLocalAmplitude,_WaveWorldAmplitude;
                float4 _WaveLocalDir,_WaveWorldDir;
                float _WaveLocalSpeed,_WaveWorldSpeed;
                float _WaveSpeed;
                float _Gloss;
                float _MinMainLightIntensity;
                sampler2D _MainTex;
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                vertOut o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);

                float fluffyScale = UNITY_ACCESS_INSTANCED_PROP(props, _FluffyScale);
                float blendEffect = UNITY_ACCESS_INSTANCED_PROP(props, _BlendEffect);
                float randomIntensity = UNITY_ACCESS_INSTANCED_PROP(props, _Randomize);

                o.uv = v.uv;
                

                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                float3 wPos = o.positionWS;

                float random =  randomIntensity*(abs(wPos.x)+abs(wPos.z))  ;

                o.normalWS = GetVertexNormalInputs(v.normalOS).normalWS;//conver OS normal to WS normal
                o.tangentWS = GetVertexNormalInputs(v.normalOS,v.tangentOS).tangentWS;
                o.biTangent = cross(o.normalWS, o.tangentWS)
                              * (v.tangentOS.w) 
                              * (unity_WorldTransformParams.w);

                float3x3 transposeTangent = transpose(float3x3(o.tangentWS, o.biTangent, o.normalWS*sin(random) ));

                float3 foliageUV = (mul(float3(2*v.uv-1,0), transposeTangent ).xyz);


                foliageUV = mul(float4( foliageUV,0),unity_ObjectToWorld).xyz;
                foliageUV = normalize(foliageUV)*fluffyScale;
                foliageUV = lerp(0,foliageUV,blendEffect);

                v.positionOS.xyz += foliageUV;
                v.positionOS.xz += sin((_Time.y + random)*_WaveLocalSpeed)
                                  *_WaveLocalAmplitude*o.uv.y
                                  *normalize(_WaveLocalDir.xy);

                v.positionOS.y += sin((_Time.y + random)*_WaveLocalSpeed)
                                  *_WaveLocalAmplitude
                                  *o.uv.y;

                float3 positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                positionWS.xz += sin((_Time.y + random)*_WaveWorldSpeed)
                                 *_WaveWorldAmplitude
                                 *normalize( _WaveWorldDir.xy)
                                 *o.uv.y;

                o.positionCS = TransformWorldToHClip(positionWS);

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
                                *Col
                                * min( mainLight.distanceAttenuation,_MinMainLightIntensity) 
                                + AmbientCol.rgb;
                LightingData lightingData = (LightingData)0;
                lightingData.mainLightColor += mainCol;

                clip(mainTex.r-0.1);
                return CalculateFinalColor(lightingData,1);
                //return mainTex;
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }
