using System;
using UnityEngine.Rendering;

namespace UnityEngine.Experimental.Rendering.LightweightPipeline
{
    /// <summary>
    /// Render all opaque objects to depth buffer
    /// </summary>
    public class LindenDepthPass : ScriptableRenderPass
    {
        const string k_RenderLindenDepthTag = "Linden Depth Pass";
        FilterRenderersSettings m_OpaqueFilterSettings;

        int kDepthBufferBits = 32;

        RenderTargetHandle colorAttachmentHandle { get; set; }
        public RenderTextureDescriptor descriptor { get; set; }

        public LindenDepthPass()
        {
            RegisterShaderPassName("LindenDepth");

            m_OpaqueFilterSettings = new FilterRenderersSettings(true)
            {
                renderQueueRange = RenderQueueRange.opaque,
            };
        }

        /// <summary>
        /// Configure the pass before execution
        /// </summary>
        /// <param name="baseDescriptor">Current target descriptor</param>
        /// <param name="colorAttachmentHandle">Color attachment to render into</param>
        public void Setup(
            RenderTextureDescriptor baseDescriptor,
            RenderTargetHandle colorAttachmentHandle
        )
        {
            this.colorAttachmentHandle = colorAttachmentHandle;
            baseDescriptor.colorFormat = RenderTextureFormat.ARGBFloat;
            baseDescriptor.depthBufferBits = kDepthBufferBits;
            descriptor = baseDescriptor;
        }

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderer renderer, ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderer == null)
                throw new ArgumentNullException("renderer");
            
            CommandBuffer cmd = CommandBufferPool.Get(k_RenderLindenDepthTag);
            using (new ProfilingSample(cmd, k_RenderLindenDepthTag))
            {
                cmd.GetTemporaryRT(colorAttachmentHandle.id, descriptor, FilterMode.Point);
                SetRenderTarget(
                    cmd:cmd,
                    colorAttachment:colorAttachmentHandle.Identifier(),
                    colorLoadAction:RenderBufferLoadAction.DontCare,
                    colorStoreAction:RenderBufferStoreAction.Store,
                    clearFlags:ClearFlag.All,
                    clearColor:Color.black,
                    dimension:descriptor.dimension
                );

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                Camera camera = renderingData.cameraData.camera;
                var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
                var drawSettings = CreateDrawRendererSettings(camera, sortFlags, RendererConfiguration.None, renderingData.supportsDynamicBatching);
                context.DrawRenderers(renderingData.cullResults.visibleRenderers, ref drawSettings, m_OpaqueFilterSettings);
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        /// <inheritdoc/>
        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (cmd == null)
                throw new ArgumentNullException("cmd");
            
            if (colorAttachmentHandle != RenderTargetHandle.CameraTarget)
            {
                cmd.ReleaseTemporaryRT(colorAttachmentHandle.id);
                colorAttachmentHandle = RenderTargetHandle.CameraTarget;
            }
        }
    }
}
