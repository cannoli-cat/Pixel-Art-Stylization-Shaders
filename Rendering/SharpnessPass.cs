using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

namespace Rendering {
    public class SharpnessPass : ScriptableRenderPass {
        private static readonly int Amount = Shader.PropertyToID("_Amount");
        
        private const string TextureName = "_SharpnessTexture";
        
        private readonly Material material;
        private readonly SharpnessSettings settings;

        private RenderTextureDescriptor descriptor;
        
        public SharpnessPass(Material material, SharpnessSettings settings) {
            this.material = material;
            this.settings = settings;

            descriptor = new RenderTextureDescriptor(Screen.width, Screen.height, RenderTextureFormat.Default, 0);
        }

        private void UpdateMaterialSettings() {
            if (material == null) return;
            
            material.SetFloat(Amount, settings.amount);
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData) {
            var resourceData = frameData.Get<UniversalResourceData>();
            var cameraData = frameData.Get<UniversalCameraData>();
            
            if (resourceData.isActiveTargetBackBuffer || cameraData.renderType == CameraRenderType.Overlay) return;
            
            descriptor.width = cameraData.cameraTargetDescriptor.width;
            descriptor.height = cameraData.cameraTargetDescriptor.height;
            descriptor.depthBufferBits = 0;

            var srcCamColor = resourceData.activeColorTexture;
            var dst = UniversalRenderer.CreateRenderGraphTexture(renderGraph, descriptor, TextureName, false);
            
            UpdateMaterialSettings();
            if (!srcCamColor.IsValid() || !dst.IsValid()) return;
            
            renderGraph.AddBlitPass(new RenderGraphUtils.BlitMaterialParameters(srcCamColor, dst, material, 0));
            resourceData.cameraColor = dst;
        }
    }
}