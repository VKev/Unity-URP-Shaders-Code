            
            
            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;// HCS: H CLIP SPACE
                float3 normalWS : TEXCOORD1;
                float2 uv:TEXCOORD0;
                float3 positionWS: TEXCOORD2;
            };

            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                half4 _BaseColor;
                float _SpecularSmoothness;
            CBUFFER_END

            vertOut vert(appdata v)
            {
                vertOut o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v .uv;
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);//conver OS normal to WS normal
                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS; // convert OS position to WS position

                return o;
            }
            //float3 _LightDirection;
            half4 frag(vertOut i) : SV_Target
            {
                float4 mainTex = tex2D(_MainTex,i.uv);
                

                InputData inputData = (InputData)0;//declare InputData struct
                inputData.normalWS = normalize( i.normalWS);
                inputData.positionWS = i.positionWS;
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(i.positionWS);//get view dir base on positionWS
                inputData.shadowCoord = TransformWorldToShadowCoord(i.positionWS);//get shadowcoord base on position WS

                SurfaceData surfaceData = (SurfaceData)0;//declare SurfaceData 
                surfaceData.albedo = mainTex.rbg*_BaseColor.rgb;
                surfaceData.alpha = mainTex.a*_BaseColor.a;
                surfaceData.specular = 1;
                surfaceData.smoothness = _SpecularSmoothness;
                //return float4 (_LightDirection,1);
                return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }
            