const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const zm = @import("zmath");

const Shader = @import("Shader.zig");
const Camera = @import("Camera.zig");

fn glGetProcAddress(_: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    return glfw.getProcAddress(proc);
}
/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(640 * 2, 480 * 2, "mach-glfw + zig-opengl", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 6,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);
    glfw.Window.setFramebufferSizeCallback(window, framebufferSizeCallback);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    const num_sides: u32 = 16;
    const circle_vertex_array = genCircleVertexArray(num_sides, 0.1);
    const circle_index_array = genCircleIndexBuffer(num_sides);

    const shader = Shader.init(vertex_shader_t, fragment_shader_t);
    defer shader.deinit();

    var VAO: u32 = undefined;
    var VBO: u32 = undefined;
    var EBO: u32 = undefined;

    gl.genVertexArrays(1, &VAO);
    defer gl.deleteVertexArrays(1, &VAO);
    gl.genBuffers(1, &VBO);
    defer gl.deleteBuffers(1, &VBO);
    gl.genBuffers(1, &EBO);
    defer gl.deleteBuffers(1, &EBO);

    gl.bindVertexArray(VAO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(f32) * circle_vertex_array.len, &circle_vertex_array[0], gl.STATIC_DRAW);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(u32) * circle_index_array.len, &circle_index_array[0], gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    while (!window.shouldClose()) {
        gl.clearColor(0, 0, 0, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        shader.use();
        gl.bindVertexArray(VAO);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
        gl.drawElements(gl.TRIANGLES, circle_index_array.len, gl.UNSIGNED_INT, null);
        gl.bindVertexArray(0);
        window.swapBuffers();
        glfw.pollEvents();
    }
}

fn genCircleVertexArray(comptime num_sides: u32, comptime radius: f32) [num_sides * 3]f32 {
    var vertices: [num_sides * 3]f32 = undefined;
    var theta: f32 = std.math.tau / @as(f32, @floatFromInt(num_sides));
    for (0..num_sides) |n| {
        var angle: f32 = theta * @as(f32, @floatFromInt(n));
        vertices[n * 3] = radius * @cos(angle);
        vertices[n * 3 + 1] = radius * @sin(angle);
        vertices[n * 3 + 2] = 1.0;
    }
    return vertices;
}

fn genCircleIndexBuffer(comptime num_sides: u32) [num_sides * 3]u32 {
    var indices: [num_sides * 3]u32 = undefined;
    for (0..num_sides) |n| {
        indices[n * 3] = 0;
        indices[n * 3 + 1] = @truncate(n + 1);
        indices[n * 3 + 2] = @truncate(n + 2);
    }
    return indices;
}

const vertex_shader_t =
    \\#version 460 core
    \\void main() {
    \\  gl_Position = vec4(0.5,0.5,1.0,1.0);
    \\}
;
const fragment_shader_t =
    \\#version 460 core
    \\out vec4 FragColor;
    \\void main() {
    \\  FragColor = vec4(1.0,1.0,1.0,1.0);
    \\}
;

fn framebufferSizeCallback(window: glfw.Window, width: u32, height: u32) void {
    _ = window;
    gl.viewport(0, 0, @intCast(width), @intCast(height));
}
