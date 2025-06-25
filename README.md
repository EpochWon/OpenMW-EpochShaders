# OpenMW-EpochShaders
Vanilla+ core shader mod

Very WIP. 0.49 only

![screenshot294](https://github.com/user-attachments/assets/0ae97918-4777-4c87-835d-3d7b07ce05ca)
![screenshot290](https://github.com/user-attachments/assets/8002321a-25e2-4cc6-9a7d-e8932105c5fa)
![screenshot295](https://github.com/user-attachments/assets/5b347f1f-caf9-478d-9de1-81161e59cc68)


<h2>Features:</h2>

- Soft Shadows (Credits to Wareya, I didn't make them)
- Very basic indirect hemisphere lighting for ambient
- Energy conserving blinn-phong specular, only applied when there is no custom specular power detected in the texture, requires specular maps still. I probably did the math wrong
- Elongated specular highlight for water, re-ported (backported? Forwardported?) from the original Blender shader
- Water sunlight scattering is now masked by shadows

These shaders focus more on aesthetic rather than realism, especially the water shader changes which might not be to everyone's taste, if you don't like the water you can skip copying the file, or if you want the water without anything else its standalone.

Performance wise the shadows are the heaviest, and can kill your frames in certain situations (like a lot of transparency), you can tweak a few settings at the top of the ``shadows_fragment.glsl`` file. I've tweaked them to appear softer but because of how OpenMW's shadows work the blur size will change based on your view angle. 

<h2>Recommened Post Process Shaders</h2>
This is the setup I use, its fairly minimal, in the order its applied: 

- reshade-CAS
- reshade-colourfulness
- ssao_hq
- adjustments
- hdr
- reshade-magicBloom
