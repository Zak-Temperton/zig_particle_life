const BufferedRenderer = @This();
const gl = @import("gl");
const zm = @import("zmath");
const std = @import("std");
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const Camera = @import("Camera.zig");
const Program = @import("Shader.zig");
const RenderableCircle = @import("renderable.zig").RenderableCircle;

allocator: Allocator,
shader_program: Program,
vertices: ArrayList(f32),
indices: ArrayList(u32),
vao: u32,
vbo: u32,
ebo: u32,
count: u32 = 0,

pub fn init(allocator: Allocator, shader_program: Program) BufferedRenderer {
    var vao: u32 = 0;
    var vbo: u32 = 0;
    var ebo: u32 = 0;
    gl.genVertexArrays(1, &vao);
    gl.genBuffers(1, &vbo);
    gl.genBuffers(1, &ebo);

    return .{
        .allocator = allocator,
        .shader_program = shader_program,
        .vertices = ArrayList(f32){},
        .indices = ArrayList(u32){},
        .vao = vao,
        .vbo = vbo,
        .ebo = ebo,
    };
}

pub fn deinit(self: *BufferedRenderer) void {
    self.vertices.deinit(self.allocator);
    self.indices.deinit(self.allocator);
    defer gl.deleteVertexArrays(1, &self.vao);
    defer gl.deleteBuffers(1, &self.vbo);
    defer gl.deleteBuffers(1, &self.ebo);
}

pub fn append(self: *BufferedRenderer, comptime num_vertices: u32, renderable: RenderableCircle(num_vertices)) !void {
    var vertices =
        renderable.mesh.vertices;

    for (0..vertices.len / 5) |i| {
        const vertexX = vertices[i * 5] * renderable.scale + renderable.x;
        const vertexY = vertices[i * 5 + 1] * renderable.scale + renderable.y;
        try self.vertices.append(self.allocator, vertexX);
        try self.vertices.append(self.allocator, vertexY);
        try self.vertices.appendSlice(self.allocator, vertices[i * 5 + 2 .. i * 5 + 5]);
    }
    for (renderable.mesh.indices) |index| {
        try self.indices.append(self.allocator, index + self.count);
    }
    self.count += num_vertices;
}

pub fn bind(self: BufferedRenderer) void {
    gl.bindVertexArray(self.vao);
    gl.bindBuffer(gl.ARRAY_BUFFER, self.vbo);
    gl.bufferData(gl.ARRAY_BUFFER, @intCast(@sizeOf(f32) * self.vertices.items.len), &self.vertices.items[0], gl.STATIC_DRAW);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ebo);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(@sizeOf(u32) * self.indices.items.len), &self.indices.items[0], gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, @intCast(5 * @sizeOf(f32)), null);
    gl.enableVertexAttribArray(0);
    const col_offset: [*c]c_uint = (2 * @sizeOf(f32));
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, @intCast(5 * @sizeOf(f32)), col_offset);
    gl.enableVertexAttribArray(1);
}

pub fn render(self: BufferedRenderer, camera: Camera, width: u32, height: u32) void {
    var projection: [16]f32 = undefined;
    zm.storeMat(&projection, camera.getProjectionMatrix(width, height));
    self.shader_program.use();
    self.shader_program.setMat4f("proj", projection);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ebo);
    gl.bindVertexArray(self.vao);
    gl.drawElements(gl.TRIANGLES, @intCast(self.indices.items.len), gl.UNSIGNED_INT, null);
    gl.bindVertexArray(0);
}

pub fn clear(self: *BufferedRenderer) void {
    self.vertices.clearAndFree(self.allocator);
    self.indices.clearAndFree(self.allocator);
    self.count = 0;
}
