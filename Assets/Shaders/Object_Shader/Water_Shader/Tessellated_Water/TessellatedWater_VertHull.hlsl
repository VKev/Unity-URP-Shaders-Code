            struct Attributes {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS: TANGENT;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct TessellationControlPoint {
                float3 positionWS : INTERNALTESSPOS;
                float3 normalWS : NORMAL;
                float3 tangentWS:TANGENT;
                float3 biTangent: TEXCOORD1;
                float4 screenPosition: TEXCOORD3;
                float2 waterUV: TEXCOORD2;
                float2 foamUV: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct TessellationFactors {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            

            struct domaOut {
                float4 positionCS  : SV_POSITION;
                float2 waterUV:TEXCOORD0;
                float2 foamUV:TEXCOORD5;
                float4 screenPosition: TEXCOORD1;
                float4 screenPositionReal: TEXCOORD6;
                float3 normalWS: NORMAL;
                float3 tangentWS : TEXCOORD3;
                float3 biTangent : TEXCOORD2;
                float3 positionWS: TEXCOORD4;
                float distanceToCam: TEXCOORD7;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            float4x4 _Object2World;
            
            sampler2D _CameraOpaqueTexture;
            float4x4 _World2Object;
            CBUFFER_START(UnityPerMaterial)
                float3 _FactorEdge1;
                float _FactorInside;
                sampler2D _MainTex;
                float _TextureBlend;
                float4 _MainTex_ST;
                half4 _BaseColor;
                half4 _FoamColor;
                half4 _SurfaceColor;
                half4 _BottomColor;
                float _Depth;
                float _WaveSpeed;
                float _WaveScale;
                float _WaveStrength;
                float _FoamAmount;
                float _FoamCutoff;
                float _FoamSpeed;
                float _FoamScale;
                float _SpecularIntensity;
                float _Gloss;
                float _Smoothness;
                float _NoiseNormalStrength;
                float _WaterShadow;
                float _InteractFactorInside;
                float _InteractTessellatedRange;
                float _RefractionCut;
                float _ReflectionIntensity;
                float _ReflectionNormalIntensity;
                float4 _PlayerWpos;
                uniform samplerCUBE _ReflectionMap;
            CBUFFER_END

            float3 GetViewDirectionFromPosition(float3 positionWS) {
                return normalize(GetCameraPositionWS() - positionWS);
            }

            

            TessellationControlPoint Vertex(Attributes input) {
                TessellationControlPoint output;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                _MainTex_ST.zw += _Time.y*_WaveSpeed;
                _MainTex_ST.xy *= _WaveScale;
                output.waterUV = TRANSFORM_TEX(input.uv, _MainTex);

                _MainTex_ST.zw += _Time.y*_FoamSpeed;
                _MainTex_ST.xy *= _FoamScale;
                output.foamUV = TRANSFORM_TEX(input.uv, _MainTex);

                VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

                output.tangentWS = GetVertexNormalInputs(input.normalOS,input.tangentOS).tangentWS;
                output.normalWS = normalInputs.normalWS;
                output.biTangent = cross(output.normalWS, output.tangentWS)
                              * (input.tangentOS.w) 
                              * (unity_WorldTransformParams.w);

                output.positionWS = posnInputs.positionWS;
                output.screenPosition = ComputeScreenPos(TransformObjectToHClip(input.positionOS.xyz));
                return output;
            }

            // The patch constant function runs once per triangle, or "patch"
            TessellationFactors PatchConstantFunction(
                InputPatch<TessellationControlPoint, 3> patch) {
                UNITY_SETUP_INSTANCE_ID(patch[0]); 

                float distance1 = distance(_PlayerWpos.xyz, patch[0].positionWS);
                float distance2 = distance(_PlayerWpos.xyz, patch[1].positionWS);
                float distance3 = distance(_PlayerWpos.xyz, patch[2].positionWS);
                float distance =  min(min(distance1, distance2), distance3);
                float distanceToPlayer1 = distance;
                distanceToPlayer1 = 1 - clamp(distanceToPlayer1,0,_InteractTessellatedRange)/_InteractTessellatedRange;

                TessellationFactors f;
                if(distanceToPlayer1 >0){
                    f.edge[0] = _FactorEdge1.x;
                    f.edge[1] = _FactorEdge1.y;
                    f.edge[2] = _FactorEdge1.z;
                    f.inside = _InteractFactorInside;
                }else{
                    f.edge[0] = _FactorEdge1.x;
                    f.edge[1] = _FactorEdge1.y;
                    f.edge[2] = _FactorEdge1.z;
                    f.inside = _FactorInside;
                }

                return f;
            }

            // The hull function runs once per vertex. You can use it to modify vertex
            [domain("tri")] // Signal we're inputting triangles
            [outputcontrolpoints(3)] // Triangles have three points
            [outputtopology("triangle_cw")] // Signal we're outputting triangles
            [patchconstantfunc("PatchConstantFunction")] // Register the patch constant function
             [partitioning("integer")]
            TessellationControlPoint Hull(
                InputPatch<TessellationControlPoint, 3> patch, 
                uint id : SV_OutputControlPointID) { 

                return patch[id];
            }

            