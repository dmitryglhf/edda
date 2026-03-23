const std = @import("std");
const index = @import("index.zig");
const types = @import("types.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

export fn edda_index_create(dim: u32, metric: u8) ?*index.IndexFlat {
    const m: types.Metric = @enumFromInt(metric);
    const idx = allocator.create(index.IndexFlat) catch return null;
    idx.* = index.IndexFlat.init(allocator, dim, m);
    return idx;
}

export fn edda_index_destroy() void {
    unreachable;
}

export fn edda_index_add() void {
    unreachable;
}

export fn edda_index_search() void {
    unreachable;
}

export fn edda_index_save() void {
    unreachable;
}

export fn edda_index_load() void {
    unreachable;
}
