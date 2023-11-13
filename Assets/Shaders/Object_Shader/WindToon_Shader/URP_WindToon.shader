Shader "MyCustom_URP_Shader/URP_WindToon"
{
    Properties
    {
        [Header(Rendering options)]
        _AnimationRenderDistance("Animation render distance", float) = 60
        _AnimationShadowRenderDistance("Shadow render distance", float) = 20

        [Header(Color options)]
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", COLOR) = (0,0,0,0)

        [Header(Lighting options)]
        _AmbientColor("Ambient Color", COLOR) = (0,0,0,0)
        _Gloss("Glossity", float) = 1
        _LightMaxIntensity("Light Max receiver Intensity", float) = 0
        _MainLightShadowIntensity("Main light shadow receiver intensity",float) = 1

        [Header(Rim options)]
        _RimSize("Rim Size", Range(0,1))=0.2
        _RimBlur("Rim Blur", Range(0,0.1))= 0.01
        _RimThreshold("Rim Threshold", Range(0.01,10))= 2
        
        [Header(Wind Texture animation)]
        _WindTexture("Wind Texture", 2D) = "white" {}
        _WindTextureScale("Wind Texture Scale", float) = 1
        _WindSpeed("Wind Speed", float) = 1
        _WindStrength("Wind Strength", float) = 1
        _PivotY("Pivot Y", float) = 1


         [Header(Local animation options)]
        _WaveLocalStrength("Local wind strength", float) = 0.4
        _WaveLocalSpeed("Local wave speed", float) = 0.2
        _Randomize("Local cycle random intensity", Range(1,20)) = 20
        _WaveLocalDir("Local wind direction", vector) = (0.7,0.7,0,0)

        [Header(World animation options)]
        _WaveWorldSpeed("World wave speed",float) = 0.3
        _WaveWorldStrength("World wind strength", float) = 0.05
        _WaveWorldDir("World wind direction", vector) = (1,0,0,0)

        [Header(Interact options)]
        _InteractDistance("Interact with grass distance", float) = 1
        _InteractStrength("Interact grass strength",float) = 5
        _InteractOffsetY("Interact offset Y", float) = 0.5

        [HideInInspector] _Pass("Pass", float) = 0
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


            #pragma multi_compile_instancing
            //specular of UniversalFragmentBlinnPhong only work with this define
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
                float4 positionOS   : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS: TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct vertOut
            {
                float4 positionCS  : SV_POSITION;
                float3 positionWS  : TEXCOORD1;
                float2 windTextureUV  : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float4 tangentWS : TEXCOORD4;
                float2 uv:TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            UNITY_INSTANCING_BUFFER_START(props)
                UNITY_DEFINE_INSTANCED_PROP(float, _Gloss)
                UNITY_DEFINE_INSTANCED_PROP(float, _RimSize)
                UNITY_DEFINE_INSTANCED_PROP(float, _RimThreshold)
                UNITY_DEFINE_INSTANCED_PROP(float, _RimBlur)
                UNITY_DEFINE_INSTANCED_PROP(float4, _AmbientColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
            UNITY_INSTANCING_BUFFER_END(props)

            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                sampler2D _WindTexture;
                float4 _WindTexture_ST;
                float _WindTextureScale;
                float _WindSpeed;
                float _WindStrength;
                float _PivotY;
                float _AnimationRenderDistance;
                float _InteractDistance;
                float _InteractStrength;
                half4 _BaseColor;
                
                float _WaveLocalSpeed,_WaveLocalStrength,_Randomize;
                float4 _WaveLocalDir;

                float _WaveWorldSpeed,_WaveWorldStrength;
                float4 _WaveWorldDir;
                float _RandomWorldLength;
                float _InteractOffsetY;
                float4 _PlayerWpos;

                float _LightMaxIntensity;
                float _MainLightShadowIntensity;
            CBUFFER_END

            

            vertOut vert(appdata v)
            {
                vertOut o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);

                o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;

                float uvY = lerp(0,1,  v.positionOS.y+ _PivotY);


                _WindTexture_ST.zw += _Time.y*_WindSpeed;
                float2 positionWSUV = o.positionWS.xz*_WindTextureScale;
                float2 windTextureUV  = TRANSFORM_TEX( positionWSUV, _WindTexture);
                float windTexture = tex2Dlod(_WindTexture, float4(windTextureUV,0,0)).x;


                float distanceToCamera = length(_WorldSpaceCameraPos - o.positionWS);
                float3 playerWpos = _PlayerWpos.xyz;
                playerWpos.y += _InteractOffsetY;

                if(distanceToCamera < _AnimationRenderDistance){
                    float3 directionToPlayer = normalize( playerWpos.xyz - o.positionWS.xyz);

                    float distanceToPlayer = distance(playerWpos.xyz, o.positionWS);
                    distanceToPlayer = 1 - clamp(distanceToPlayer,0,_InteractDistance)/_InteractDistance;

                    float random = Random( o.positionWS,_Randomize) ;

                    v.positionOS.xz += WindHorizontalOS(float2(0,uvY), random, _WaveLocalSpeed,_WaveLocalStrength,_WaveLocalDir).xz;
                
                    

                    o.positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;


                    o.positionWS.xz += windTexture*_WindStrength*(uvY);
                    o.positionWS.xz +=  WindHorizontalWS(float2(0,uvY), random, _WaveWorldSpeed,_WaveWorldStrength,_WaveWorldDir).xz;
                    o.positionWS.xz -=  directionToPlayer.xz*distanceToPlayer*uvY*_InteractStrength;
                    //o.positionWS.y -=  directionToPlayer.y*distanceToPlayer*(v.positionOS.y+ _PivotY)*1;
                }

                o.uv = v.uv;
                o.windTextureUV =windTextureUV;
                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS,v.tangentOS);
                o.normalWS = normalInput.normalWS;//conver OS normal to WS normal
                o.tangentWS = float4(normalInput.tangentWS,v.tangentOS.w);
                o.positionCS = TransformWorldToHClip(o.positionWS);


                return o;
            }

            float3 generateToonLightBlinnPhong(float3 N, float3 wPos, float3 V,Light light, float4 ambientColor, float gloss, float rimSize, float rimBlur, float rimThreshold){

                float3 L = normalize(light.direction); 
                float3 fresnel = 1-saturate(dot(N,V));//float3 L = normalize(GetAdditionalLight(0,N).direction); 

                float3 LightColor = light.color * min(light.distanceAttenuation , _LightMaxIntensity);

                float3 rim = smoothstep((1-rimSize) - rimBlur, (1-rimSize) +rimBlur, fresnel);
                rim *= fresnel*pow( saturate(dot(N,L)),rimThreshold);


                float3 deffuseLight = DeffuseLight(N,light);
                deffuseLight = smoothstep(0,0.01, deffuseLight );
                

                float3 specularLight = SpecularLight(N,wPos,gloss,light);
                specularLight = smoothstep(0.005,0.006,specularLight);

                

                //return float4(lambert.xxx,1) ;
                float3 Col = LightColor*( 
                deffuseLight *light.shadowAttenuation 
                + specularLight*light.shadowAttenuation 
                + ambientColor.rgb 
                + rim*light.shadowAttenuation );

                return Col;
            };

            //float3 _LightDirection;
            half4 frag(vertOut i, FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC) : SV_Target//get front face of object
            {
                UNITY_SETUP_INSTANCE_ID(i);
                
                float gloss = UNITY_ACCESS_INSTANCED_PROP(props, _Gloss);
                float4 ambientColor = UNITY_ACCESS_INSTANCED_PROP(props, _AmbientColor);
                float4 Col = UNITY_ACCESS_INSTANCED_PROP(props, _Color);
                float rimSize = UNITY_ACCESS_INSTANCED_PROP(props, _RimSize);
                float rimBlur = UNITY_ACCESS_INSTANCED_PROP(props, _RimBlur);
                float rimThreshold = UNITY_ACCESS_INSTANCED_PROP(props, _RimThreshold);

                float4 mainTex = tex2D(_MainTex,i.uv);
                float3 N = normalize(i.normalWS);
                float3 wPos = i.positionWS;
                float3 V = GetWorldSpaceNormalizeViewDir(wPos);


                InputData inputData = (InputData)0;
                float4 shadowMask = CalculateShadowMask(inputData);

                
                float4 shadowcoord = TransformWorldToShadowCoord(wPos);
                Light mainLight = GetMainLight(shadowcoord);
                mainLight.shadowAttenuation *= _MainLightShadowIntensity;



                float3 baseColor = Col.rgb*mainTex.xyz*generateToonLightBlinnPhong(N,wPos,V,mainLight,ambientColor,gloss,rimSize,rimBlur,rimThreshold);
                


                LightingData lightingData = (LightingData)0;
                lightingData.mainLightColor  += baseColor;

                #if defined(_ADDITIONAL_LIGHTS)
                uint pixelLightCount = GetAdditionalLightsCount();

                #if USE_FORWARD_PLUS
                for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
                {
                    FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

                    Light AddLight = GetAdditionalLight(lightIndex, wPos, shadowMask);
                    float3 additionalColor = Col.rgb*mainTex.xyz*generateToonLightBlinnPhong(N,wPos,V,mainLight,ambientColor,gloss,rimSize,rimBlur,rimThreshold);
                    lightingData.additionalLightsColor += additionalColor;
                }
                #endif

                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light AddLight = GetAdditionalLight(lightIndex, wPos, shadowMask);
                    float3 additionalColor = Col.rgb*mainTex.xyz*generateToonLightBlinnPhong(N,wPos,V,mainLight,ambientColor,gloss,rimSize,rimBlur,rimThreshold);
                    lightingData.additionalLightsColor += additionalColor;
                LIGHT_LOOP_END
                #endif
                


                //return float4(additionalColor,1) ;
                return CalculateFinalColor(lightingData,1);
                //return UniversalFragmentBlinnPhong(inputData , surfaceData);
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
             #include "Assets/VkevShaderLib.hlsl"
            struct appdata
            {
                float4 positionOS   : POSITION;//OS : OBJECT SPACE
                float3 normalOS : NORMAL;
                
            };

            float3 FlipNormalBasedOnViewDir(float3 normalWS, float3 positionWS){
                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);
                return normalWS * (dot(normalWS,viewDirWS)<0?-1:1);
            }

            

            float4 GetShadowCasterPositionCS(float3 positionWS, float3 normalWS){
                Light mainlight = GetMainLight();
                float4 positionCS;
                positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS,normalWS,mainlight.direction));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z,UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z,UNITY_NEAR_CLIP_VALUE);
                #endif

                return positionCS;

            }
            CBUFFER_START(UnityPerMaterial)
                
                sampler2D _MainTex;
                sampler2D _WindTexture;
                float4 _WindTexture_ST;
                float _WindTextureScale;
                float _WindSpeed;
                float _WindStrength;
                float _PivotY;
                float _AnimationShadowRenderDistance;
                float _InteractDistance;
                float _InteractStrength;
                half4 _BaseColor;
                
                float _WaveLocalSpeed,_WaveLocalStrength,_Randomize;
                float4 _WaveLocalDir;

                float _WaveWorldSpeed,_WaveWorldStrength;
                float4 _WaveWorldDir;
                float _RandomWorldLength;
                float _InteractOffsetY;
                float4 _PlayerWpos;

                float _LightMaxIntensity;
                float _MainLightShadowIntensity;
            CBUFFER_END

            struct vertOut
            {
                float4 positionCS : SV_POSITION;// HCS: H CLIP SPACE
                
            };


            vertOut vert(appdata v)
            {
                vertOut o;
                float3 positionWS;
                positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;
                float uvY = lerp(0,1,  v.positionOS.y+ _PivotY);


                _WindTexture_ST.zw += _Time.y*_WindSpeed;
                float2 positionWSUV = positionWS.xz*_WindTextureScale;
                float2 windTextureUV  = TRANSFORM_TEX( positionWSUV, _WindTexture);
                float windTexture = tex2Dlod(_WindTexture, float4(windTextureUV,0,0)).x;


                float distanceToCamera = length(_WorldSpaceCameraPos - positionWS);
                

                if(distanceToCamera < _AnimationShadowRenderDistance){
                    float3 playerWpos = _PlayerWpos.xyz;
                    playerWpos.y += _InteractOffsetY;
                    float3 directionToPlayer = normalize( playerWpos.xyz - positionWS.xyz);

                    float distanceToPlayer = distance(playerWpos.xyz, positionWS);
                    distanceToPlayer = 1 - clamp(distanceToPlayer,0,_InteractDistance)/_InteractDistance;

                    float random = Random( positionWS,_Randomize) ;

                    v.positionOS.xz += WindHorizontalOS(float2(0,uvY), random, _WaveLocalSpeed,_WaveLocalStrength,_WaveLocalDir).xz;
                
                    

                    positionWS = GetVertexPositionInputs(v.positionOS.xyz).positionWS;


                    positionWS.xz += windTexture*_WindStrength*(uvY);
                    positionWS.xz +=  WindHorizontalWS(float2(0,uvY), random, _WaveWorldSpeed,_WaveWorldStrength,_WaveWorldDir).xz;
                    positionWS.xz -=  directionToPlayer.xz*distanceToPlayer*uvY*_InteractStrength;
                    //o.positionWS.y -=  directionToPlayer.y*distanceToPlayer*(v.positionOS.y+ _PivotY)*1;
                }
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);//conver OS normal to WS normal
                o.positionCS = GetShadowCasterPositionCS(positionWS, (normalWS)); //apply shadow bias
                return o;
            }


            half4 frag(vertOut i) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
    CustomEditor "URP_Global_Editor"
}
