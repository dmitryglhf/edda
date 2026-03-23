const std = @import("std");
const Allocator = std.mem.Allocator;
const metrics = @import("metrics.zig");
const types = @import("types.zig");

pub const IndexFlat = struct {
    allocator: Allocator,
    dim: u32,
    metric: types.Metric,

    vectors: std.ArrayList(f32),
    ids: std.ArrayList(u64),
    count: u32,

    pub fn init(allocator: Allocator, dim: u32, metric: types.Metric) IndexFlat {
        return .{
            .allocator = allocator,
            .dim = dim,
            .metric = metric,
            .vectors = std.ArrayList(f32).init(allocator),
            .ids = std.ArrayList(u64).init(allocator),
            .count = 0,
        };
    }

    pub fn deinit(self: *IndexFlat) void {
        self.vectors.deinit(self.allocator);
        self.ids.deinit(self.allocator);
    }

    pub fn add(self: *IndexFlat, ids: []const u64, vectors: []const f32) !void {
        if (vectors.len != ids.len * self.dim) {
            return error.DimensionMismatch;
        }
        try self.vectors.appendSlice(self.allocator, vectors);
        try self.ids.appendSlice(self.allocator, ids);
        self.count += @intCast(ids.len);
    }

    pub fn search(self: *const IndexFlat, query: []const f32, k: u32) ![]types.SearchResult {
        if (query.len != self.dim) return error.DimensionMismatch;

        const results = try self.allocator.alloc(types.SearchResult, self.count);
        defer self.allocator.free(results);

        for (0..self.count) |i| {
            const vec = self.vectors.items[i * self.dim .. (i + 1) * self.dim];
            const score = metrics.similarity(self.metric, vec, query);
            results[i] = .{ .score = score, .id = self.ids.items[i] };
        }

        const actual_k = @min(k, self.count);

        std.mem.sort(types.SearchResult, results, {}, struct {
            fn cmp(ctx: void, a: types.SearchResult, b: types.SearchResult) bool {
                _ = ctx;
                return a.score > b.score;
            }
        }.cmp);

        const top_k = try self.allocator.alloc(types.SearchResult, actual_k);
        @memcpy(top_k, results[0..actual_k]);

        return top_k;
    }
};

test "add and search" {
    var index = IndexFlat(std.testing.allocator, 3, .cosine);
    defer index.deinit();

    try index.add(
        &[_]u64{ 0, 1, 2 },
        &[_]f32{ 0.1, 0.2, 0.3, 0.9, 0.1, 0.0, 0.1, 0.3, 0.28 },
    );

    const query = &[_]f32{ 0.3, 0.8, 0.6 };
    const results = try index.search(query, 2);
    defer std.testing.allocator.free(results);

    try std.testing.expect(results.len == 2);
}
