Shader "MyCustom_URP_Shader/URP_Foliage"
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

            #pragma vertex vert
            #pragma fragment frag




            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float2 uv : TEXCOORD0;
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;// HCS: H CLIP SPACE
                float2 uv:TEXCOORD0;
            };

            //declare Properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                half4 _BaseColor;
                
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                vertOut o;
                o.uv = v.uv;
                //v.positionOS.xy += (2*v.uv-1);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);


                return o;
            }

            

            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                float4 mainTex = tex2D(_MainTex,i.uv);
                
                return float4 (i.uv,0,1);
                //return mainTex;
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }

            ENDHLSL
        }
    }
}
