
Shader "MyCustom_URP_Shader/URP_BlinnPhong"
{

    Properties
    {
        _MainTex("Main Tex",2D) = "White" {}
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct vertOut
            {
                float4 positionHCS  : SV_POSITION;// HCS: H CLIP SPACE
                float3 normalWS : TEXCOORD1;
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
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v .uv;
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                return o;
            }

            half4 frag(vertOut i) : SV_Target
            {
                float4 mainTex = tex2D(_MainTex,i.uv);
                
                InputData inputData = (InputData)0;//declare InputData struct
                inputData.normalWS = i.normalWS;

                SurfaceData surfaceData = (SurfaceData)0;//declare SurfaceData 
                surfaceData.albedo = mainTex.rbg*_BaseColor.rgb;
                surfaceData.alpha = mainTex.a;

                return UniversalFragmentBlinnPhong(inputData , surfaceData);
            }
            ENDHLSL
        }
    }
}