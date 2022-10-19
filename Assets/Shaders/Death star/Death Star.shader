// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Erik/Death Star"
{
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
		}

		Pass
		{
			//Traditional transparency
			Blend SrcAlpha OneMinusSrcAlpha


			CGPROGRAM

			//Pragmas
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"


			//Structs
			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};


			//Input
			//appdata_base includes position, normal and one texture coordinate
			v2f vert(appdata_base v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;

				return o;
			}


			//
			//User defined functions and variables
			//

			//Camera
			float3 _CamPos;
			float3 _CamRight;
			float3 _CamUp;
			float3 _CamForward;
			//Planet
			float3 _StarPos;
			//Unity specific
			float4 _LightColor0;



			//Standardized distance functions needed to build the death star
			//Get the distance to a sphere
			float getDistanceSphere(float sphereRadius, float3 circleCenter, float3 rayPos)
			{
				float distance = length(rayPos - circleCenter) - sphereRadius;

				return distance;
			}

			//Get the distance to a box
			float getDistanceBox(float3 boxSize, float3 boxCenter, float3 rayPos)
			{
				return length(max(abs(rayPos - boxCenter) - boxSize, 0.0));
			}



			//The distance function, which returns the distance to death star from a position
			float distFunc(float3 pos)
			{
				const float starRadius = 50.0;

				const float3 cutOutBoxSize = float3(starRadius, starRadius, starRadius);

				//The death star consists of 2 half-spheres and this is the gap between them
				const float distanceBetweenHalf = 0.5;


				//Top half
				float3 starPosTop = _StarPos + float3(0.0, distanceBetweenHalf, 0.0);

				float starDistanceTop = getDistanceSphere(starRadius, starPosTop, pos);

				float3 cutOutPosTop = starPosTop + float3(0.0, starRadius, 0.0);

				float cutOutDistanceTop = getDistanceBox(cutOutBoxSize, cutOutPosTop, pos);


				//Bottom half
				float3 starPosBottom = _StarPos + float3(0.0, -distanceBetweenHalf, 0.0);

				float starDistanceBottom = getDistanceSphere(starRadius, starPosBottom, pos);

				float3 cutOutPosBottom = starPosBottom + float3(0.0, -starRadius, 0.0);

				float cutOutDistanceBottom = getDistanceBox(cutOutBoxSize, cutOutPosBottom, pos);


				//The final distance to the main star body
				float starBodyDist = min(max(starDistanceTop, cutOutDistanceTop), max(starDistanceBottom, cutOutDistanceBottom));


				//The cutout hole in the death star
				const float cutOutRadius = starRadius * 0.3;

				//The cutout is always facing the center of the map
				//First move the cutout sphere up
				float3 cutOutPos = _StarPos + float3(0.0, starRadius / 2.0, 0.0);

				//Then move the  cutout sphere in the direction to the center
				float3 centerDir = normalize(-_StarPos);
				
				//Don't move in y direction
				centerDir.y = 0;

				cutOutPos += starRadius * centerDir;

				float cutOutDistance = getDistanceSphere(cutOutRadius, cutOutPos, pos);


				//The final distance to the death star
				return max(starBodyDist, -cutOutDistance);
			}



			//Get color at a certain position
			fixed4 getColor(float3 pos, fixed3 color)
			{
				//Find the normal at this point
				const fixed2 eps = fixed2(0.00, 0.02);

				//Can approximate the surface normal using what is known as the gradient. 
				//The gradient of a scalar field is a vector, pointing in the direction where the field 
				//increases or decreases the most.
				//The gradient can be approximated by numerical differentation
				fixed3 normal = normalize(float3(
					distFunc(pos + eps.yxx) - distFunc(pos - eps.yxx),
					distFunc(pos + eps.xyx) - distFunc(pos - eps.xyx),
					distFunc(pos + eps.xxy) - distFunc(pos - eps.xxy)));

				//The main light is always a direction and not a position
				//This is the direction to the light
				fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				//Add diffuse light (intensity is already included in _LightColor0 so no need to add it)
				fixed3 diffuse = _LightColor0.rgb * max(dot(lightDir, normal), 0.0);

				
				//Add ambient light
				//According to internet, the ambient light should always be multiplied by 2
				fixed3 finalLight = diffuse + (UNITY_LIGHTMODEL_AMBIENT.xyz * 2.0);


				//Add all lights to the base color
				color *= finalLight;

				

				//Add fog to make it more moon-like
				float distance = length(pos - _CamPos);
				
				fixed fogDensity = 0.1;

				const fixed3 fogColor = fixed3(0.8, 0.8, 0.8);

				//Fog fractions
				//Exponential
				float f = exp(-distance * fogDensity);
				//Exponential square
				//float f = exp(-distance * distance * fogDensity * fogDensity);
				//Linear - the first term is where the fog begins
				//float f = fogDensity * (0.0 - distance);

				color = (fogColor * (1.0 - f)) + (color * f);


				//We also need to add alpha to the color
				fixed4 finalColor = fixed4(color, 1.0);

				//To make it more moon-like, the shadow should be transparent as the moon is when we see it in daylight
				finalColor.a *= max(dot(lightDir, normal) * 1.0, 0.0);


				return finalColor;
			}



			//Get the color where the ray hit something, else return transparent color
			fixed4 getColorFromRaymarch(float3 pos, float3 ray)
			{
				//Init the color to transparent
				fixed4 color = 0;

				for (int i = 0; i < 64; i++)
				{
					//Get the current distance to the death star along this ray
					float d = distFunc(pos);

					//If we have hit or are very close to the death star (negative distance means inside)
					if (d < 0.005)
					{
						//Get the color at this position
						color = getColor(pos, fixed3(0.7, 0.7, 0.7));

						break;
					}

					//If we are far away from ever reaching the death star along this ray
					if (d > 400.0)
					{
						break;
					}

					//Move along the ray with a variable step size
					//Multiply with a value of your choice to increase/decrease accuracy
					pos += ray * d * 0.5;
				}

				return color;
			}



			//Output
			fixed4 frag(v2f i) : SV_Target
			{
				//Transform the uv so they go from -1 to 1 and not 0 to 1, like a normal coordinate system, 
				//which begins at the center
				float2 uv = i.uv * 2.0 - 1.0;

				
				//Camera - use the camera in the scene
				float3 startPos = _CamPos;

				//Focal length obtained from experimentation
				fixed focalLength = 0.62;

				//The final ray at this pixel
				fixed3 ray = normalize(_CamUp * uv.y + _CamRight * uv.x + _CamForward * focalLength);

				
				//Get the color
				fixed4 color = getColorFromRaymarch(startPos, ray);


				return color;
			}

			ENDCG
		}
	}
}
