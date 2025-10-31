const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});

    const Target = std.Target.x86;
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86,
        .os_tag = .freestanding,
        .abi = .none,
        // We use software float because we are disabling all SIMD stuff
        .cpu_features_add = Target.featureSet(&.{.soft_float}),
        // Disable all SIMD related stuff because SIMD are problematic in kernel
        .cpu_features_sub = Target.featureSet(&.{ .avx, .avx2, .sse, .sse2, .mmx }),
    });

    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kernel.zig"),
            .target = target,
            .optimize = optimize,
            .code_model = .kernel,
        }),
    });
    kernel.setLinkerScript(b.path("linker.ld"));
    b.installArtifact(kernel);

    const make_dirs = b.addSystemCommand(&[_][]const u8{
        "mkdir", "-p", "iso/boot/grub",
    });
    
    const copy_kernel = b.addSystemCommand(&[_][]const u8{
        "cp", "zig-out/bin/kernel.elf", "iso/boot/kernel.elf",
    });
    copy_kernel.step.dependOn(&make_dirs.step);
    
    const copy_grub_cfg = b.addSystemCommand(&[_][]const u8{
        "cp", "grub.cfg", "iso/boot/grub/grub.cfg",
    });
    copy_grub_cfg.step.dependOn(&copy_kernel.step);
    
    const make_iso = b.addSystemCommand(&[_][]const u8{
        "grub-mkrescue", "-o", "kernel.iso", "iso",
    });
    make_iso.step.dependOn(&copy_grub_cfg.step);
    make_iso.step.dependOn(&kernel.step);
    
    b.step("iso", "Build bootable ISO").dependOn(&make_iso.step);
    
}
