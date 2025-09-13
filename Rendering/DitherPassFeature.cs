using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Rendering {
    public class DitherPassFeature : ScriptableRendererFeature {
        [SerializeField] private DitherSettings settings;
        [SerializeField] private Shader shader;

        private Material material;
        private DitherPass pass;
        
        public override void Create() {
            if (shader == null) return;
            
            material = new Material(shader);
            pass = new DitherPass(material, settings) {
                renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing
            };
        }
        
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
            if (pass == null) return;
            
            if (renderingData.cameraData.cameraType == CameraType.Game) {
                renderer.EnqueuePass(pass);
            }
        }

        protected override void Dispose(bool disposing) {
            if (Application.isPlaying) Destroy(material);
            else DestroyImmediate(material, true);
        }
    }
    
    [Serializable]
    public class DitherSettings {
        [Range(0.0f, 1.0f)]
        public float spread = 0.5f;

        [Range(2, 64)]
        public int redColorCount = 2;
        [Range(2, 64)]
        public int greenColorCount = 2;
        [Range(2, 64)]
        public int blueColorCount = 2;

        [Range(0, 3)]
        public int bayerLevel = 0;

        [Range(0, 8)]
        public int downSamples = 0;
    }
}