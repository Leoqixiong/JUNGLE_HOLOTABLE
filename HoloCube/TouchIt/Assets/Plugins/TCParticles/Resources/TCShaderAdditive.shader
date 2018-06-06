Shader "TCParticles/Additive" {
	Properties {
		_MainTex ("Texture", 2D) = "white" { }
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	}

	Category  {
		Tags { "Queue"="Transparent" "RenderType"="Transparent"}

		SubShader {
			Pass {
				Blend SrcAlpha One
				ZWrite Off 
				Cull Off

				CGPROGRAM
					#pragma target 4.5
					#pragma vertex TCDefaultVert
					#pragma fragment frag

					#pragma multi_compile TC_BILLBOARD TC_BILLBOARD_STRETCHED TC_MESH
					#pragma multi_compile TC_UV_NORMAL TC_UV_SPRITE_ANIM

					#include "TCFramework.cginc"
					#include "TCDefaultVert.cginc"

					#pragma multi_compile_instancing
					#pragma instancing_options procedural:TCDefaultProc

					float4 frag (TCFragment i) : SV_Target {
						return tex2D(_MainTex, float4(i.uv, 0, -3)) * i.col;
					}
				ENDCG
			}
		}
	}
}
