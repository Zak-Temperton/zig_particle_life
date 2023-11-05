const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "sdl-zig-demo",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const glfw_dep = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });

    exe.addModule("mach-glfw", glfw_dep.module("mach-glfw"));
    @import("mach_glfw").link(glfw_dep.builder, exe);

    exe.addModule("gl", b.createModule(.{
        .source_file = .{ .path = "lib/gl4v6.zig" },
    }));

    exe.addModule("zmath", b.createModule(.{
        .source_file = .{ .path = "lib/zmath.zig" },
    }));
    b.installArtifact(exe);

    const run = b.step("run", "Run the demo");
    const run_cmd = b.addRunArtifact(exe);
    run.dependOn(&run_cmd.step);
}
