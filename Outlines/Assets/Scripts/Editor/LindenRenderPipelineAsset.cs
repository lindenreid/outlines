#if UNITY_EDITOR
using System;
using UnityEditor;
using UnityEditor.ProjectWindowCallback;
#endif

namespace UnityEngine.Experimental.Rendering.LightweightPipeline
{
    [CreateAssetMenu(menuName = "Rendering/Linden Pipeline")]
    public class LindenRenderPipelineAsset : LightweightRenderPipelineAsset
    {
        protected override IRenderPipeline InternalCreatePipeline() {
            return new LindenRenderPipeline(this);
        }
    }
}