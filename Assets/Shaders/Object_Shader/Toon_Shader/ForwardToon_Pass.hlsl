           

            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float3 normalOS : NORMAL;
                float4 tangentOS: TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;// HCS: H CLIP SPACE
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD3;
                float2 uv:TEXCOORD0;
                float3 positionWS: TEXCOORD2;
            };

            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                half4 _BaseColor, _AmbientColor;
                float _DeffuseBlur;
                float _SpecularSmoothness, _SpecularBlur;
                float _RimSize,_RimBlur,_RimThreshold;
                float _Metalness;
                float _ShadowBlur,_ShadowThreshold,_ShadowIntensity;
                
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                vertOut o;
                o.uv = v.uv;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = normalInput.normalWS;//conver OS normal to WS normal
                o.tangentWS = float4(normalInput.tangentWS,v.tangentOS.w);

                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS; // convert OS position to WS position

                return o;
            }


            float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                float4 mainTex = tex2D(_MainTex,i.uv);
                float3 N = normalize(i.normalWS);
                float3 wPos = i.positionWS;
                float3 V = GetWorldSpaceNormalizeViewDir(wPos);
                float3 L = normalize(_LightDirection); 
                ///////////////////////////////////////////////



                float3 fresnel = 1-saturate(dot(N,V));
                float3 rim = smoothstep((1-_RimSize) - _RimBlur, (1-_RimSize) +_RimBlur, fresnel);
                rim *= fresnel*pow( saturate(dot(N,L)),_RimThreshold);
                ///////////////////////////////////////////////
                

                


                InputData inputData0 = (InputData)0;
                inputData0.normalWS = N;

                SurfaceData surfaceData0 = (SurfaceData)0;
                surfaceData0.albedo =float3(1,1,1);

                float4 deffuseLight = UFBP(inputData0 , surfaceData0);
                deffuseLight = smoothstep(0,_DeffuseBlur, deffuseLight );
                ///////////////////////////////////////////////



                InputData shadowData = (InputData)0;
                shadowData.normalWS = N;
                shadowData.shadowCoord = TransformWorldToShadowCoord(wPos);//get shadowcoord base on position WS

                SurfaceData shadowSurfaceData = (SurfaceData)0;
                shadowSurfaceData.albedo = float3(1,1,1);

                float4 shadowAtten = UFBP(shadowData , shadowSurfaceData);
                shadowAtten = smoothstep(_ShadowThreshold,_ShadowThreshold+_ShadowBlur, shadowAtten )*_ShadowIntensity;
                ///////////////////////////////////////////////



                InputData inputData1 = (InputData)0;
                inputData1.normalWS =  N;
                inputData1.viewDirectionWS = V;

                SurfaceData surfaceData1 = (SurfaceData)0;
                surfaceData1.specular = 0.8;
                surfaceData1.smoothness = _SpecularSmoothness;

                float specularLight = UFBP(inputData1 , surfaceData1);
                specularLight = smoothstep(0.005,_SpecularBlur,specularLight);
                ///////////////////////////////////////////////



                float4 Toon = _BaseColor.rgba*mainTex*(
                                  deffuseLight*shadowAtten
                                + float4(rim,1)*shadowAtten
                                + specularLight*_Metalness*shadowAtten
                                + _AmbientColor);
                ///////////////////////////////////////////////



                //return float4(rim,1);
                return Toon ;
            }