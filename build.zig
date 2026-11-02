const std = @import("std");

pub fn build(b: *std.Build) void {
    // SPIR-V target for Vulkan
    const shader_target = b.resolveTargetQuery(.{
        .cpu_arch = .spirv32,
        .os_tag = .vulkan,
    });

    // Build shader.zig to shader.spv
    const shader = b.addObject(.{
        .name = "shader",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/shader.zig"),
            .target = shader_target,
            .optimize = .ReleaseFast,
        }),
        .use_llvm = false,
    });

    // Install to zig-out/bin/shader.spv
    const install_shader = b.addInstallFileWithDir(shader.getEmittedBin(), .bin, "shader.spv");
    b.getInstallStep().dependOn(&install_shader.step);

    // Build step for shader compilation
    const shader_step = b.step("shader", "Compile src/shader.zig to zig-out/bin/shader.spv");
    shader_step.dependOn(&install_shader.step);
}
