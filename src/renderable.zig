const std = @import("std");

pub fn RenderableCircle(comptime num_vertices: u32) type {
    const Mesh = struct {
        vertices: [num_vertices * 5]f32,
        indices: [(num_vertices - 2) * 3]u32,

        pub fn circle(color: [3]f32) @This() {
            return .{
                .vertices = genCircleVertexArray(color),
                .indices = genCircleIndexBuffer(),
            };
        }

        fn genCircleVertexArray(color: [3]f32) [num_vertices * 5]f32 {
            var vertices: [num_vertices * 5]f32 = undefined;
            var theta: f32 = std.math.tau / @as(f32, @floatFromInt(num_vertices));
            for (0..num_vertices) |n| {
                var angle: f32 = theta * @as(f32, @floatFromInt(n));
                vertices[n * 5] = @cos(angle);
                vertices[n * 5 + 1] = @sin(angle);
                vertices[n * 5 + 2] = color[0];
                vertices[n * 5 + 3] = color[1];
                vertices[n * 5 + 4] = color[2];
            }
            return vertices;
        }

        fn genCircleIndexBuffer() [(num_vertices - 2) * 3]u32 {
            var indices: [(num_vertices - 2) * 3]u32 = undefined;
            for (0..num_vertices - 2) |n| {
                indices[n * 3] = 0;
                indices[n * 3 + 1] = @truncate(n + 1);
                indices[n * 3 + 2] = @truncate(n + 2);
            }
            return indices;
        }
    };

    return struct {
        mesh: Mesh,
        x: f32,
        y: f32,
        scale: f32,

        pub fn init_circle(x: f32, y: f32, color: [3]f32, scale: f32) @This() {
            return .{
                .mesh = Mesh.circle(color),
                .x = x,
                .y = y,
                .scale = scale,
            };
        }
    };
}
