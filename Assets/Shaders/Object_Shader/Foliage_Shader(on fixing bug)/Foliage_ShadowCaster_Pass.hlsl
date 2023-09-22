            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float3 normalOS : NORMAL;
                float4 tangentOS: TANGENT;
                #ifdef _ALPHA_CUTOUT
                    float2 uv :TEXCOORD0;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
                
            };

            float3 FlipNormalBasedOnViewDir(float3 normalWS, float3 positionWS){
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);
                return normalWS * (dot(normalWS,viewDirWS)<0?-1:1);
            }

            float3 _LightDirection;//globle variable

            float4 GetShadowCasterPositionCS(float3 positionWS, float3 normalWS){
                float3 lightDirectionWS = _LightDirection;
                #ifdef _DOUBLE_SIDED_NORMALS
                    normalWS = FlipNormalBasedOnViewDir(normalWS,positionWS);
                #endif
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS,normalWS,lightDirectionWS));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z,UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z,UNITY_NEAR_CLIP_VALUE);
                #endif

                return positionCS;

            }

            struct vertOut
            {
                float4 positionCS : SV_POSITION;// HCS: H CLIP SPACE
                float3 normalWS: NORMAL;
                float3 tangentWS : TEXCOORD3;
                float3 biTangent : TEXCOORD2;
                float3 positionWS: TEXCOORD1;
                #ifdef _ALPHA_CUTOUT
                    float2 uv :TEXCOORD0;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
                
            };

            UNITY_INSTANCING_BUFFER_START(props)
                UNITY_DEFINE_INSTANCED_PROP(float, _FluffyScale)
                 UNITY_DEFINE_INSTANCED_PROP(float, _BlendEffect)
                 UNITY_DEFINE_INSTANCED_PROP(float, _NormalRandom)
                 UNITY_DEFINE_INSTANCED_PROP(float, _TangentRandom)
                 UNITY_DEFINE_INSTANCED_PROP(float, _BitangentRandom)
                 UNITY_DEFINE_INSTANCED_PROP(float, _WaveLocalHorizontalAmplitude)
                 UNITY_DEFINE_INSTANCED_PROP(float, _WaveLocalVerticalAmplitude)
            UNITY_INSTANCING_BUFFER_END(props)

            CBUFFER_START(UnityPerMaterial)

                float _Cutoff;
                float _WaveWorldAmplitude;
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
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

                float fluffyScale = UNITY_ACCESS_INSTANCED_PROP(props, _FluffyScale);
                float blendEffect = UNITY_ACCESS_INSTANCED_PROP(props, _BlendEffect);
                float normalRandom = UNITY_ACCESS_INSTANCED_PROP(props, _NormalRandom);
                float tangentRandom = UNITY_ACCESS_INSTANCED_PROP(props, _TangentRandom);
                float bitangentRandom = UNITY_ACCESS_INSTANCED_PROP(props, _BitangentRandom);
                float waveLocalHorizontalAmplitude = UNITY_ACCESS_INSTANCED_PROP(props, _WaveLocalHorizontalAmplitude);
                float waveLocalVerticalAmplitude = UNITY_ACCESS_INSTANCED_PROP(props, _WaveLocalVerticalAmplitude);




                #ifdef _ALPHA_CUTOUT
                    o.uv = v.uv;
                #endif
                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                o.normalWS = GetVertexNormalInputs(v.normalOS).normalWS;//conver OS normal to WS normal
                o.tangentWS = GetVertexNormalInputs(v.normalOS,v.tangentOS).tangentWS;
                o.biTangent = cross(o.normalWS, o.tangentWS)
                              * (v.tangentOS.w) 
                              * (unity_WorldTransformParams.w);

                normalRandom =  Random(o.positionWS, normalRandom)  ;
                tangentRandom =  Random(o.positionWS, tangentRandom)  ;
                bitangentRandom =  Random(o.positionWS, bitangentRandom)  ;
                float3x3 transposeTangent = TransposeTangent((sin(bitangentRandom)+1)*o.tangentWS,
                                                             (sin(tangentRandom)+1)*o.biTangent, 
                                                             (sin(normalRandom))*o.normalWS);

                float3 quadScatter = QuadScatter(transposeTangent, o.uv, normalRandom, blendEffect, fluffyScale);
                

                v.positionOS.xyz += quadScatter;



                v.positionOS += WindHorizontalOS( o.uv,normalRandom, _WaveLocalSpeed, waveLocalHorizontalAmplitude, _WaveLocalDir);
                v.positionOS += WindVerticalOS( o.uv, normalRandom, _WaveLocalSpeed, waveLocalVerticalAmplitude);



                float3 finalPositionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                finalPositionWS+= WindHorizontalWS(o.uv, normalRandom, _WaveWorldSpeed, _WaveWorldAmplitude, _WaveWorldDir );

                o.positionCS = GetShadowCasterPositionCS(finalPositionWS,normalWS);

                return o;
            }

            void Cutout(float4 tex){
                #ifdef _ALPHA_CUTOUT
                    clip(tex.r-_Cutoff);
                #endif
            }

            half4 frag(vertOut i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                #ifdef _ALPHA_CUTOUT
                    float2 uv = i.uv;
                    float4 cutoutTex = tex2D(_MainTex,uv);
                    Cutout(cutoutTex);
                #endif
                return 0;
            }