using System;
using System.Collections.Generic;
using UnityEngine.Rendering.PostProcessing;

namespace UnityEngine.Experimental.Rendering.LightweightPipeline
{
    public sealed partial class LindenRenderPipeline
    {
        static List<Vector4> m_ShadowBiasData = new List<Vector4>();

        public static bool IsStereoEnabled(Camera camera)
        {
            if (camera == null)
                throw new ArgumentNullException("camera");

            bool isSceneViewCamera = camera.cameraType == CameraType.SceneView;
            return XRGraphics.enabled && !isSceneViewCamera && (camera.stereoTargetEye == StereoTargetEyeMask.Both);
        }

        void SortCameras(Camera[] cameras)
        {
            Array.Sort(cameras, (lhs, rhs) => (int)(lhs.depth - rhs.depth));
        }
    }
}