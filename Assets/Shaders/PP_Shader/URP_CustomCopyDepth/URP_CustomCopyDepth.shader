Shader "MyCustom_URP_Shader/URP_CustomCopyDepth"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Name "CopyDepth"
            ZTest Always ZWrite On ColorMask R
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

            #pragma multi_compile _ _DEPTH_MSAA_2 _DEPTH_MSAA_4 _DEPTH_MSAA_8
            #pragma multi_compile _ _OUTPUT_DEPTH

            #ifndef UNIVERSAL_COPY_DEPTH_PASS_INCLUDED
            #define UNIVERSAL_COPY_DEPTH_PASS_INCLUDED

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #if defined(_DEPTH_MSAA_2)
                #define MSAA_SAMPLES 2
            #elif defined(_DEPTH_MSAA_4)
                #define MSAA_SAMPLES 4
            #elif defined(_DEPTH_MSAA_8)
                #define MSAA_SAMPLES 8
            #else
                #define MSAA_SAMPLES 1
            #endif

            #if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
            #define DEPTH_TEXTURE_MS(name, samples) Texture2DMSArray<float, samples> name
            #define DEPTH_TEXTURE(name) TEXTURE2D_ARRAY_FLOAT(name)
            #define LOAD(uv, sampleIndex) LOAD_TEXTURE2D_ARRAY_MSAA(_MainTex, uv, unity_StereoEyeIndex, sampleIndex)
            #define SAMPLE(uv) SAMPLE_TEXTURE2D_ARRAY(_MainTex, sampler_MainTex, uv, unity_StereoEyeIndex).r
            #else
            #define DEPTH_TEXTURE_MS(name, samples) Texture2DMS<float, samples> name
            #define DEPTH_TEXTURE(name) TEXTURE2D_FLOAT(name)
            #define LOAD(uv, sampleIndex) LOAD_TEXTURE2D_MSAA(_MainTex, uv, sampleIndex)
            #define SAMPLE(uv) SAMPLE_DEPTH_TEXTURE(_MainTex, sampler_MainTex, uv)
            #endif

            #if MSAA_SAMPLES == 1
                DEPTH_TEXTURE(_MainTex);
                SAMPLER(sampler_MainTex);
            #else
                DEPTH_TEXTURE_MS(_MainTex, MSAA_SAMPLES);
                float4 _MainTex_TexelSize;
            #endif

            #if UNITY_REVERSED_Z
                #define DEPTH_DEFAULT_VALUE 1.0
                #define DEPTH_OP min
            #else
                #define DEPTH_DEFAULT_VALUE 0.0
                #define DEPTH_OP max
            #endif

            float SampleDepth(float2 uv)
            {
            #if MSAA_SAMPLES == 1
                return SAMPLE(uv);
            #else
                int2 coord = int2(uv * _MainTex_TexelSize.zw);
                float outDepth = DEPTH_DEFAULT_VALUE;

                UNITY_UNROLL
                for (int i = 0; i < MSAA_SAMPLES; ++i)
                    outDepth = DEPTH_OP(LOAD(coord, i), outDepth);
                return outDepth;
            #endif
            }

            #if defined(_OUTPUT_DEPTH)
            float frag(Varyings input) : SV_Depth
            #else
            float frag(Varyings input) : SV_Target
            #endif
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                return SampleDepth(input.texcoord);
            }

            #endif

            ENDHLSL
        }
    }
}
