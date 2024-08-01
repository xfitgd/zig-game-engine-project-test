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
const MemoryPool = std.heap.MemoryPool;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const math = @import("zig-game-engine-project/math.zig");
const mem = @import("zig-game-engine-project/mem.zig");
const matrix = math.matrix;
const matrix4x4 = math.matrix4x4;
const matrix_error = math.matrix_error;
const file = @import("zig-game-engine-project/file.zig");

const graphics = @import("zig-game-engine-project/graphics.zig");

pub var v: *graphics.vertices(graphics.color_vertex_2d) = undefined;
pub var i: *graphics.indices16 = undefined;
pub var o: *graphics.shape2d = undefined;
pub var objects: ArrayList(*graphics.iobject) = ArrayList(*graphics.iobject).init(allocator);
pub var mem_pool: MemoryPool(graphics.dummy_vertices) = MemoryPool(graphics.dummy_vertices).init(allocator);
pub var mem_pool2: MemoryPool(graphics.dummy_object) = MemoryPool(graphics.dummy_object).init(allocator);
pub var mem_pool3: MemoryPool(graphics.dummy_indices) = MemoryPool(graphics.dummy_indices).init(allocator);

pub fn xfit_init() void {
    v = graphics.take_vertices(v, mem_pool.create() catch unreachable);
    o = graphics.take_object(o, mem_pool2.create() catch unreachable);
    i = graphics.take_indices(i, mem_pool3.create() catch unreachable);
    o.* = graphics.shape2d.init();
    v.* = graphics.vertices(graphics.color_vertex_2d).init(allocator);
    i.* = graphics.indices16.init(allocator);
    v.*.array.append(.{
        .pos = .{ -0.5, -0.5 },
        .color = .{ 1, 0, 0, 1 },
    }) catch unreachable;
    v.*.array.append(.{
        .pos = .{ 0.5, -0.5 },
        .color = .{ 0, 1, 0, 1 },
    }) catch unreachable;
    v.*.array.append(.{
        .pos = .{ -0.5, 0.5 },
        .color = .{ 0, 0, 1, 1 },
    }) catch unreachable;
    v.*.array.append(.{
        .pos = .{ 0.5, 0.5 },
        .color = .{ 1, 1, 1, 1 },
    }) catch unreachable;
    i.*.array.append(0) catch unreachable;
    i.*.array.append(1) catch unreachable;
    i.*.array.append(2) catch unreachable;
    i.*.array.append(1) catch unreachable;
    i.*.array.append(3) catch unreachable;
    i.*.array.append(2) catch unreachable;
    v.*.build(.read_gpu);
    i.*.build(.read_gpu);

    //system.print("{d}\n", .{@sizeOf(graphics.vertices(u8))});

    o.vertices = v;
    o.indices = i;
    objects.append(&o.interface) catch unreachable;
    graphics.scene = &objects.items;
}

pub fn xfit_update() void {}

pub fn xfit_destroy() void {
    v.*.deinit();
    i.*.deinit();
    objects.deinit();
    mem_pool.deinit();
    mem_pool2.deinit();
    mem_pool3.deinit();
}

pub fn xfit_activate() void {}

pub fn xfit_closing() bool {
    return true;
}

pub fn main() void {
    const init_setting: system.init_setting = .{ .window_width = 600, .window_height = 400, .maxframe = system.sec_to_nano_sec(240, 0) };
    xfit.xfit_main(&init_setting);
}
