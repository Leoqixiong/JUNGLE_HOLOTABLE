#if !defined(TC_DEFAULT_VERT)
#define TC_DEFALT_VERT

sampler2D _MainTex;
float4 _MainTex_ST;

TCFragment TCDefaultVert (TCAppdata input) {
	TCFragment o;
	UNITY_SETUP_INSTANCE_ID(input);
	o.pos = UnityObjectToClipPos(input.vertex);
	o.uv = TRANSFORM_TEX(input.uv, _MainTex);
	o.col = input.col;
	return o;
}

#endif