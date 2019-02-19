using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

namespace Linden.Rendering {
    [Serializable]
    [PostProcess(typeof(OutlineRenderer), PostProcessEvent.BeforeStack, "Custom/Outlines")]
    public sealed class Outline : PostProcessEffectSettings
    {
        public FloatParameter size = new FloatParameter { value = 1.0f };
        public FloatParameter depthSensitivity = new FloatParameter { value = 1.0f };
        public FloatParameter normalSensitivity = new FloatParameter { value = 1.0f };
        public FloatParameter distance = new FloatParameter { value = 1.0f };
        public ColorParameter color = new ColorParameter { value = Color.white };
        public TextureParameter noiseTex = new TextureParameter { value = null };
        public FloatParameter noiseScale = new FloatParameter { value = 1.0f };
    }
    
    public sealed class OutlineRenderer : PostProcessEffectRenderer<Outline>
    {
        public override void Render(PostProcessRenderContext context)
        {
            var projectionMatrix = GL.GetGPUProjectionMatrix(context.camera.projectionMatrix, false);

            var sheet = context.propertySheets.Get(Shader.Find("Custom/Outline"));

            sheet.properties.SetFloat("_MaxSize", settings.size);
            sheet.properties.SetFloat("_DepthSensitivity", settings.depthSensitivity);
            sheet.properties.SetFloat("_NormalSensitivity", settings.normalSensitivity);
            sheet.properties.SetFloat("_DistanceMult", settings.distance);
            sheet.properties.SetColor("_Color", settings.color);
            sheet.properties.SetMatrix("unity_ViewToWorldMatrix", context.camera.cameraToWorldMatrix);
            sheet.properties.SetMatrix("unity_InverseProjectionMatrix", projectionMatrix.inverse);
            sheet.properties.SetTexture("_NoiseTex", settings.noiseTex);
            sheet.properties.SetFloat("_NoiseScale", settings.noiseScale);
        
            context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
        }
    }
}
