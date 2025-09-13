using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Rendering {
    public class PaletteSwapperPassFeature : ScriptableRendererFeature {
        [SerializeField] private PaletteSwapperSettings settings;
        [SerializeField] private Shader shader;

        private Material material;
        private PaletteSwapperPass pass;
        
        public override void Create() {
            if (shader == null) return;
            
            material = new Material(shader);
            pass = new PaletteSwapperPass(material, settings) {
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

    [System.Serializable]
    public class PaletteSwapperSettings {
        public Texture2D colorPalette;
        public bool invert;
        public bool isColorRamp = true;
    }
}