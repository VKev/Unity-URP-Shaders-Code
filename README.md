# URP shader project
Using shader code, Non-shader graph

Unity 2023.2.0b1

## How to use
#### For all shader:
    -Download and copy the VkevShaderLib.hlsl file in your assets folder (Impotant)
    -The directory of the VkevShaderLib should be assets/VkevShaderLib.hlsl


#### For Outline post process: 
    
    -Add outline render feature to your universal render data
    
    -Add outline override to global volume
 
<img src="/ShowCase/OutlineSetting.png" alt="drawing" width="400"/>

#### For Grass shader:
    
    -Blend grass color with terrain feature need the texture map of terrain, you can create a render texture that render terrain color or simply use terrain texture map.

    -Blend grass color with terrain feature can be turned off by set the Blend intensity in material inspector to 0
    

#### For Tessellated water shader:

    -Reflection feature need a reflection cubemap - which you can bake using unity reflection probe.

#### For any shader with interact with player feature:

    -Set shader global property _PlayerWpos to player position in update().
    
    -Only work with 1 player.
    

## Show case
### Toon Shader:
    -Color, texture customizable.
    -All light support.
    -All shadow support.
    -Shadow quality customizable with URP asset.
   >**Youtube**: <a href="https://www.youtube.com/watch?v=TD1LF1E0NM8"> watch here </a>

<img src="/ShowCase/Toon.png" alt="drawing" width="400"/>


### Outline Shader:
    -Using scriptable renderer feature.
    -Outline color customizable.
    -Can toggle see through wall on/off.
    -Specify which layer is outline.
    -Depth, Normal outline customizable.
    -Support volume setting, camera postprocess.
   >**Youtube**: <a href="https://www.youtube.com/watch?v=gQ1xyFfLvwY"> watch here </a>

<img src="/ShowCase/Outline.png" alt="drawing" width="400"/>


### Stylized Grass Shader:
    -Blend grass color with terrain.
    -Interactive grass.
    -Wind Local/world direction, randomize wind or sync wind.
    -All light support.
    -Color, texture customizable.
   >**Optimization**: GPU instancing, Occlusion culling, Frustum culling, LOD.
   
   >**Youtube**: <a href="https://www.youtube.com/watch?v=IJnpnlxnKwk"> watch here </a>

<img src="/ShowCase/Grass1.png" alt="drawing" width="350"/> <img src="/ShowCase/Grass2.png" alt="drawing" width="350"/>

### Water Shader:
    -Water distortion.
    -Wave by noise.
    -Foam customizable.
    -Reflection with reflection probe.
   >**Youtube**: <a href="https://www.youtube.com/watch?v=BVga1hSMhaM1"> watch here </a>

<img src="/ShowCase/Water.png" alt="drawing" width="700"/>

<img src="/ShowCase/Water1.png" alt="drawing" width="700"/>
