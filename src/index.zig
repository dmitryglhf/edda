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
            .vectors = .{},
            .ids = .{},
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

    pub fn save(self: *const IndexFlat, path: []const u8) !void {
        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();

        var buf: [4096]u8 = undefined;
        var writer = file.writer(&buf);

        try writer.interface.writeAll(std.mem.asBytes(&self.dim));
        try writer.interface.writeAll(std.mem.asBytes(&self.metric));
        try writer.interface.writeAll(std.mem.asBytes(&self.count));
        try writer.interface.writeAll(std.mem.sliceAsBytes(self.ids.items[0..self.count]));
        try writer.interface.writeAll(std.mem.sliceAsBytes(self.vectors.items[0 .. self.count * self.dim]));

        try writer.interface.flush();
    }

    pub fn load(allocator: Allocator, path: []const u8) !IndexFlat {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var buf: [4096]u8 = undefined;
        var reader = file.reader(&buf);

        var dim: u32 = undefined;
        try reader.interface.readSliceAll(std.mem.asBytes(&dim));

        var metric: types.Metric = undefined;
        try reader.interface.readSliceAll(std.mem.asBytes(&metric));

        var count: u32 = undefined;
        try reader.interface.readSliceAll(std.mem.asBytes(&count));

        const ids = try allocator.alloc(u64, count);
        defer allocator.free(ids);
        try reader.interface.readSliceAll(std.mem.sliceAsBytes(ids));

        const vectors = try allocator.alloc(f32, count * dim);
        defer allocator.free(vectors);
        try reader.interface.readSliceAll(std.mem.sliceAsBytes(vectors));

        var index = IndexFlat.init(allocator, dim, metric);
        index.count = count;
        try index.ids.appendSlice(allocator, ids);
        try index.vectors.appendSlice(allocator, vectors);

        return index;
    }
};

test "add and search" {
    var index = IndexFlat.init(std.testing.allocator, 3, .cosine);
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

test "save and load" {
    var index = IndexFlat.init(std.testing.allocator, 3, .cosine);
    defer index.deinit();

    try index.add(
        &[_]u64{ 0, 1, 2 },
        &[_]f32{ 0.1, 0.2, 0.3, 0.9, 0.1, 0.0, 0.1, 0.3, 0.28 },
    );

    try index.save("test_idx.edda");
    var i_loaded = try IndexFlat.load(std.testing.allocator, "test_idx.edda");
    defer i_loaded.deinit();

    try std.testing.expectEqual(@as(u32, 3), i_loaded.dim);
    try std.testing.expectEqual(@as(u32, 3), i_loaded.count);

    defer std.fs.cwd().deleteFile("test_idx.edda") catch {};
}
