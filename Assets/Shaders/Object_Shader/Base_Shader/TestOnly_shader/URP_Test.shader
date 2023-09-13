Shader "MyCustom_URP_Shader/URP_Test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Strength("Quad scatter strength",float) = 1
    }
    SubShader
    {
        Tags {  "RenderType" = "Opaque" 
                //"Queue" = "Transparent"
                "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        Cull Off
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag




            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float2 uv : TEXCOORD0;
                float4 tangentOS: TANGENT;
                float3 normalOS : NORMAL;
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;// HCS: H CLIP SPACE
                float2 uv:TEXCOORD0;
                 
                float3 tangentWS : TEXCOORD3;
                float3 biTangent : TEXCOORD2;
                float3 normalWS: TEXCOORD1;
            };

            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                half4 _BaseColor;
                float _Strength;
                
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                vertOut o;
                o.uv = 2*v.uv-1;
                o.normalWS = GetVertexNormalInputs(v.normalOS).normalWS;//conver OS normal to WS normal
                o.tangentWS = GetVertexNormalInputs(v.normalOS,v.tangentOS).tangentWS;
                o.biTangent = cross(o.normalWS, o.tangentWS);

                v.positionOS.xyz += normalize(  -o.biTangent*o.uv.y+o.tangentWS*o.uv.x)*_Strength;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);


                return o;
            }

            

            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                float4 mainTex = tex2D(_MainTex,i.uv);
                
                //return float4 (_LightDirection,1);
                return float4(i.uv,0,1);
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }

            ENDHLSL
        }
    }
}
