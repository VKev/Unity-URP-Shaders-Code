	        
            
            #ifdef UNIVERSAL_LIGHTING_INCLUDED
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
            #endif

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
            

            float2 unity_gradientNoise_dir(float2 p)
            {
                p = p % 289;
                float x = (34 * p.x + 1) * p.x % 289 + p.y;
                x = (34 * x + 1) * x % 289;
                x = frac(x / 41) * 2 - 1;
                return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
            }

            float unity_gradientNoise(float2 p)
            {
                float2 ip = floor(p);
                float2 fp = frac(p);
                float d00 = dot(unity_gradientNoise_dir(ip), fp);
                float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
                float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
                float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
                fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
                return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
            }

            void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
            {
                Out = unity_gradientNoise(UV * Scale) + 0.5;
            }

            void Unity_NormalFromHeight_Tangent_float(float In, float Strength, float3 Position, float3x3 TangentMatrix, out float3 Out)
            {
                float3 worldDerivativeX = ddx(Position);
                float3 worldDerivativeY = ddy(Position);

                float3 crossX = cross(TangentMatrix[2].xyz, worldDerivativeX);
                float3 crossY = cross(worldDerivativeY, TangentMatrix[2].xyz);
                float d = dot(worldDerivativeX, crossY);
                float sgn = d < 0.0 ? (-1.f) : 1.f;
                float surface = sgn / max(0.00000000000001192093f, abs(d));

                float dHdx = ddx(In);
                float dHdy = ddy(In);
                float3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
                Out = normalize(TangentMatrix[2].xyz - (Strength * surfGrad));
                Out = TransformWorldToTangent(Out, TangentMatrix);
            }

            void Unity_NormalFromHeight_World_float(float In, float Strength, float3 Position, float3x3 TangentMatrix, out float3 Out)
            {
                float3 worldDerivativeX = ddx(Position);
                float3 worldDerivativeY = ddy(Position);

                float3 crossX = cross(TangentMatrix[2].xyz, worldDerivativeX);
                float3 crossY = cross(worldDerivativeY, TangentMatrix[2].xyz);
                float d = dot(worldDerivativeX, crossY);
                float sgn = d < 0.0 ? (-1.f) : 1.f;
                float surface = sgn / max(0.00000000000001192093f, abs(d));

                float dHdx = ddx(In);
                float dHdy = ddy(In);
                float3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
                Out = normalize(TangentMatrix[2].xyz - (Strength * surfGrad));
            }



            