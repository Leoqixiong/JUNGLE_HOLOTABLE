using UnityEngine;

//Utilities class

namespace TC.Internal {
	public class TCHelper {
		static Color[] s_colours = new Color[c_dimSize];
		const int c_dimSize = 128;

		//Prodcues a texture of resolution of dimx1 encoding a gradient
		public static void TextureFromGradient(Gradient gradient, Texture2D toSet, Color tint) {
			if (toSet == null) {
				return;
			}

			for (int i = 0; i < c_dimSize; ++i) {
				s_colours[i] = gradient.Evaluate(i / (c_dimSize - 1.0f)) * tint;
			}

			toSet.SetPixels(s_colours);
			toSet.Apply();
		}

		//TODO: Replace in 2017.2
		static float[] s_matrixArr4 = new float[16];

		public static void SetMatrix(ComputeShader shader, int id, Matrix4x4 matrix) {
			for (int i = 0; i < 16; ++i) {
				s_matrixArr4[i] = matrix[i];
			}
			shader.SetFloats(id, s_matrixArr4);
		}
	}
}