const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe_target_name = "day11";

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_aoc = b.dependency("aoc", .{}).module("aoc");

    const exe = b.addExecutable(.{
        .name = exe_target_name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("aoc", mod_aoc);

    b.installArtifact(exe);

    const exe_check = b.addExecutable(.{
        .name = exe_target_name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_check.root_module.addImport("aoc", mod_aoc);

    const check = b.step("check", "Check compilation");
    check.dependOn(&exe_check.step);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
