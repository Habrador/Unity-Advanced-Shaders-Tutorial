Shader "Volume/HoleInGround" 
{
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		_NoiseTex("Noise texture", 2D) = "white" {}
		_MaskTex("Mask texture", 2D) = "white" {}
		//_RadialTex("Radial texture", 2D) = "white" {}
		//How deep is the hole? Has to be above 0 to avoid division by 0
		_HoleDepth("Depth", Range(0.0001,5)) = 0.5
		//Whats the size of the hole?
		_HoleSize("Size", Range(0,10)) = 0.5
	}
	
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		
		#pragma surface surf Lambert vertex:vert
		#pragma target 3.0



		//Properties values
		float4 _Color;
		sampler2D _NoiseTex;
		sampler2D _MaskTex;
		//sampler2D _RadialTex;
		float _HoleDepth;
		float _HoleSize;



		struct Input
		{
			//What Unity can give you
			float2 uv_NoiseTex;

			//What you have to calculate yourself
			float3 tangentViewDir;
		};



		void vert(inout appdata_full i, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			//Calculate the view direction in tangent space from world space			
			float3 worldVertexPos = mul(unity_ObjectToWorld, i.vertex).xyz;
			float3 worldViewDir = worldVertexPos - _WorldSpaceCameraPos;

			//To convert from world space to tangent space we need the following
			//https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
			float3 worldNormal = UnityObjectToWorldNormal(i.normal);
			float3 worldTangent = UnityObjectToWorldDir(i.tangent.xyz);
			float3 worldBitangent = cross(worldNormal, worldTangent) * i.tangent.w * unity_WorldTransformParams.w;

			//Use dot products instead of building the matrix
			o.tangentViewDir = float3(
				dot(worldViewDir, worldTangent),
				dot(worldViewDir, worldNormal),
				dot(worldViewDir, worldBitangent)
				);
		}



		//Get the actual height in m
		float getActualHeight(float blackAndWhite)
		{
			float actualHeight = exp2(blackAndWhite * _HoleDepth) - 1;

			//-1 because the ray is going down 
			actualHeight *= -1;

			return actualHeight;
		}



		//Get the height in range 0->1 a uv position
		float4 getGrayScaleDepth(float2 texturePos)
		{
			//The crack texture
			float4 finalColor = tex2Dlod(_NoiseTex, float4(texturePos, 0, 2));


			//Add the hole
			//Animate the size of the hole and normalize sinx to 0->1 range
			float animValue = (sin(_Time[1] * 0.5) + 1) / 2;
			
			float holeSize = lerp(0.0, _HoleSize, animValue);
			//float holeSize = _HoleSize;

			//Mask the texture to form a hole
			//Multiplication of alpha will give change the size of the hole
			float holeAlpha = (tex2Dlod(_MaskTex, float4(texturePos, 0, 2)).r) * holeSize;

			//But we also need to mask the border to make it darker
			finalColor = lerp(finalColor, float4(1, 1, 1, 1), 1 - holeAlpha);
			//Run it again to get a better result!
			finalColor = lerp(finalColor, float4(1, 1, 1, 1), 1 - holeAlpha);


			//White should be deeper
			float height = (1 - finalColor.r);

			return height;
		}



		//Get the height based on interpolation between the two positions based on their distance to terrain
		float2 getWeightedTexPos(float3 rayPos, float3 rayDir, float stepDistance)
		{
			//Move one step back to the position before we hit terrain
			float3 oldPos = rayPos - stepDistance * rayDir;

			float oldHeight = getActualHeight(getGrayScaleDepth(oldPos.xz));

			//Always positive
			float oldDistToTerrain = abs(oldHeight - oldPos.y);

			float currentHeight = getActualHeight(getGrayScaleDepth(rayPos.xz));

			//Always negative
			float currentDistToTerrain = rayPos.y - currentHeight;

			float weight = currentDistToTerrain / (currentDistToTerrain - oldDistToTerrain);

			//Calculate a weighted texture coordinate
			//If height is -2 and oldHeight is 2, then weightedTex is 0.5, which is good because we should use 
			//the exact middle between the coordinates
			float2 weightedTex = oldPos.xz * weight + rayPos.xz * (1 - weight);

			return weightedTex;
		}



		void surf(Input IN, inout SurfaceOutput o) 
		{
			//Where is the ray starting? y is up and we always start at the surface
			float3 rayPos = float3(IN.uv_NoiseTex.x, 0, IN.uv_NoiseTex.y);

			//What's the direction of the ray?
			float3 rayDir = normalize(IN.tangentViewDir);

			//Find where the ray is intersecting with the ground with a raymarch algorithm
			int STEPS = 500;
			float stepDistance = 0.002;

			//The default color used if the ray doesnt hit anything
			float4 finalColor = float4(1, 0, 0, 1);

			for (int i = 0; i < STEPS; i++)
			{
				//Get the current height at this uv coordinate
				float height = getActualHeight(getGrayScaleDepth(rayPos.xz));

				//If the ray is below the surface
				if (rayPos.y < height)
				{
					//Fire a ray from the last position with smaller step size to get a more accurate intersection point
					//rayPos -= stepDistance * rayDir;

					//int STEPS_SMALL = 10;
					////Make sure we cover the entire distance
					//float stepDistanceSmall = stepDistance / (STEPS_SMALL - 1);
					
					//Get the weighted texture position based on interpolation between the two positions based on their distance to terrain
					float2 weightedTex = getWeightedTexPos(rayPos, rayDir, stepDistance);
					
					//Get the interpolated height
					height = getActualHeight(getGrayScaleDepth(weightedTex));

					//The height is negative so make it positive again so we can use the height as color
					finalColor = getGrayScaleDepth(weightedTex);

					//Stop the raymarching because we have found ground
					break;
				}
				//The ray is still above the surface
				else
				{
					//Move along the ray
					rayPos += stepDistance * rayDir;
				}
			}


			finalColor = lerp(float4(0,0,0,0), _Color, (1-finalColor.r));

			
			//Debug
			//finalColor = getGrayScaleDepth(IN.uv_NoiseTex);

			//Output
			o.Albedo = finalColor.rgb;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
