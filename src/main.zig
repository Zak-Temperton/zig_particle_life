const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const zm = @import("zmath");

const Universe = @import("Universe.zig").Universe;
const Shader = @import("Shader.zig");
const Camera = @import("Camera.zig");
const BufferedRenderer = @import("BufferRenderer.zig");

var width: u32 = 0;
var height: u32 = 0;

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
    const window = glfw.Window.create(1600, 900, "mach-glfw + zig-opengl", null, null, .{
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
    width = window.getSize().width;
    height = window.getSize().height;

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    const shader = Shader.init(vertex_shader_t, fragment_shader_t);
    defer shader.deinit();

    const alloc = std.heap.page_allocator;

    const camera = Camera.init(.{ @floatFromInt(width / 2), @floatFromInt(height / 2) }, 1.0);
    var b_renderer = BufferedRenderer.init(alloc, shader);
    defer b_renderer.deinit();

    var universe = Universe(6).init(alloc, b_renderer);
    try universe.seed(-0.02, 0.06, 0.0, 20.0, 20.0, 70.0, 0.05, false);
    //try universe.seed(0.02, 0.05, 0.0, 20.0, 20.0, 50.0, 0.05, false);
    try universe.addParticles(500, width, height);

    while (!window.shouldClose()) {
        try processInput(window, &universe);
        gl.clearColor(0, 0, 0, 0.2);
        gl.clear(gl.COLOR_BUFFER_BIT);

        try universe.render(camera, width, height);
        for (0..20) |_|
            try universe.step(@floatFromInt(width), @floatFromInt(height));

        window.swapBuffers();
        glfw.pollEvents();
    }
}

const vertex_shader_t =
    \\#version 410 core
    \\layout (location = 0) in vec2 aPos;
    \\layout (location = 1) in vec3 aColor;
    \\uniform mat4 proj;
    \\out vec3 ourColor;
    \\void main()
    \\{
    \\  gl_Position = proj * vec4(aPos.x, aPos.y, 1.0, 1.0);
    \\  ourColor = aColor;
    \\}
;

const fragment_shader_t =
    \\#version 460 core
    \\in vec3 ourColor;
    \\out vec4 FragColor;
    \\void main() {
    \\  FragColor = vec4(ourColor, 1.0);
    \\}
;

fn framebufferSizeCallback(window: glfw.Window, w: u32, h: u32) void {
    _ = window;
    width = w;
    height = h;
    gl.viewport(0, 0, @intCast(width), @intCast(height));
}
var space = false;
var space_last = false;
fn processInput(window: glfw.Window, universe: anytype) !void {
    if (glfw.Window.getKey(window, glfw.Key.space) == glfw.Action.press) {
        space_last = space;
        space = true;
    } else if (glfw.Window.getKey(window, glfw.Key.space) == glfw.Action.release) {
        space = false;
    }
    if (space and !space_last) {
        try universe.seed(-0.02, 0.04, 10.0, 15.0, 25.0, 80.0, 0.05, false);
        //try universe.seed(-0.02, 0.03, 0.0, 10.0, 20.0, 40.0, 0.2, false);
    }
}
