	        
            

            float LightLambert(float3 normal, Light light){
                float3 N = normalize( normal);
                float3 L = normalize(light.direction); 
                return  saturate(  dot (N,L));
            }
            
            float3 DeffuseLight(float3 normal, Light light){
                float lambert = LightLambert(normal, light);
                float3 deffuseLight = lambert;//*light.color * (light.distanceAttenuation * light.shadowAttenuation);
                return deffuseLight;
            }


            //*light.color * (light.distanceAttenuation * light.shadowAttenuation) : lightcolor of light
            float3 SpecularLight(float3 normal,float3 wPos, float _Gloss, Light light){
                float3 lambert = LightLambert(normal,light);
                float3 N = normalize( normal);
                float3 V= GetWorldSpaceNormalizeViewDir(wPos);
                float3 L = normalize(light.direction); 
                float3 H = normalize(L+V);
                float3 specularLight = saturate(dot(H,N))*(lambert>0);
                float specularExponent = exp2(_Gloss*11)+2;
                specularLight = pow(specularLight,specularExponent);//*light.color * (light.distanceAttenuation * light.shadowAttenuation);
                return specularLight;
            }

            float Random(float3 positionWS, float randomScale){
                
                return randomScale*(abs(positionWS.x)+abs(positionWS.z));
            }



            float4 WindHorizontalOS(float2 uv, float random, float Speed,float Amplitude,float4 Dir){
                float4 result = float4(0,0,0,0);
                result.xz = sin((_Time.y + random)*Speed)
                                  *Amplitude*uv.y
                                  *normalize(Dir.xy);

                return result;
            }
            float4 WindVerticalOS(float2 uv , float random, float Speed,float Amplitude){
                float4 result = float4(0,0,0,0);
                result.y = sin((_Time.y + random)*Speed)
                                *Amplitude
                                *uv.y;

                return result;
            }

            float3 WindHorizontalWS(float2 uv, float random, float Speed,float Amplitude,float4 Dir){
                float3 result = float3(0,0,0);
                result.xz += sin((_Time.y + random)*Speed)
                                 *Amplitude
                                 *normalize( Dir.xy)
                                 *uv.y;
                return result;
            }

            float3x3 TransposeTangent(float3 tangentWS, float3 biTangentWS, float3 normalWS){
               
               return transpose(float3x3(tangentWS, biTangentWS, normalWS ));
            }

            float3 QuadScatter(float3x3 transposeTangent ,float2 uv, float random, float BlendScale, float FluffyScale){

                float3 quadScatter = (mul(float3(2*uv-1,0), transposeTangent ).xyz);

                quadScatter = mul(float4( quadScatter,0),unity_ObjectToWorld).xyz; 
                quadScatter = normalize(quadScatter)*FluffyScale;
                quadScatter = lerp(0,quadScatter,BlendScale);

                return quadScatter;
            }
            