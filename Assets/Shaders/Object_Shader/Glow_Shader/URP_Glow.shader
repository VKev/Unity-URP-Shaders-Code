Shader "MyCustom_URP_Shader/URP_Glow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CoreColor ("Color", COLOR) = (0,0,0,0)
        _BackgroundColor ("Color", COLOR) = (0,0,0,0)
        _GlowIntensity("Glow Intensity",float ) = 1

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

            #pragma vertex vert
            #pragma fragment frag




            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/VkevShaderLib.hlsl"

            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float3 normalOS : NORMAL;
                float4 tangentOS: TANGENT;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID//GPU instancing
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;// HCS: H CLIP SPACE
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD3;
                float2 uv:TEXCOORD0;
                float3 positionWS: TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID//GPU instancing
            };
            vertOut vert(appdata v)
            {
                vertOut o;
                UNITY_SETUP_INSTANCE_ID(v);//GPU instancing
                UNITY_TRANSFER_INSTANCE_ID(v,o);//GPU instancing
                o.uv = v.uv;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = normalInput.normalWS;//conver OS normal to WS normal
                o.tangentWS = float4(normalInput.tangentWS,v.tangentOS.w);

                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS; // convert OS position to WS position

                return o;
            }

            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                half4 _CoreColor;
                half4 _BackgroundColor;
                float _GlowIntensity;
                
            CBUFFER_END

            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                UNITY_SETUP_INSTANCE_ID(i);
                float4 mainTex = tex2D(_MainTex,i.uv);
                float3 N = normalize(i.normalWS);
                float3 wPos = i.positionWS;
                float3 V = GetWorldSpaceNormalizeViewDir(wPos);

                float fresnel=0;
                Unity_FresnelEffect_float(N, V, 1, fresnel);
                
                half4 finalColor = lerp(_BackgroundColor, _CoreColor, 1-fresnel)*_GlowIntensity;
                
                //return float4 (_LightDirection,1);
                return mainTex*finalColor;
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }

            ENDHLSL
        }
    }
}
