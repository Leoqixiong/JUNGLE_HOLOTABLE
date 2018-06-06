#if !defined(TC_FRAMEWORK_INC)
#define TC_FRAMEWORK_INC

#define TC_COMPUTES 0

#if defined(SHADER_API_D3D11) || defined(SHADER_API_METAL) || defined(SHADER_API_VULKAN) || defined(SHADER_API_PS4) || defined(SHADER_API_XBOXONE) || defined(SHADER_API_GLCORE) ||	SHADER_STAGE_COMPUTE
	#if SHADER_TARGET > 40 || SHADER_STAGE_COMPUTE
		#undef TC_COMPUTES
		#define TC_COMPUTES 1
	#endif
#endif


#include "UnityCG.cginc"

//TODO: Unify?
#if SHADER_STAGE_COMPUTE
	uint _BufferOffset;
	uint _MaxParticles;
#else
	float _BufferOffset;
	float _MaxParticles;

#endif

	float _ParticleEmitCount;


struct Particle {
	float3 pos;
	float rotation;

	float3 velocity;
	float baseSize;

	float life;
	uint color;
};

#if TC_COMPUTES
	RWStructuredBuffer<Particle> particles : register(u1);
	StructuredBuffer<Particle> particlesRead : register(t1);
#endif

//global parameters
struct SystemParameters {
	float3 constantForce;
	float angularVelocity;
	float damping;
	float maxSpeed;
};

#if TC_COMPUTES
	StructuredBuffer<SystemParameters> systemParameters : register(t2);
#endif

float4 _LifeMinMax;
float _DeltTime;

sampler2D _ColTex;

#if !SHADER_STAGE_COMPUTE	
	sampler2D _LifetimeTexture;
#else
	Texture2D _LifetimeTexture;
	SamplerState sampler_LifetimeTexture;
#endif
			
float4 _PixelMult;
float4 _Glow;

float _MaxSpeed;
float _TCColourSpeed;

float4x4 TC_MATRIX_M;

float _SpeedScale;
float _LengthScale;
float _BillboardFlip = 1.0f;

float4 _SpriteAnimSize;
float4 _SpriteAnimUv;
float _Cycles;


//===============================
//variables
//Groupsize is the number of threads in X direction in a thread group. Constraints:
//->Mutliple of 64 (nvidia warps are sized 64)
//->Must be smaller than 1024 (or 768 for DX10, if unity would support that...)
//->Memory is shared between groups
//->Driver must be able to handle sharing memory between the number of threads in the group
#define TCGroupSize 128


uint GetId(uint id) {
	return (id + (uint)_BufferOffset) % ((uint)_MaxParticles);
}


//-----------------------------------------------------------------------------
// R8G8B8A8_UNORM <-> FLOAT4
//-----------------------------------------------------------------------------
uint D3DX_FLOAT_to_UINT(float _V, float _Scale) {
	return (uint)floor(_V * _Scale + 0.5f);
}

float4 UnpackColor(uint packedInput) {
	float4 unpackedOutput;
	unpackedOutput.x = (float)(packedInput & 0x000000ff) / 255;
	unpackedOutput.y = (float)(((packedInput >> 8) & 0x000000ff)) / 255;
	unpackedOutput.z = (float)(((packedInput >> 16) & 0x000000ff)) / 255;
	unpackedOutput.w = (float)(packedInput >> 24) / 255;

	return unpackedOutput;
}

uint PackColor(float4 unpackedInput) {
	uint packedOutput;

	packedOutput = ((D3DX_FLOAT_to_UINT(saturate(unpackedInput.x), 255)) |
		(D3DX_FLOAT_to_UINT(saturate(unpackedInput.y), 255) << 8) |
		(D3DX_FLOAT_to_UINT(saturate(unpackedInput.z), 255) << 16) |
		(D3DX_FLOAT_to_UINT(saturate(unpackedInput.w), 255) << 24));

	return packedOutput;
}

struct TCAppdata {
	float4 vertex : POSITION;
	float4 uv : TEXCOORD0;

#if defined(TC_BILLBOARD_STRETCHED)
	float4 uv2 : TEXCOORD1;
#endif

	float4 col : COLOR0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct TCFragment {
	float4 pos : SV_POSITION;
	float4 col : COLOR;
	half2 uv : TEXCOORD0;
};

//Instancing proc func override system	
#if !SHADER_STAGE_COMPUTE
	//Initialize override system

	//TODO: Little brittle - need to keep in sync with unity updates
	#if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED)
		//Give access to original clip pos			
		inline float4 UnityObjectToClipPosRaw(float4 vertex) {
			return UnityObjectToClipPos(vertex);
		}

