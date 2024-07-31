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

const math = @import("zig-game-engine-project/math.zig");
const matrix = math.matrix;
const matrix4x4 = math.matrix4x4;
const matrix_error = math.matrix_error;
const file = @import("zig-game-engine-project/file.zig");

const graphics = @import("zig-game-engine-project/graphics.zig");

pub var v: graphics.vertices(graphics.color_vertex_2d) = .{};
pub var objects: ArrayList(*graphics.ivertices) = ArrayList(*graphics.ivertices).init(allocator);

pub fn xfit_init() void {
    v = graphics.vertices(graphics.color_vertex_2d).init(allocator);
    v.array.append(.{
        .pos = .{ 0, -0.5 },
        .color = .{ 1, 0, 0, 1 },
    }) catch unreachable;
    v.array.append(.{
        .pos = .{ 0.5, 0.5 },
        .color = .{ 0, 1, 0, 1 },
    }) catch unreachable;
    v.array.append(.{
        .pos = .{ -0.5, 0.5 },
        .color = .{ 0, 0, 1, 1 },
    }) catch unreachable;
    v.build() catch unreachable;

    objects.append(&v.interface) catch unreachable;
    graphics.scene = &objects.items;
}

pub fn xfit_update() void {}

pub fn xfit_destroy() void {
    v.destroy();
    objects.deinit();
}

pub fn xfit_activate() void {}

pub fn xfit_closing() bool {
    return true;
}

pub fn main() void {
    const init_setting: system.init_setting = .{ .window_width = 600, .window_height = 400, .maxframe = system.sec_to_nano_sec(240, 0) };
    xfit.xfit_main(&init_setting);
}
