Shader "Custom/TCSurfaceTest" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
	}
	
	SubShader{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM

		//#include "TCFramework.cginc"
		//#include "TCDefaultVert.cginc"


		sampler2D _MainTex;

		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows
		#pragma target 4.5

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		float4 _Color;

		//#pragma instancing_options procedural:TCDefaultProc	

		//TODO: Proc instancing doesn't work with this right?
		UNITY_INSTANCING_CBUFFER_START(Props)

		UNITY_INSTANCING_CBUFFER_END


		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}

