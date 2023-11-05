const zm = @import("zmath");
const Camera = @This();

const WORLD_UP = zm.loadArr3(.{ 0.0, 1.0, 0.0 });

position: zm.F32x4 = zm.loadArr3(.{ 0.0, 0.0, 0.0 }),
front: zm.F32x4 = zm.loadArr3(.{ 0.0, 0.0, -1.0 }),
up: zm.F32x4 = undefined,
right: zm.F32x4 = undefined,

yaw: f32 = -90,
pitch: f32 = 0.0,

zoom: f32 = 45.0,

pub fn camera(position: ?zm.F32x4) Camera {
    const _position = p: {
        if (position) |value| {
            break :p value;
        } else {
            break :p zm.loadArr3(.{ 0.0, 0.0, 0.0 });
        }
    };

    const _front = zm.loadArr3(.{ 0.0, 0.0, -1.0 });
    const _world_up = zm.loadArr3(.{ 0.0, 1.0, 0.0 });
    const _right = zm.normalize3(zm.cross3(_front, _world_up));
    const _up = zm.normalize3(zm.cross3(_right, _front));

    return Camera{
        .position = _position,
        .right = _right,
        .up = _up,
    };
}

pub fn getViewMatrix(self: *Camera) zm.Mat {
    return zm.lookAtRh(self.position, self.position + self.front, self.up);
}
