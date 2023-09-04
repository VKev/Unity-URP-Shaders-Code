Shader "Unlit/URP_Tessellation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags {  "RenderType" = "Opaque" 
                //"Queue" = "Transparent"
                "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
           
            #pragma target 2.0
            #pragma require geometry

            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag


            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 tangentOS: TANGENT;
                float3 normalOS: NORMAL;
                float2 uv: TEXCOORD0;

            };

            struct vertOut
            {
                float3 positionWS:TEXCOORD1;
                float2 uv   : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            struct geoOut
            {
                float3 positionWS:TEXCOORD1;
                float3 normalWS: TEXCOORD2;
                float4 positionCS : SV_POSITION;
                float2 uv   : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                sampler2D _MainTex;
            CBUFFER_END

            //************************
            vertOut vert(Attributes v)
            {
                vertOut o;
                
                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);

                //VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);

                o.uv   = v.uv;

                return o;
            }

            //************************
            geoOut SetupVertex(float3 positionWS, float3 normalWS, float2 uv)
            {
                geoOut o;
                o.positionWS = positionWS;
                o.uv = uv;
                o.normalWS = normalWS;
                o.positionCS = TransformWorldToHClip(positionWS);
                return o;
            }

            float3 GetNormalFromTriangle(float3 a, float3 b, float3 c) {
                return normalize(cross(b - a, c - a));
            }

            void SetupAndOutputTriangle(inout TriangleStream<geoOut> os, vertOut a, vertOut b, vertOut c)
            {
                os.RestartStrip();// reset and make the next output triangle to be the new triangle
                float3 normalWS = GetNormalFromTriangle(a.positionWS, b.positionWS, c.positionWS);
                os.Append(SetupVertex(a.positionWS, normalWS, a.uv ));
                os.Append(SetupVertex(b.positionWS, normalWS, b.uv ));
                os.Append(SetupVertex(c.positionWS, normalWS, c.uv ));
            }

            [maxvertexcount(9)]
            void geo(triangle vertOut v[3], inout TriangleStream<geoOut> os)
            {
                vertOut center;
                float3 triNormal = GetNormalFromTriangle(v[0].positionWS, v[1].positionWS, v[2].positionWS);//get normal of TriangleStream
                
                center.positionWS = (v[0].positionWS+ v[1].positionWS+ v[2].positionWS)/3.0 + triNormal;//get center WS POSITION
                center.uv = (v[0].uv+ v[1].uv+ v[2].uv)/3.0;//get center WS uv

                SetupAndOutputTriangle(os,v[0],v[1],center);
                SetupAndOutputTriangle(os,v[1],v[2],center);
                SetupAndOutputTriangle(os,v[2],v[0],center);
            }


            //************************
            half4 frag(geoOut i) : SV_Target//get front face of object
            {
                half4 mainTex = tex2D(_MainTex,i.uv);
                return mainTex;
            }

            ENDHLSL
        }
    }
}
