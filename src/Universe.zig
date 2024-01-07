const std = @import("std");
const math = std.math;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const BufferedRenderer = @import("BufferRenderer.zig");
const RenderableCircle = @import("renderable.zig").RenderableCircle;
const Particle = @import("Particle.zig");
const Camera = @import("Camera.zig");

pub fn Universe(comptime num_types: u8) type {
    const ParticleTypes = Particle.ParticleTypes(num_types);
    return struct {
        const Self = @This();
        const Particles = ArrayList(Particle);

        width: u32,
        height: u32,
        seeded: bool,
        friction: f32 = 0,
        flat_force: bool = false,
        particles: Particles,
        particle_types: ParticleTypes,
        buffered_renderer: BufferedRenderer,

        pub fn init(alloc: Allocator, buffered_renderer: BufferedRenderer, width: u32, height: u32) Self {
            return .{
                .width = width,
                .height = height,
                .particles = Particles.init(alloc),
                .particle_types = undefined,
                .seeded = false,
                .buffered_renderer = buffered_renderer,
            };
        }

        pub fn addParticles(self: *Self, num_particles: usize) !void {
            var rand = std.rand.DefaultPrng.init((try std.time.Instant.now()).timestamp);
            for (0..num_particles) |_| {
                try self.particles.append(.{
                    .x = (rand.random().float(f32)) * @as(f32, @floatFromInt(self.width)),
                    .y = (rand.random().float(f32)) * @as(f32, @floatFromInt(self.height)),
                    .vx = rand.random().floatNorm(f32) * 0.1,
                    .vy = rand.random().floatNorm(f32) * 0.1,
                    .type_id = rand.random().uintLessThan(u8, num_types),
                });
            }
        }

        const radius: f32 = 5.0;
        const diameter: f32 = 2 * radius;

        pub fn seed(
            self: *Self,
            attract_mean: f32,
            attract_std: f32,
            minr_lower: f32,
            minr_upper: f32,
            maxr_lower: f32,
            maxr_upper: f32,
            friction: f32,
            flat_force: bool,
        ) !void {
            const particle_types = &self.particle_types;
            var rand = std.rand.DefaultPrng.init((try std.time.Instant.now()).timestamp);

            for (0..num_types) |i| {
                particle_types.color[i] = .{ @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(num_types)), 1.0, rand.random().float(f32) };
                for (0..num_types) |j| {
                    if (i == j) {
                        particle_types.get_attract_ptr(i, j).* = -@abs(rand.random().floatNorm(f32) * attract_std + attract_mean);
                        particle_types.get_minr_ptr(i, j).* = diameter;
                    } else {
                        particle_types.get_attract_ptr(i, j).* = rand.random().floatNorm(f32) * attract_std + attract_mean;
                        particle_types.get_minr_ptr(i, j).* = @max(diameter, rand.random().float(f32) * (minr_upper - minr_lower) + minr_lower);
                    }
                    particle_types.get_maxr_ptr(i, j).* = rand.random().float(f32) * (maxr_upper - maxr_lower) + maxr_lower;
                    particle_types.get_maxr_ptr(j, i).* = particle_types.get_maxr(i, j);
                    particle_types.get_minr_ptr(j, i).* = particle_types.get_minr(i, j);
                }
            }
            self.friction = friction;
            self.flat_force = flat_force;
            self.seeded = true;
        }

        pub fn step(self: *Self) !void {
            const width: f32 = @floatFromInt(self.width);
            const height: f32 = @floatFromInt(self.height);
            if (!self.seeded) return error.UnSeeded;

            for (self.particles.items, 0..) |*particle1, i| {
                for (self.particles.items, 0..) |particle2, j| {
                    if (i == j) continue;
                    Particle.interact(num_types, self.particle_types, self.flat_force, particle1, particle2, width, height);
                }
            }
            for (self.particles.items) |*particle| {
                particle.step(self.friction, width, height);
            }
        }

        pub fn render(self: *Self, camera: Camera) !void {
            for (self.particles.items) |particle| {
                try self.buffered_renderer.append(8, RenderableCircle(8).init_circle(
                    particle.x,
                    particle.y,
                    self.particle_types.color[particle.type_id],
                    5.0,
                ));
            }
            self.buffered_renderer.bind();
            self.buffered_renderer.render(camera, self.width, self.height);
            self.buffered_renderer.clear();
        }
    };
}
