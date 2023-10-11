Shader "MyCustom_URP_Shader/URP_WindTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", COLOR) = (0,0,0,0)
        _WindTexture("Wind Texture", 2D) = "white" {}
        _WindTextureScale("Wind Texture Scale", float) = 1
        _WindSpeed("Wind Speed", float) = 1
        _WindStrength("Wind Strength", float) = 1
        _PivotY("Pivot Y", float) = 1
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
                float4 positionOS   : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;
                float3 positionWS  : TEXCOORD1;
                float2 windTextureUV  : TEXCOORD2;
                float2 uv:TEXCOORD0;
            };


            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                sampler2D _WindTexture;
                float4 _WindTexture_ST;
                float4 _Color;
                float _WindTextureScale;
                float _WindSpeed;
                float _WindStrength;
                float _PivotY;
                half4 _BaseColor;
                
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                vertOut o;
                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;

                _WindTexture_ST.zw += _Time.y*_WindSpeed;
                float2 positionWSUV = o.positionWS.xz*_WindTextureScale;
                float2 windTextureUV  = TRANSFORM_TEX( positionWSUV, _WindTexture);
                float windTexture = tex2Dlod(_WindTexture, float4(windTextureUV,0,0)).x;
                v.positionOS.xz += windTexture*_WindStrength*(2*v.positionOS.y- _PivotY);
                o.uv = v.uv;
                o.windTextureUV =windTextureUV;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);


                return o;
            }

            

            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                float4 mainTex = tex2D(_MainTex,i.uv);
                
                //return float4 (_LightDirection,1);
                return mainTex*_Color;
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }

            ENDHLSL
        }
    }
}
