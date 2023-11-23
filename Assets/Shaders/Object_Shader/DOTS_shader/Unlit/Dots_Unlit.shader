Shader "MyCustom_URP_Shader/DOTS_Unlit"
{
	Properties
	{

		[Header(Color options)]
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Base Color", COLOR) = (1, 1, 1, 1)

        [Header(Lighting options)]
        _AmbientColor("Ambient Color", COLOR) = (0,0,0,0)
        _Gloss("Glossity", float) = 1
        _LightMaxIntensity("Light Max receiver Intensity", float) = 0
        _MainLightShadowIntensity("Main light shadow receiver intensity",float) = 1

        [Header(Rim options)]
        _RimSize("Rim Size", Range(0,1))=0.2
        _RimBlur("Rim Blur", Range(0,0.1))= 0.01
        _RimThreshold("Rim Threshold", Range(0.01,10))= 2

        [HideInInspector] _Pass("Pass", float) = 0
	}
	SubShader
	{
		Tags
		{
			//"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}
		Pass
		{
			Name "Pass"

			HLSLPROGRAM

			#pragma target 4.5
			#pragma multi_compile_instancing
			#pragma multi_compile _ DOTS_INSTANCING_ON
			#pragma vertex vert
			#pragma fragment frag

			#define _SPECULAR_COLOR

            
            #define _LIGHT_COOKIES
            //cal light shadow for main light and enable cascade
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE

            //supprot multiple light
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #define ADDITIONAL_LIGHT_CALCULATE_SHADOWS
            #pragma multi_compile _ _FORWARD_PLUS

            //#define USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA

            //enable soft shadow
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

			 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Assets/VkevShaderLib.hlsl"

			struct appdata
			{
				float3 positionOS : POSITION;
				float4 uv0 : TEXCOORD0;
				#if UNITY_ANY_INSTANCING_ENABLED
				uint instanceID : INSTANCEID_SEMANTIC;
				#endif
			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				#if UNITY_ANY_INSTANCING_ENABLED
				uint instanceID : CUSTOM_INSTANCE_ID;
				#endif
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float4 _MainTex_ST;
			CBUFFER_END

			#if defined(UNITY_DOTS_INSTANCING_ENABLED)
				UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
					UNITY_DOTS_INSTANCED_PROP(float4, _Color)
					UNITY_DOTS_INSTANCED_PROP(float4, _MainTex_ST)
				UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

				#define _Color UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _Color)
				#define _MainTex_ST UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _MainTex_ST)
			#endif

			sampler2D _MainTex;

			v2f vert(appdata v)
			{
				v2f o = (v2f)0;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 positionWS = TransformObjectToWorld(v.positionOS);
				o.positionCS = TransformWorldToHClip(positionWS);
				o.uv0 = v.uv0.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				#if UNITY_ANY_INSTANCING_ENABLED
				o.instanceID = v.instanceID;
				#endif

				return o;
			}

			half4 frag(v2f i) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(i);
				float4 color = tex2D(_MainTex,i.uv0.xy) * _Color;
				return color;
			}

			ENDHLSL
		}
		Pass{
            name "ShadowCaster"
            Tags{"LightMode"= "ShadowCaster"}
            ColorMask 0 // No color output, only depth
            

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Dots_ShadowCaster_Pass.hlsl"
            ENDHLSL
        }
    }
    CustomEditor "URP_Global_Editor"
}