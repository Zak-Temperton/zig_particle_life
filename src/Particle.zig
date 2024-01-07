const std = @import("std");
const main = @import("main.zig");

const Particle = @This();
x: f32,
y: f32,
vx: f32,
vy: f32,
type_id: u8,

const r_smooth: f32 = 2.0;

pub fn ParticleTypes(comptime n: u8) type {
    return struct {
        const Self = @This();
        color: [n][3]f32,
        attract: [n * n]f32,
        minr: [n * n]f32,
        maxr: [n * n]f32,

        pub fn len() u8 {
            return n;
        }

        pub fn get_color(self: Self, i: usize) [3]f32 {
            return self.color[i];
        }

        pub fn get_attract(self: Self, i: usize, j: usize) f32 {
            return self.attract[i * n + j];
        }

        pub fn get_attract_ptr(self: *Self, i: usize, j: usize) *f32 {
            return &self.attract[i * n + j];
        }

        pub fn get_minr(self: Self, i: usize, j: usize) f32 {
            return self.minr[i * n + j];
        }

        pub fn get_minr_ptr(self: *Self, i: usize, j: usize) *f32 {
            return &self.minr[i * n + j];
        }

        pub fn get_maxr(self: Self, i: usize, j: usize) f32 {
            return self.maxr[i * n + j];
        }

        pub fn get_maxr_ptr(self: *Self, i: usize, j: usize) *f32 {
            return &self.maxr[i * n + j];
        }
    };
}

inline fn applyFriction(self: *Particle, friction: f32) void {
    self.vx *= 1.0 - friction;
    self.vy *= 1.0 - friction;
}

pub fn interact(
    comptime num_particles: u8,
    particle_types: ParticleTypes(num_particles),
    flat_force: bool,
    particle1: *Particle,
    particle2: Particle,
    width: f32,
    height: f32,
) void {
    var dx = particle2.x - particle1.x;
    var dy = particle2.y - particle1.y;
    if (dx > width * 0.5) {
        dx -= width;
    } else if (dx < -width * 0.5) {
        dx += width;
    }
    if (dy > height * 0.5) {
        dy -= height;
    } else if (dy < -height * 0.5) {
        dy += height;
    }
    const p1 = particle1.type_id;
    const p2 = particle2.type_id;
    const r2 = dx * dx + dy * dy;
    const maxr = particle_types.get_maxr(p1, p2);
    if (r2 < maxr * maxr and r2 > 0.01) {
        const r = std.math.sqrt(r2);
        dx /= r;
        dy /= r;
        const minr = particle_types.get_minr(p1, p2);
        const f = if (r > minr) blk: {
            if (flat_force) {
                break :blk particle_types.get_attract(p1, p2);
            } else {
                const numer = 2.0 * @abs(r - 0.5 * (maxr + minr));
                const denom = maxr - minr;
                break :blk particle_types.get_attract(p1, p2) * (1.0 - (numer / denom));
            }
        } else blk: {
            break :blk r_smooth * minr * (1.0 / (minr + r_smooth) - 1.0 / (r + r_smooth));
        };
        particle1.vx += f * dx;
        particle1.vy += f * dy;
    }
}

pub fn step(self: *Particle, friction: f32, width: f32, height: f32) void {
    self.x += self.vx;
    self.y += self.vy;
    self.applyFriction(friction);
    while (self.x < 0.0) {
        self.x += width;
    } else while (self.x >= width) {
        self.x -= width;
    }
    while (self.y < 0.0) {
        self.y += height;
    } else while (self.y >= height) {
        self.y -= height;
    }
}
