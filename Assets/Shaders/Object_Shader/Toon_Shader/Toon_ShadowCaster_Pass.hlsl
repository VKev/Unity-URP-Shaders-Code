struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float3 normalOS : NORMAL;
                
            };

            float3 FlipNormalBasedOnViewDir(float3 normalWS, float3 positionWS){
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);
                return normalWS * (dot(normalWS,viewDirWS)<0?-1:1);
            }

            

            float4 GetShadowCasterPositionCS(float3 positionWS, float3 normalWS){
                Light mainlight = GetMainLight();
                float4 positionCS;
                positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS,normalWS,mainlight.direction));

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
                
            };
            CBUFFER_START(UnityPerMaterial)
            sampler2D _MainTex;
            CBUFFER_END


            vertOut vert(appdata v)
            {
                vertOut o;

                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);//conver OS normal to WS normal
                float3 positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS; // convert OS position to WS position
                o.positionCS = GetShadowCasterPositionCS(positionWS, (normalWS)); //apply shadow bias
                return o;
            }


            half4 frag(vertOut i) : SV_Target
            {
                return 0;
            }