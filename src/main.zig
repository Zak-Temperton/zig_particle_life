const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const std = @import("std");
const gl = @import("gl");

const width: usize = 900;
const height: usize = 900;

fn glGetProcAddress(comptime _: type, proc: [:0]const u8) ?gl.FunctionPointer {
    return c.SDL_GL_GetProcAddress(proc);
}

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow(
        "My Game Window",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        @as(c_int, width),
        @as(c_int, height),
        c.SDL_WINDOW_OPENGL,
    ) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(screen);

    const context = c.SDL_GL_CreateContext(screen);
    defer c.SDL_GL_DeleteContext(context);

    try gl.load(void, glGetProcAddress);

    const num_sides: u32 = 16;
    const circle_vertex_array = genCircleVertexArray(num_sides, 0.1);
    const circle_index_array = genCircleIndexBuffer(num_sides);

    const vertex_shader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(vertex_shader, 1, &vertex_shader_t, null);
    gl.compileShader(vertex_shader);
    defer gl.deleteShader(vertex_shader);

    const fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragment_shader, 1, &fragment_shader_t, null);
    gl.compileShader(fragment_shader);
    defer gl.deleteShader(fragment_shader);

    const shader_program = gl.createProgram();
    gl.attachShader(shader_program, vertex_shader);
    gl.attachShader(shader_program, fragment_shader);
    gl.linkProgram(shader_program);
    defer gl.deleteProgram(shader_program);

    var vertex_arrays: u32 = undefined;
    var vertex_buffers: u32 = undefined;
    var element_buffers: u32 = undefined;

    gl.genVertexArrays(1, &vertex_arrays);
    defer gl.deleteVertexArrays(1, &vertex_arrays);
    gl.genBuffers(1, &vertex_buffers);
    defer gl.deleteBuffers(1, &vertex_buffers);

    gl.genBuffers(1, &element_buffers);
    defer gl.deleteBuffers(1, &element_buffers);

    gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffers);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(Vertex) * circle_vertex_array.len, &circle_vertex_array[0], gl.STATIC_DRAW);
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, @sizeOf(Vertex), null);
    gl.enableVertexAttribArray(0);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, element_buffers);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(u32) * circle_index_array.len, &circle_index_array[0], gl.STATIC_DRAW);

    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }
        gl.clearColor(0, 0, 0, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);
        gl.useProgram(shader_program);

        //gl.bindVertexArray(vertex_arrays);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, element_buffers);
        gl.drawElements(gl.TRIANGLES, circle_index_array.len, gl.UNSIGNED_INT, null);
        gl.bindVertexArray(0);
        c.SDL_GL_SwapWindow(screen);
    }
}

const Vertex = struct { x: f32, y: f32, z: f32 };

fn genCircleVertexArray(comptime num_sides: u32, comptime radius: f32) [num_sides]Vertex {
    var vertices: [num_sides]Vertex = undefined;
    var theta: f32 = std.math.tau / @as(f32, @floatFromInt(num_sides));
    for (0..num_sides) |n| {
        var angle: f32 = theta * @as(f32, @floatFromInt(n));
        vertices[n] = .{
            .x = radius * @cos(angle),
            .y = radius * @sin(angle),
            .z = 1.0,
        };
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

const vertex_shader_t: [*c]const u8 =
    \\#version 330 core
    \\out vec4 outCol;
    \\void main() {
    \\  gl_Position = vec4(0.5,0.5,1.0,1.0);
    \\  outCol = vec4(1.0,1.0,1.0, 1.0);
    \\}
;
const fragment_shader_t: [*c]const u8 =
    \\#version 330 core
    \\out vec4 gl_FragColor
    \\in vec4 outCol
    \\void main() {
    \\  gl_FragColor = vec4(outCol,1.0);
    \\}
;
