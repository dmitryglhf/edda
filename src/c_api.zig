const std = @import("std");
const index = @import("flat.zig");
const metrics = @import("metrics.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

export fn edda_index_create(dim: u32, metric: u32) ?*index.IndexFlat {
    const m: metrics.Metric = @enumFromInt(metric);
    const idx = allocator.create(index.IndexFlat) catch return null;
    idx.* = index.IndexFlat.init(allocator, dim, m);
    return idx;
}

export fn edda_index_destroy(idx: *index.IndexFlat) void {
    idx.deinit();
    allocator.destroy(idx);
}

export fn edda_index_len(idx: *const index.IndexFlat) usize {
    return idx.len();
}

export fn edda_index_add(
    idx: *index.IndexFlat,
    ids_ptr: [*]const i64,
    vectors_ptr: [*]const f32,
    count: usize,
) i32 {
    const ids = ids_ptr[0..count];
    const vectors = vectors_ptr[0 .. count * idx.dim];
    idx.add(ids, vectors) catch return -1;
    return 0;
}

/// Batch search: queries is (n_queries * dim) f32, outputs are (n_queries * k).
/// Empty slots in out_ids are set to -1 if fewer than k vectors exist.
export fn edda_index_search_batch(
    idx: *index.IndexFlat,
    queries_ptr: [*]const f32,
    n_queries: usize,
    k: usize,
    out_ids: [*]i64,
    out_scores: [*]f32,
) i32 {
    const dim = idx.dim;

    // Initialize all output slots to -1 / 0 in case some queries return < k.
    @memset(out_ids[0 .. n_queries * k], -1);
    @memset(out_scores[0 .. n_queries * k], 0);

    var qi: usize = 0;
    while (qi < n_queries) : (qi += 1) {
        const query = queries_ptr[qi * dim .. (qi + 1) * dim];
        const results = idx.search(query, k) catch return -1;
        defer allocator.free(results);

        const base = qi * k;
        for (results, 0..) |r, i| {
            out_ids[base + i] = @intCast(r.id);
            out_scores[base + i] = r.score;
        }
    }
    return 0;
}

/// Single-query helper, kept for convenience. Returns number of results found,
/// or -1 on error. Unlike search_batch, does not pad output to k.
export fn edda_index_search_one(
    idx: *index.IndexFlat,
    query_ptr: [*]const f32,
    query_len: usize,
    k: usize,
    out_ids: [*]i64,
    out_scores: [*]f32,
) i32 {
    const query = query_ptr[0..query_len];
    const results = idx.search(query, k) catch return -1;
    defer allocator.free(results);

    for (results, 0..) |r, i| {
        out_ids[i] = @intCast(r.id);
        out_scores[i] = r.score;
    }
    return @intCast(results.len);
}

export fn edda_index_save(
    idx: *index.IndexFlat,
    path_ptr: [*]const u8,
    path_len: usize,
) i32 {
    const path = path_ptr[0..path_len];
    idx.save(path) catch return -1;
    return 0;
}

/// Load index from disk. dim and metric are read from the file header
/// and returned via out parameters.
export fn edda_index_load(
    path_ptr: [*]const u8,
    path_len: usize,
    out_dim: *u32,
    out_metric: *u32,
) ?*index.IndexFlat {
    const path = path_ptr[0..path_len];
    const idx = allocator.create(index.IndexFlat) catch return null;
    idx.* = index.IndexFlat.load(allocator, path) catch {
        allocator.destroy(idx);
        return null;
    };
    out_dim.* = idx.dim;
    out_metric.* = @intFromEnum(idx.metric);
    return idx;
}
