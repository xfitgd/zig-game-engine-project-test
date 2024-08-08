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

pub var g_proj: graphics.projection = undefined;
pub var g_camera: graphics.camera = undefined;

pub fn xfit_init() void {
    const vertices = graphics.take_vertices(*graphics.vertices(graphics.color_vertex_2d), vertices_mem_pool.create() catch unreachable);
    const indices = graphics.take_indices(*graphics.indices16, indices_mem_pool.create() catch unreachable);
    const object = graphics.take_object(*graphics.shape2d, objects_mem_pool.create() catch unreachable);
    const object2 = graphics.take_object(*graphics.shape2d, objects_mem_pool.create() catch unreachable);
    const object3 = graphics.take_object(*graphics.shape2d, objects_mem_pool.create() catch unreachable);
    g_proj = graphics.projection.init(.perspective, std.math.degreesToRadians(45)) catch unreachable;
    g_camera = graphics.camera.init(.{ 0, 0, -3, 1 }, .{ 0, 0, 0, 1 }, .{ 0, 1, 0, 1 });

    object.* = graphics.shape2d.init();
    object2.* = graphics.shape2d.init();
    object3.* = graphics.shape2d.init();
    vertices.* = graphics.vertices(graphics.color_vertex_2d).init(allocator);
    indices.* = graphics.indices.init(allocator);
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

    for ([3]*graphics.shape2d{ object, object2, object3 }) |value| {
        value.*.interface.transform.camera = &g_camera;
        value.*.interface.transform.projection = &g_proj;
        value.*.build(.readwrite_cpu);
        value.*.vertices = vertices;
        value.*.indices = indices;
        objects.append(&value.*.interface) catch unreachable;
    }
    object2.*.interface.transform.model = matrix.translation(-3, 0, 3);
    object3.*.interface.transform.model = matrix.translation(3, 0, 3);
    object2.*.interface.transform.map_update();
    object3.*.interface.transform.map_update();

    graphics.scene = &objects.items;
}

//g_proj은 렌더 스레드 내에서 처리해야 해서 Semaphore를 사용해 창 사이즈 바뀔 시 통보 받는 식으로 처리함.
var size_update_sem: std.Thread.Semaphore = .{};
pub fn xfit_update() void {
    var need_size_update = true;
    size_update_sem.timedWait(0) catch {
        need_size_update = false; //?need_size_update 변수를 안쓰는 방법이 있나..?
    };
    if (need_size_update) {
        //system.print_debug("need size update\n", .{});
        g_proj.init_matrix(.perspective, std.math.degreesToRadians(45)) catch unreachable;
        g_proj.map_update();
    }
}

pub fn xfit_size() void {
    size_update_sem.post();
}

pub fn xfit_destroy() void {
    const ivertices = objects.items[0].*.get_ivertices(objects.items[0]);
    const iindices = objects.items[0].*.get_iindices(objects.items[0]);
    ivertices.?.*.deinit(ivertices.?);
    iindices.?.*.deinit(iindices.?);

    g_camera.deinit();
    g_proj.deinit();

    for (objects.items) |value| {
        value.*.deinit();
    }
    objects.deinit();
    vertices_mem_pool.deinit();
    objects_mem_pool.deinit();
    indices_mem_pool.deinit();

    if (builtin.mode == .Debug and gpa.deinit() != .ok) unreachable;
}

pub fn xfit_activate(is_activate: bool, is_pause: bool) void {
    _ = is_activate;
    _ = is_pause;
}

pub fn xfit_closing() bool {
    return true;
}

pub fn main() void {
    const init_setting: system.init_setting = .{ .window_width = 600, .window_height = 400, .maxframe = system.sec_to_nano_sec(240, 0) };
    xfit.xfit_main(&init_setting);
}
