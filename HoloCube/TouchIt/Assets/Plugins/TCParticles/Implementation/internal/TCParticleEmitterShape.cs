using System;
using UnityEngine;

namespace TC.Internal {
	//TODO: This really shouldn't be this exposed
	[Serializable]
	public class ParticleEmitterShape {
		public EmitShapes shape = EmitShapes.Sphere;
		public MinMax radius = MinMax.Constant(5.0f);

		public Vector3 cubeSize = Vector3.one;
		public Mesh emitMesh;
		public bool normalizeArea = true;

		public Texture texture;

		[Range(0, 3)]
		public int uvChannel;

		[Range(0.0f, 89.9f)] public float coneAngle;

		public float coneHeight;
		public float coneRadius;
		public float ringOuterRadius;
		public float ringRadius;

		public float lineLength;
		public float lineRadius;

		public StartDirection startDirectionType = StartDirection.Normal;
		public Vector3 startDirectionVector;
		public float startDirectionRandomAngle;

		public bool spawnOnMeshSurface = true;

		static ComputeBuffer s_emitProtoBuffer;

		public void SetMeshData(ComputeShader cs, int kern, ref ParticleEmitterData emitter) {
			if (emitMesh == null) {
				return;
			}

			var buffer = TCParticleGlobalManager.GetMeshBuffer(emitMesh, uvChannel);
			uint onSurface;

			if (!spawnOnMeshSurface)
				onSurface = 0;
			else {
				onSurface = normalizeArea ? (uint) 1 : 2;
			}

			emitter.MeshVertLen = (uint)buffer.count;
			emitter.OnSurface = onSurface;
			cs.SetBuffer(kern, "emitFaces", buffer);

			if (texture != null) {
				cs.SetTexture(kern, "_MeshTexture", texture);
			}
			else {
				cs.SetTexture(kern, "_MeshTexture", Texture2D.whiteTexture);
			}
		}

		public void SetListData(ComputeShader cs, int kern, ParticleProto[] particlePrototypes) {
			if (s_emitProtoBuffer == null || s_emitProtoBuffer.count < particlePrototypes.Length) {
				if (s_emitProtoBuffer != null) {
					s_emitProtoBuffer.Release();
				}

				s_emitProtoBuffer = new ComputeBuffer(particlePrototypes.Length, ParticleProto.Stride);
			}

			s_emitProtoBuffer.SetData(particlePrototypes);
			cs.SetBuffer(kern, "emitList", s_emitProtoBuffer);
		}

		public void ReleaseData() {
			//TODO: this releases the buffer too often if others still use it.
			//Not a big deal for point clouds though
			if (s_emitProtoBuffer != null) {
				s_emitProtoBuffer.Release();
			}
		}
	}
}