Shader "Custom/FogLoD" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB)", 2D) = "white" {}
	_BumpMap ("Normalmap", 2D) = "bump" {}
	_DisplacementMap ("Displacement Map", 2D) = "white" {}
	_Displacement ("Displacement", Float) = 0
	_SpecularColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
	_SpecularPower ("Specular Power", Float) = 48.0
	_TessellationLevel ("Tessellation Level", Float) = 1
	_DistanceBasedTessellation ("Distance Based Tessellation", Range (0, 1)) = 1
	_EdgeTessellationFactor ("Edge Tessellation Factor", Range (0, 1)) = 0
	_ShadingLevel ("Shading Level", Range(0, 3)) = 3
}

SubShader {
	Tags { "RenderType"="Opaque" }
	LOD 300

Cull Off

CGPROGRAM
#pragma surface surf LoDControlled vertex:vert tessellate:tessateMesh
#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "Lighting.cginc"

sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _DisplacementMap;
fixed4 _Color;
fixed4 _SpecularColor;
float _SpecularPower;
float _Displacement;
float _TessellationLevel;
float _ShadingLevel;
float _DistanceBasedTessellation;
float _EdgeTessellationFactor;

struct appdata {
    float4 vertex : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float2 texcoord : TEXCOORD0;
};

struct Input {
	float2 uv_MainTex;
	float2 uv_BumpMap;
};

half4 LightingLoDControlled (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {

	if (_ShadingLevel < 1) {
		return half4 (0.5, 0.5, 0.5, 0.5);
	}
	else if (_ShadingLevel < 2
	) {
		//Use Lambert
		half NdotL = dot (s.Normal, lightDir);
		half4 c;
		c.rgb = s.Albedo * _LightColor0.rgb * (NdotL * atten);
		c.a = s.Alpha;
		return c;
	}
	else {
		//Use Blinn-Phong (with specular effects
		half3 h = normalize (lightDir + viewDir);

		half diff = max (0, dot (s.Normal, lightDir));

		float nh = max (0, dot (s.Normal, h));
		float spec = pow (nh, _SpecularPower);

		half4 c;
		c.rgb = (s.Albedo * _LightColor0.rgb * diff + _SpecularColor * spec) * atten;
		c.a = s.Alpha;
		return c;
	}
	
	return half4 (0, 0, 0, 0);
}

float getEdgeFactor (float cosValue) {

	float minEdgeFactor = pow(1.0 - cosValue, 2.0);
	return 1.0 + _EdgeTessellationFactor * (minEdgeFactor - 1.0);
}

float4 tessateMesh (appdata v0, appdata v1, appdata v2) {

	float4 cameraPosition = mul(_World2Object, float4(_WorldSpaceCameraPos, 1));
	float3 viewDirection = normalize(cameraPosition - v0.vertex.xyz);
	float cos0 = abs (dot (normalize (v0.normal), viewDirection));
	float edgeFactor0 = getEdgeFactor (cos0);
	
	viewDirection = normalize(cameraPosition - v1.vertex.xyz);
	float cos1 = abs (dot (normalize (v1.normal), viewDirection));
	float edgeFactor1 = getEdgeFactor (cos1);
	
	viewDirection = normalize(cameraPosition - v2.vertex.xyz); 
	float cos2 = abs (dot (normalize (v2.normal), viewDirection));
	float edgeFactor2 = getEdgeFactor (cos2);
	
	float4 tessellationFactors = float4 (edgeFactor1+edgeFactor2, 
										edgeFactor2+edgeFactor0, 
										edgeFactor0+edgeFactor1, 
										edgeFactor0+edgeFactor1+edgeFactor2) / float4(2,2,2,3);
	
	float4 center = float4 (1, 1, 1, 1) * 5;
	
	if (_DistanceBasedTessellation > 0.5) {
	
		center = (v0.vertex + v1.vertex + v2.vertex) / 3.0;
		center = mul(UNITY_MATRIX_MVP, center);
	}
							
	//To use non-uniform tessellation without tearing, 
	//refer: http://answers.unity3d.com/questions/823170/displacementtessellation-tearingcracks.html

	float tessellationLevel = max (floor (_TessellationLevel / center.w), 1);
	return tessellationFactors * tessellationLevel;
}

void vert (inout appdata v) {
	
	float displacementIntensity = tex2Dlod(_DisplacementMap, float4(v.texcoord.xy, 0, 0)).r;
	v.vertex.xyz += v.normal * (displacementIntensity - 0.502) * _Displacement;
}

void surf (Input IN, inout SurfaceOutput o) {

	fixed4 c = _Color;
	if (_ShadingLevel >= 1) {
	
		o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
	
		c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
		o.Albedo = c.rgb;
		o.Alpha = c.a;
	}
}
ENDCG  
}

FallBack "Legacy Shaders/Diffuse"
}