		#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
			#undef DEFAULT_UNITY_SETUP_INSTANCE_ID
			#define DEFAULT_UNITY_SETUP_INSTANCE_ID(input)      { \
				uint inst = UNITY_GET_INSTANCE_ID(input); \
				Particle part = particlesRead[GetId(inst)]; \
				UnitySetupInstanceID(inst); \
				UNITY_INSTANCING_PROCEDURAL_FUNC(part, input); \
			}


			//Redefine transform
			#define UnityObjectToClipPos TcParticlesObjectToClipPos
			
			//Proc func fills input vertex as output position so override transform with no transform
			inline float4 TcParticlesObjectToClipPos(float4 vertex){
				return vertex;
			}
		#else
			#define DEFAULT_UNITY_SETUP_INSTANCE_ID(input)          UnitySetupInstanceID(UNITY_GET_INSTANCE_ID(input));
		#endif
	#else
		#define DEFAULT_UNITY_SETUP_INSTANCE_ID(input)

		//Give access to original clip pos			
		
		inline float4 UnityObjectToClipPosRaw(float4 vertex) {
			return UnityObjectToClipPos(vertex);
		}
	#endif

	//Vertex helper functions
	inline float4 GetParticleScreenPos(Particle part, TCAppdata input, float3 realVelocity){
		#if defined(TC_BILLBOARD) || defined(TC_BILLBOARD_STRETCHED)
			float4 pos = mul(unity_MatrixVP, mul(TC_MATRIX_M, float4(part.pos.xyz, 1.0f)));
				
			float mult = _PixelMult.x * lerp(1.0f, pos.w, _PixelMult.y);

			#ifdef TC_BILLBOARD
				float angle = part.rotation;
				float c = cos(angle);
				float s = sin(angle);

				float2 buf = input.vertex.xy * mult;
				float2 rot = float2(buf.x * c - buf.y * s, buf.x * s + buf.y * c);

				return pos + mul(UNITY_MATRIX_P, float4(buf, 0, 0));
				//TODO: Tail stretch is broken
			#elif TC_BILLBOARD_STRETCHED
				half3 sv = mul(UNITY_MATRIX_V, float4(realVelocity, 0.0f)).xyz + float3(0.0001f, 0.0f, 0.0f);
				half l = length(sv);

				half3 vRight = sv / l;
				half3 vUp = float3(-vRight.y, vRight.x, 0.0f);

				float4 vertStretch = float4(input.vertex.xy, 0, input.uv2.x);
				float stretchFac = (1.0f + (_LengthScale + vertStretch.w * l * _SpeedScale));

				return pos + mul(UNITY_MATRIX_P, float4(vertStretch.x * vRight * stretchFac + vertStretch.y * vUp, 1.0f) * mult);
			#endif
		#else
			return mul(unity_MatrixVP, mul(TC_MATRIX_M, float4(part.pos.xyz + input.vertex.xyz, 1.0f)));
		#endif
	}
#endif


#if !SHADER_STAGE_COMPUTE
	void TCDefaultProc(Particle part, inout TCAppdata input) {
		//Get current particle
		float life = 1 - part.life / _LifeMinMax.y;

		float4 lifeTex = tex2Dlod(_LifetimeTexture, float4(life, 0, 0, 0));
		float3 realVelocity = part.velocity + lifeTex.xyz;
		float size = part.baseSize * lifeTex.a;

		float2 cs = float2(cos(part.rotation), sin(part.rotation));
		//Rotate around z axis
		//TODO: Are we going to support 3D rotation someday?
		input.vertex.xyz = float3(input.vertex.x * cs.x + input.vertex.z * cs.y, input.vertex.y, input.vertex.z * cs.x - input.vertex.x * cs.y);

		input.vertex.xyz *= size;
		input.vertex = GetParticleScreenPos(part, input, realVelocity);
		input.vertex.w *= step(0, part.life);

		//Get particle color
		float4 partColor = UnpackColor(part.color);
		float4 tp = float4(lerp(life, length(realVelocity) * _MaxSpeed, _TCColourSpeed), 0.0f, 0.0f, 0.0f);
		input.col = tex2Dlod(_ColTex, tp) * _Glow * partColor;

#ifdef TC_UV_SPRITE_ANIM
		float2 uv = input.uv.xy;
		uint sprite = (uint)(part.life * (_SpriteAnimSize.x * _SpriteAnimSize.y) * _Cycles);
		uint x = sprite % (uint)_SpriteAnimSize.x;
		uint y = (uint)(sprite / _SpriteAnimSize.x);

		input.uv.xy = float2(x *_SpriteAnimSize.z, 1.0f - _SpriteAnimSize.w - y * _SpriteAnimSize.w) + uv * _SpriteAnimSize.zw;
#endif
	}
#endif


#endif