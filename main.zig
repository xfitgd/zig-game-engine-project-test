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
const builtin = @import("builtin");

const ArrayList = std.ArrayList;
const MemoryPool = std.heap.MemoryPool;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const math = @import("zig-game-engine-project/math.zig");
const mem = @import("zig-game-engine-project/mem.zig");
const matrix = math.matrix;
const file = @import("zig-game-engine-project/file.zig");

const graphics = @import("zig-game-engine-project/graphics.zig");

pub var objects: ArrayList(*graphics.iobject) = ArrayList(*graphics.iobject).init(allocator);
pub var vertices_mem_pool: MemoryPool(graphics.dummy_vertices) = MemoryPool(graphics.dummy_vertices).init(allocator);
pub var objects_mem_pool: MemoryPool(graphics.dummy_object) = MemoryPool(graphics.dummy_object).init(allocator);
pub var indices_mem_pool: MemoryPool(graphics.dummy_indices) = MemoryPool(graphics.dummy_indices).init(allocator);

pub fn xfit_init() void {
    const vertices = graphics.take_vertices(*graphics.vertices(graphics.color_vertex_2d), vertices_mem_pool.create() catch unreachable);
    const indices = graphics.take_indices(*graphics.indices16, indices_mem_pool.create() catch unreachable);
    const object = graphics.take_object(*graphics.shape2d, objects_mem_pool.create() catch unreachable);
    object.* = graphics.shape2d.init();
    vertices.* = graphics.vertices(graphics.color_vertex_2d).init(allocator);
    indices.* = graphics.indices16.init(allocator);
    vertices.*.array.append(.{
        .pos = .{ -0.5, -0.5 },
        .color = .{ 1, 0, 0, 1 },
    }) catch unreachable;
    vertices.*.array.append(.{
        .pos = .{ 0.5, -0.5 },
        .color = .{ 0, 1, 0, 1 },
    }) catch unreachable;
    vertices.*.array.append(.{
        .pos = .{ -0.5, 0.5 },
        .color = .{ 0, 0, 1, 1 },
    }) catch unreachable;
    vertices.*.array.append(.{
        .pos = .{ 0.5, 0.5 },
        .color = .{ 1, 1, 1, 1 },
    }) catch unreachable;
    indices.*.array.appendSlice(&[_]u16{ 0, 1, 2, 1, 3, 2 }) catch unreachable;
    vertices.*.build(.read_gpu);
    indices.*.build(.read_gpu);

    object.vertices = vertices;
    object.indices = indices;
    objects.append(&object.interface) catch unreachable;
    graphics.scene = &objects.items;
}

pub fn xfit_update() void {}

pub fn xfit_destroy() void {
    const ivertices = objects.items[0].*.get_ivertices(objects.items[0]);
    const iindices = objects.items[0].*.get_iindices(objects.items[0]);
    ivertices.?.*.deinit(ivertices.?);
    iindices.?.*.deinit(iindices.?);
    objects.deinit();
    vertices_mem_pool.deinit();
    objects_mem_pool.deinit();
    indices_mem_pool.deinit();

    if (builtin.mode == .Debug and gpa.deinit() != .ok) unreachable;
}

pub fn xfit_activate() void {}

pub fn xfit_closing() bool {
    return true;
}

pub fn main() void {
    const init_setting: system.init_setting = .{ .window_width = 600, .window_height = 400, .maxframe = system.sec_to_nano_sec(240, 0) };
    xfit.xfit_main(&init_setting);
}
