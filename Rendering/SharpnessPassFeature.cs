using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Rendering {
    public class SharpnessPassFeature : ScriptableRendererFeature {
        [SerializeField] private SharpnessSettings settings;
        [SerializeField] private Shader shader;

        private Material material;
        private SharpnessPass pass;
        
        public override void Create() {
            if (shader == null) return;
            
            material = new Material(shader);
            pass = new SharpnessPass(material, settings) {
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
    public class SharpnessSettings {
        [Range(-10.0f, 10.0f)] public float amount = 0.0f;
    }
}