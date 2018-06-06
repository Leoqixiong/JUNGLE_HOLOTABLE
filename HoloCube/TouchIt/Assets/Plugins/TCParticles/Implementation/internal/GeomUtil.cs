using System;
using UnityEngine;
using UnityEngine.Scripting;

namespace TC.Internal {
	public static class GeomUtil {
		static Action<Plane[], Matrix4x4> s_calcFrustumPlanes;

		//Make sure IL2CPP does not strip away the frustum planes
		[Preserve]
		static Plane[] PreserveFunc() {
			return GeometryUtility.CalculateFrustumPlanes(Matrix4x4.identity);
		}

		public static void CalculateFrustumPlanes(Plane[] planes, Matrix4x4 worldToProjectMatrix) {
			if (s_calcFrustumPlanes == null) {
				var meth = typeof(GeometryUtility).GetMethod("Internal_ExtractPlanes", 
					System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic, null, new[] {typeof(Plane[]), typeof(Matrix4x4)}, null);
				s_calcFrustumPlanes = Delegate.CreateDelegate(typeof(Action<Plane[], Matrix4x4>), meth) as Action<Plane[], Matrix4x4>;
			}

			s_calcFrustumPlanes(planes, worldToProjectMatrix);
		}
	}
}