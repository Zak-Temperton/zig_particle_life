const zm = @import("zmath");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const Camera = @This();

const WORLD_UP = zm.loadArr3(.{ 0.0, 1.0, 0.0 });

focus_position: @Vector(2, f32),
zoom: f32,

pub fn init(position: @Vector(2, f32), zoom: f32) Camera {
    return Camera{
        .focus_position = position,
        .zoom = zoom,
    };
}

pub fn getProjectionMatrix(self: Camera, width: u32, height: u32) zm.Mat {
    const w: f32 = @floatFromInt(width);
    const h: f32 = @floatFromInt(height);

    const l = self.focus_position[0] - (w / 2.0);
    const r = self.focus_position[0] + (w / 2.0);
    const t = self.focus_position[1] + (h / 2.0);
    const b = self.focus_position[1] - (h / 2.0);
    const n: f32 = 0.1;
    const f: f32 = 100.0;

    const ortho = zm.orthographicOffCenterRh(l, r, t, b, n, f);
    return zm.mul(ortho, zm.scaling(self.zoom, self.zoom, 1));
    //return .{ self.zoom * 2 / (r - l), self.zoom * 2 / (t - b) };
}
