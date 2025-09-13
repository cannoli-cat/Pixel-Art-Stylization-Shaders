using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

namespace Rendering {
    public class DitherPass : ScriptableRenderPass {
        private static readonly int Spread = Shader.PropertyToID("_Spread");
        private static readonly int RedColorCount = Shader.PropertyToID("_RedColorCount");
        private static readonly int GreenColorCount = Shader.PropertyToID("_GreenColorCount");
        private static readonly int BlueColorCount = Shader.PropertyToID("_BlueColorCount");
        private static readonly int BayerLevel = Shader.PropertyToID("_BayerLevel");
        
        private const string DitherTextureName = "_DitherTexture";
        
        private readonly Material material;
        private readonly DitherSettings settings;
        
        public DitherPass(Material material, DitherSettings settings) {
            this.material = material;
            this.settings = settings;
        }

        private void UpdateMaterialSettings() {
            if (material == null) return;
            
            material.SetFloat(Spread, settings.spread);
            material.SetInt(RedColorCount, settings.redColorCount);
            material.SetInt(GreenColorCount, settings.greenColorCount);
            material.SetInt(BlueColorCount, settings.blueColorCount);
            material.SetInt(BayerLevel, settings.bayerLevel);
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData) {
            var resourceData = frameData.Get<UniversalResourceData>();
            var cameraData = frameData.Get<UniversalCameraData>();
            
            if (resourceData.isActiveTargetBackBuffer || cameraData.renderType == CameraRenderType.Overlay) return;
            
            var camDesc = cameraData.cameraTargetDescriptor;
            var descriptor = camDesc;
            descriptor.depthBufferBits = 0;
            descriptor.msaaSamples = 1;

            descriptor.width  = camDesc.width;
            descriptor.height = camDesc.height;
            for (var i = 0; i < settings.downSamples; i++) {
                descriptor.width  = Math.Max(1, descriptor.width  / 2);
                descriptor.height = Math.Max(1, descriptor.height / 2);
            }

            var srcCamColor = resourceData.activeColorTexture;
            var dst = UniversalRenderer.CreateRenderGraphTexture(renderGraph, descriptor, DitherTextureName, false);
            
            UpdateMaterialSettings();
            if (!srcCamColor.IsValid() || !dst.IsValid()) return;
            
            renderGraph.AddBlitPass(new RenderGraphUtils.BlitMaterialParameters(srcCamColor, dst, material, 0));
            
            resourceData.cameraColor = dst;
        }
    }
}