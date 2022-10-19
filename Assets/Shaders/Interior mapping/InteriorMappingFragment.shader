Shader "Volume/InteriorMappingFragment"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ColorFloor("Color Floor", Color) = (1,1,1,1)
		_ColorRoof("Color Roof", Color) = (1,1,1,1)
		_ColorWall("Color Wall", Color) = (1,1,1,1)
		_ColorWall2("Color Wall 2", Color) = (1,1,1,1)
	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 objectPos: TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			//Variables
			float4 _ColorFloor;
			float4 _ColorRoof;
			float4 _ColorWall;
			float4 _ColorWall2;
			


			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				
				//Save the position of the vertex in object space for use in vertex function 
				o.objectPos = float3(v.vertex.xyz);

				return o;
			}



			//Get the square distance between two positions
			float getSquareDistanceToWall(float3 pos1, float3 pos2)
			{
				float3 vec = pos1 - pos2;

				//The square length of the ray, which is faster to calculate than the real distance
				float sqrDist = (vec.x * vec.x) + (vec.y * vec.y) + (vec.z * vec.z);

				return sqrDist;
			}
			


			fixed4 frag (v2f i) : SV_Target
			{
				//How many rooms? (not exactly number of rooms, but sometimes)
				float wallFrequencies = 2;	
				
				//Need to do everything in object space so we can rotate the building
				//Cam pos in object space
				float3 camObjPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;
				
				//Direction to this fragment in object space, dont need to normalize
				float3 direction = i.objectPos - camObjPos;



				//Find intersection points
				//Multiply by 0.999 to prevent first wall from being displayed
				//floor(x) returns the greatest integer not greater than x
				float3 corner = floor(i.objectPos * wallFrequencies * 0.999);
				
				//Step(a,x) returns either 0 or 1
				//1 for each component of x that is greater than or equal to the corresponding component in the reference vector a
				//0 otherwise
				float3 walls = corner + step(float3(0, 0, 0), direction);
				
				walls /= wallFrequencies;

				float3 rayfractions = (walls - camObjPos) / direction;
				
				float3 intersectionXY = camObjPos + rayfractions.z * direction;
				//Floor or roof
				float3 intersectionXZ = camObjPos + rayfractions.y * direction;
				float3 intersectionZY = camObjPos + rayfractions.x * direction;

				

				//Find which wall is closest to the camera and display its color
				//Wall 1
				float minDistance = getSquareDistanceToWall(intersectionXY, camObjPos);

				float4 col = _ColorFloor;

				//Floor or roof 
				float dist2 = getSquareDistanceToWall(intersectionXZ, camObjPos);

				if (dist2 < minDistance)
				{
					col = _ColorWall;

					minDistance = dist2;
				}

				//Wall 3
				if (getSquareDistanceToWall(intersectionZY, camObjPos) < minDistance)
				{
					col = _ColorWall2;
				}
				

				return col;
			}
			ENDCG
		}
	}
}
