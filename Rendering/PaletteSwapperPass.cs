using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

namespace Rendering {
    public class PaletteSwapperPass : ScriptableRenderPass {
        private static readonly int IsColorRamp = Shader.PropertyToID("_IsColorRamp");
        private static readonly int Invert = Shader.PropertyToID("_Invert");
        private static readonly int ColorPalette = Shader.PropertyToID("_ColorPalette");
        
        private const string TextureName = "_PaletteSwapperTexture";
        
        private readonly Material material;
        private readonly PaletteSwapperSettings settings;

        private RenderTextureDescriptor descriptor;
        
        public PaletteSwapperPass(Material material, PaletteSwapperSettings settings) {
            this.material = material;
            this.settings = settings;

            descriptor = new RenderTextureDescriptor(Screen.width, Screen.height, RenderTextureFormat.Default, 0);
        }

        private void UpdateMaterialSettings() {
            if (material == null) return;
            
            material.SetTexture(ColorPalette, settings.colorPalette);
            material.SetInt(Invert, settings.invert ? 1 : 0);
            material.SetInt(IsColorRamp, settings.isColorRamp ? 1 : 0);
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