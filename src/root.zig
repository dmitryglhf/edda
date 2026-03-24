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

export fn edda_index_add(idx: *index.IndexFlat, ids_ptr: [*]const u64, vectors_ptr: [*]const f32, count: u32) i32 {
    const ids = ids_ptr[0..count];
    const vectors = vectors_ptr[0 .. count * idx.dim];
    idx.add(ids, vectors) catch return -1;
    return 0;
}

export fn edda_index_search(idx: *index.IndexFlat, query_ptr: [*]const f32, query_len: u32, k: u32, out_ids: [*]u64, out_scores: [*]f32) i32 {
    const query = query_ptr[0..query_len];
    const results = idx.search(query, k) catch return -1;
    defer allocator.free(results);
    for (0..results.len) |i| {
        out_ids[i] = results[i].id;
        out_scores[i] = results[i].score;
    }
    return @intCast(results.len);
}

export fn edda_index_save(idx: *index.IndexFlat, path_ptr: [*]const u8, path_len: u32) i32 {
    const path = path_ptr[0..path_len];
    idx.save(path) catch return -1;
    return 0;
}

export fn edda_index_load(path_ptr: [*]const u8, path_len: u32) ?*index.IndexFlat {
    const path = path_ptr[0..path_len];
    const idx = allocator.create(index.IndexFlat) catch return null;
    idx.* = index.IndexFlat.load(allocator, path) catch {
        allocator.destroy(idx);
        return null;
    };
    return idx;
}
