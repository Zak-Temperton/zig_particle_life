const Shader = @This();
const gl = @import("gl");
const std = @import("std");

id: u32,

pub fn init(vert: []const u8, frag: []const u8) Shader {
    var success: c_int = undefined;
    var infoLog: [512]u8 = [_]u8{0} ** 512;

    var vert_id = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vert_id);
    gl.shaderSource(vert_id, 1, @ptrCast(&vert), null);
    gl.compileShader(vert_id);
    gl.getShaderiv(vert_id, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(vert_id, 512, 0, &infoLog);
        std.log.err("{s}", .{infoLog});
    }

    var frag_id = gl.createShader(gl.FRAGMENT_SHADER);
    defer gl.deleteShader(frag_id);
    gl.shaderSource(frag_id, 1, @ptrCast(&frag), null);
    gl.compileShader(frag_id);
    gl.getShaderiv(frag_id, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(frag_id, 512, 0, &infoLog);
        std.log.err("{s}", .{infoLog});
    }

    var id = gl.createProgram();
    gl.attachShader(id, vert_id);
    gl.attachShader(id, frag_id);
    gl.linkProgram(id);
    gl.getProgramiv(id, gl.LINK_STATUS, &success);
    if (success == 0) {
        gl.getProgramInfoLog(id, 512, 0, &infoLog);
        std.log.err("{s}", .{infoLog});
    }
    return .{ .id = id };
}

pub fn use(self: Shader) void {
    gl.useProgram(self.id);
}

pub fn deinit(self: Shader) void {
    gl.deleteProgram(self.id);
}

pub fn setBool(self: Shader, name: [*c]const u8, value: bool) void {
    gl.uniform1i(gl.getUniformLocation(self.id, name), @as(c_int, @intFromBool(value)));
}

pub fn setInt(self: Shader, name: [*c]const u8, value: u32) void {
    gl.uniform1i(gl.getUniformLocation(self.id, name), @intCast(value));
}

pub fn setFloat(self: Shader, name: [*c]const u8, value: f32) void {
    gl.uniform1f(gl.getUniformLocation(self.id, name), value);
}

pub fn setVec2f(self: Shader, name: [*c]const u8, value: [2]f32) void {
    gl.uniform2fv(gl.getUniformLocation(self.id, name), 1, &value[0]);
}

pub fn setVec3f(self: Shader, name: [*c]const u8, value: [3]f32) void {
    gl.uniform3f(gl.getUniformLocation(self.id, name), value[0], value[1], value[2]);
}

pub fn setMat4f(self: Shader, name: [*c]const u8, value: [16]f32) void {
    const matLoc = gl.getUniformLocation(self.id, name);
    if (matLoc == -1)
        std.debug.print("invalid operation", .{});
    gl.uniformMatrix4fv(matLoc, 1, gl.FALSE, &value);
}
