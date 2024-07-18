// !! do not change
pub const platform = @import("build_options").platform;
pub const XfitPlatform = @import("build_options").@"zig-game-engine-project.engine.XfitPlatform";
// !!
// !! windows platform only do not change
pub const UNICODE = false;
// !!
// !! android platform only do not change
comptime {
    if (platform == XfitPlatform.android)
        _ = @import("zig-game-engine-project/__android.zig").android.ANativeActivity_createFunc;
}
// !!

const std = @import("std");
const xfit = @import("zig-game-engine-project/xfit.zig");
const system = @import("zig-game-engine-project/system.zig");

const ArrayList = std.ArrayList;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const matrix = @import("zig-game-engine-project/matrix_.zig").matrix;
const matrix4x4 = @import("zig-game-engine-project/matrix_.zig").matrix4x4;
const matrix_error = @import("zig-game-engine-project/matrix_.zig").matrix_error;
const file = @import("zig-game-engine-project/file.zig");
const geometry = @import("zig-game-engine-project/geometry.zig");

pub fn xfit_init() void {
    const mat: matrix4x4(f32) = .{ .e = .{
        .{ 1, 2, 3, 4 },
        .{ 5, 7, 7, 8 },
        .{ 9, 10, 57, 12 },
        .{ 13, 14, 15, 16 },
    } };

    const m5 = mat.inverse() catch unreachable;

    system.print("{s}", .{m5});
    return;
}

pub fn xfit_update() void {}

pub fn xfit_destroy() void {}

pub fn xfit_activate() void {}

pub fn xfit_closing() bool {
    return true;
}

pub fn main() void {
    const init_setting: system.init_setting = .{ .window_width = 600, .window_height = 400, .maxframe = 1000000000 * 240 };
    xfit.xfit_main(&init_setting);
}
