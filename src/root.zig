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

export fn edda_index_destroy(idx: *index.IndexFlat) void {
    idx.deinit();
    allocator.destroy(idx);
}

export fn edda_index_add(idx: *index.IndexFlat, ids: []const u64, vectors: []const f32) !void {
    idx.add(ids, vectors);
}

export fn edda_index_search(idx: *index.IndexFlat, query: []const f32, k: u32) ![]types.SearchResult {
    return idx.search(query, k);
}

export fn edda_index_save(idx: *index.IndexFlat, path: []const u8) !void {
    idx.save(path);
}

export fn edda_index_load(path: []const u8) !index.IndexFlat {
    return index.IndexFlat.load(allocator, path);
}
