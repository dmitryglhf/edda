const std = @import("std");
const Allocator = std.mem.Allocator;
const metrics = @import("metrics.zig");
const types = @import("types.zig");

pub const IndexFlat = struct {
    allocator: Allocator,
    dim: u32,
    metric: metrics.Metric,

    vectors: std.ArrayList(f32),
    ids: std.ArrayList(i64),

    pub fn init(allocator: Allocator, dim: u32, metric: metrics.Metric) IndexFlat {
        return .{
            .allocator = allocator,
            .dim = dim,
            .metric = metric,
            .vectors = .{},
            .ids = .{},
        };
    }

    pub fn deinit(self: *IndexFlat) void {
        self.vectors.deinit(self.allocator);
        self.ids.deinit(self.allocator);
    }

    pub fn len(self: *const IndexFlat) usize {
        return self.ids.items.len;
    }

    pub fn add(self: *IndexFlat, ids: []const i64, vectors: []const f32) !void {
        if (vectors.len != ids.len * self.dim) {
            return error.DimensionMismatch;
        }
        try self.vectors.appendSlice(self.allocator, vectors);
        try self.ids.appendSlice(self.allocator, ids);
    }

    pub fn search(self: *const IndexFlat, query: []const f32, k: usize) ![]types.SearchResult {
        if (query.len != self.dim) return error.DimensionMismatch;

        const results = try self.allocator.alloc(types.SearchResult, self.len());
        defer self.allocator.free(results);

        for (0..self.len()) |i| {
            const vec = self.vectors.items[i * self.dim .. (i + 1) * self.dim];
            const score = metrics.similarity(self.metric, vec, query);
            results[i] = .{ .score = score, .id = self.ids.items[i] };
        }

        const actual_k = @min(k, self.len());

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

        try writer.interface.writeAll(types.MAGIC);
        try writer.interface.writeAll(std.mem.asBytes(&types.FORMAT_VERSION));

        try writer.interface.writeAll(std.mem.asBytes(&self.dim));

        const metric_code: u32 = @intFromEnum(self.metric);
        try writer.interface.writeAll(std.mem.asBytes(&metric_code));

        const count: u64 = self.len();
        try writer.interface.writeAll(std.mem.asBytes(&count));

        try writer.interface.writeAll(std.mem.sliceAsBytes(self.ids.items[0..self.len()]));
        try writer.interface.writeAll(std.mem.sliceAsBytes(self.vectors.items[0 .. self.len() * self.dim]));

        try writer.interface.flush();
    }

    pub fn load(allocator: Allocator, path: []const u8) !IndexFlat {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var buf: [4096]u8 = undefined;
        var reader = file.reader(&buf);

        var magic: [4]u8 = undefined;
        try reader.interface.readSliceAll(&magic);
        if (!std.mem.eql(u8, &magic, types.MAGIC)) return error.InvalidFormat;

        var version: u32 = undefined;
        try reader.interface.readSliceAll(std.mem.asBytes(&version));
        if (version != types.FORMAT_VERSION) return error.UnsupportedVersion;

        var dim: u32 = undefined;
        try reader.interface.readSliceAll(std.mem.asBytes(&dim));

        var metric_code: u32 = undefined;
        try reader.interface.readSliceAll(std.mem.asBytes(&metric_code));
        const metric: metrics.Metric = @enumFromInt(metric_code);

        var count: u64 = undefined;
        try reader.interface.readSliceAll(std.mem.asBytes(&count));

        var index = IndexFlat.init(allocator, dim, metric);
        errdefer index.deinit();

        try index.ids.resize(allocator, count);
        try index.vectors.resize(allocator, count * dim);

        try reader.interface.readSliceAll(std.mem.sliceAsBytes(index.ids.items));
        try reader.interface.readSliceAll(std.mem.sliceAsBytes(index.vectors.items));

        return index;
    }
};

test "add and search" {
    var index = IndexFlat.init(std.testing.allocator, 3, .cosine);
    defer index.deinit();

    try index.add(
        &[_]i64{ 0, 1, 2 },
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
        &[_]i64{ 0, 1, 2 },
        &[_]f32{ 0.1, 0.2, 0.3, 0.9, 0.1, 0.0, 0.1, 0.3, 0.28 },
    );

    // Creating temp dir for testing
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const path = try tmp.dir.realpathAlloc(std.testing.allocator, ".");
    defer std.testing.allocator.free(path);
    const full_path = try std.fs.path.join(std.testing.allocator, &.{ path, "test.edda" });
    defer std.testing.allocator.free(full_path);

    try index.save(full_path);
    var i_loaded = try IndexFlat.load(std.testing.allocator, full_path);
    defer i_loaded.deinit();

    // Asserts
    try std.testing.expectEqual(@as(u32, 3), i_loaded.dim);
    try std.testing.expectEqual(@as(usize, 3), i_loaded.len());

    try std.testing.expectEqualSlices(
        i64,
        &[_]i64{ 0, 1, 2 },
        i_loaded.ids.items,
    );
    try std.testing.expectEqualSlices(
        f32,
        &[_]f32{ 0.1, 0.2, 0.3, 0.9, 0.1, 0.0, 0.1, 0.3, 0.28 },
        i_loaded.vectors.items,
    );
}
