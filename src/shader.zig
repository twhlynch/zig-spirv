//! Vertex and Fragment shader using Zig's SPIR-V backend.

const std = @import("std");
const spirv = std.spirv;

/// 2D image for sampling in the fragment shader.
/// No builtin type yet, so we define it with @SpirvType.
const Image = @SpirvType(.{ .image = .{
    .usage = .{ .sampled = f32 },
    .format = .unknown,
    .dim = .@"2d",
    .depth = .not_depth,
    .arrayed = false,
    .multisampled = false,
    .access = .unknown,
} });
const SampledImage = @SpirvType(.{ .sampled_image = Image });

/// Input texture for the fragment shader.
/// set = 0, binding = 0
const texture = @extern(*addrspace(.constant) const SampledImage, .{
    .name = "texture",
    .decoration = .{ .descriptor = .{ .set = 0, .binding = 0 } },
});

// MARK: vertex stage

/// Input vertex position from the vertex buffer.
/// binding = 0, location = 0
const vertex_pos = @extern(*addrspace(.input) const @Vector(2, f32), .{
    .name = "vertex_pos",
    .decoration = .{ .location = 0 },
});
/// Input UV coordinates from the vertex buffer.
/// binding = 0, location = 1
const vertex_uv = @extern(*addrspace(.input) const @Vector(2, f32), .{
    .name = "vertex_uv",
    .decoration = .{ .location = 1 },
});
/// Output UV coordinates to the fragment shader.
/// binding = 0, location = 0
const vertex_uv_out = @extern(*addrspace(.output) @Vector(2, f32), .{
    .name = "uv",
    .decoration = .{ .location = 0 },
});

/// The vertex shader.
/// Simply passes on the vertex position and UV coords to the fragment shader.
export fn vs_main() callconv(.spirv_vertex) void {
    const position = vertex_pos.*;
    spirv.position_out.* = .{ position[0], position[1], 0.0, 1.0 };
    vertex_uv_out.* = vertex_uv.*;
}

// MARK: fragment stage

/// Input UV coordinates from the vertex shader.
/// binding = 0, location = 0
const fragment_uv = @extern(*addrspace(.input) const @Vector(2, f32), .{
    .name = "fragment_uv",
    .decoration = .{ .location = 0 },
});
/// Input color from the vertex shader.
/// binding = 0, location = 0
const fragment_color = @extern(*addrspace(.output) @Vector(4, f32), .{
    .name = "color",
    .decoration = .{ .location = 0 },
});

/// The fragment shader.
/// Samples the input texture and modulates it with a travelling ring pattern.
export fn fs_main() callconv(.{ .spirv_fragment = .{} }) void {
    // Get the UV coords then sample the texture at that point.

    // vec2 uv = fragment_uv
    const uv = fragment_uv.*;
    // vec4 texel = texture.sample(uv)
    const texel = spirv.imageSampleImplicitLod(texture, uv);

    // A travelling ring pattern by applying a sine wave to the distance from
    // the center of the texture.

    // vec2 centered = uv - vec2(0.5)
    const centered = uv - @as(@Vector(2, f32), @splat(0.5));
    // float radius = sqrt(centered.x * centered.x + centered.y * centered.y)
    const radius = @sqrt(centered[0] * centered[0] + centered[1] * centered[1]);
    // float wave = 0.5 + 0.5 * sin(radius * 28.0 - uv.x * 9.0 + uv.y * 5.0)
    const wave = 0.5 + 0.5 * @sin(radius * 28.0 - uv[0] * 9.0 + uv[1] * 5.0);

    // Modulate the sampled texel with the wave pattern and output the color.

    // fragColor = vec4(texel.r * wave, texel.g * (1.0 - wave), texel.b * (0.5 + 0.5 * wave), 1.0)
    fragment_color.* = .{
        texel[0] * wave,
        texel[1] * (1.0 - wave),
        texel[2] * (0.5 + 0.5 * wave),
        1.0,
    };
}
