	        
            

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