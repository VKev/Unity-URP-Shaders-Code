            
            
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
                
                sampler2D _MainTex, _CutoutTex,_NormalMap,_EmissionMap,_HeightMap;
                half4 _BaseColor,_EmissionColor;
                float _SpecularSmoothness;
                float _Cutoff,_normalIntensity,_HeightIntensity;
                float _Metalness;
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                vertOut o;
                o.uv = v.uv;
                float heightMap = (tex2Dlod(_HeightMap, float4(o.uv,0,0)).rgb.x)*_HeightIntensity;
                v.positionOS.xyz += v.normalOS*heightMap;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = normalInput.normalWS;//conver OS normal to WS normal
                o.tangentWS = float4(normalInput.tangentWS,v.tangentOS.w);

                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS; // convert OS position to WS position

                return o;
            }

            void Cutout(float4 tex){
                #ifdef _ALPHA_CUTOUT
                    clip(length(tex.rgb)-_Cutoff);
                #endif
            }

            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                float4 mainTex = tex2D(_MainTex,i.uv);
                float4 cutoutTex =  tex2D(_CutoutTex,i.uv);
                float3 normalWS = normalize( i.normalWS);
                float3 normalTS = UnpackNormal( tex2D(_NormalMap,i.uv));
                normalTS = normalize( lerp(float3(0,0,1),normalTS,_normalIntensity));
                float3x3 tangentToWorld = CreateTangentToWorld(normalWS,i.tangentWS.xyz,i.tangentWS.w);
                normalWS = normalize(TransformTangentToWorld(normalTS,tangentToWorld));

                #ifdef _DOUBLE_SIDED_NORMALS
                    normalWS *= IS_FRONT_VFACE(frontFace,1,-1);
                #endif

                InputData inputData = (InputData)0;//declare InputData struct
                inputData.normalWS = normalWS;// if front face return 1 else return -1
                inputData.positionWS = i.positionWS;
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(i.positionWS);//get view dir base on positionWS
                inputData.shadowCoord = TransformWorldToShadowCoord(i.positionWS);//get shadowcoord base on position WS
                inputData.tangentToWorld = tangentToWorld;

                Cutout(cutoutTex);

                SurfaceData surfaceData = (SurfaceData)0;//declare SurfaceData 
                surfaceData.albedo = mainTex.rbg*_BaseColor.rgb;
                surfaceData.alpha = _BaseColor.a;
                surfaceData.specular = 1;
                surfaceData.smoothness = _SpecularSmoothness;
                surfaceData.normalTS = normalTS;
                surfaceData.metallic = _Metalness;
                surfaceData.emission = tex2D(_EmissionMap,i.uv).xyz*_EmissionColor.rgb;
                //return float4 (_LightDirection,1);
                //return float4(normalWS,1);
                return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }
            