# OpenMW-EpochShaders
Vanilla+ core shader mod

Very WIP. 0.49 only

Features:
- Soft Shadows (Credits to Wareya, I didn't make them)
- Very basic indirect hemisphere lighting for ambient
- Energy conserving blinn-phong specular, only applied when there is no custom specular power detected in the texture. I probably did the math wrong
- Elongated specular highlight for water, re-ported (backported? Forwardported?) from the original Blender shader

<h2>Recommened Post Process Shaders</h2>
This is the setup I use, its fairly minimal, in the order its applied: 

- reshade-CAS
- reshade-colourfulness
- ssao_hq
- adjustments
- hdr
- reshade-magicBloom
