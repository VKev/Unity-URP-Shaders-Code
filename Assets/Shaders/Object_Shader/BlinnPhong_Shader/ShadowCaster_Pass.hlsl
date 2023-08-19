            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float3 normalOS : NORMAL;
                #ifdef _ALPHA_CUTOUT
                    float2 uv :TEXCOORD0;
                #endif
                
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
                #ifdef _ALPHA_CUTOUT
                    float2 uv :TEXCOORD0;
                #endif
                
            };
            CBUFFER_START(UnityPerMaterial)
            sampler2D _MainTex, _CutoutTex;
            float _Cutoff;
            CBUFFER_END


            vertOut vert(appdata v)
            {
                vertOut o;
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);//conver OS normal to WS normal
                float3 positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS; // convert OS position to WS position
                o.positionCS = GetShadowCasterPositionCS(positionWS,normalWS); //apply shadow bias
                #ifdef _ALPHA_CUTOUT
                    o.uv = v.uv;
                #endif
                return o;
            }

            void Cutout(float4 tex){
                #ifdef _ALPHA_CUTOUT
                    clip(length(tex.rgb)-_Cutoff);
                #endif
            }

            half4 frag(vertOut i) : SV_Target
            {
                #ifdef _ALPHA_CUTOUT
                    float2 uv = i.uv;
                    float4 cutoutTex = tex2D(_CutoutTex,uv);
                    Cutout(cutoutTex);
                #endif
                return 0;
            }