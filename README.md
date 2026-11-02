# zig-spirv demo

A demo using Zig's new SPIR-V backend to compile to a SPIR-V binary and run it
on the GPU using Vulkan. Currently only builds the shader, I didn't include
something to run it on the GPU.

Conceptually I think this is pretty awesome. The configuration of the shader is
complex (such is Vulkan) but managable and comes with a great level of control
that I find much more intuitive than setup of a HLSL equivelant, however the
verbosity of Zig makes the syntax for the actual shader code much less
enjoyable, especially vector construction, and lack of swizzling.

```zig
const uv = fragment_uv.*;
const texel = spirv.imageSampleImplicitLod(texture, uv);

const centered = uv - @as(@Vector(2, f32), @splat(0.5)); // dont like this
const radius = @sqrt(centered[0] * centered[0] + centered[1] * centered[1]);
const wave = 0.5 + 0.5 * @sin(radius * 28.0 - uv[0] * 9.0 + uv[1] * 5.0);

fragment_color.* = .{ // but i love this
    texel[0] * wave,
    texel[1] * (1.0 - wave),
    texel[2] * (0.5 + 0.5 * wave),
    1.0,
};
```

```hlsl
vec2 uv = fragment_uv
vec4 texel = texture.sample(uv)

vec2 centered = uv - vec2(0.5)
float radius = sqrt(centered.x * centered.x + centered.y * centered.y)
float wave = 0.5 + 0.5 * sin(radius * 28.0 - uv.x * 9.0 + uv.y * 5.0)

fragColor = vec4(texel.r * wave, texel.g * (1.0 - wave), texel.b * (0.5 + 0.5 * wave), 1.0)
```
