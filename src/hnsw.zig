const std = @import("std");
const Allocator = std.mem.Allocator;
const metrics = @import("metrics.zig");
const types = @import("types.zig");

// hnswlib defaults
pub const M_DEFAULT: u32 = 16;
pub const EF_CONSTRUCTION_DEFAULT: u32 = 200;
pub const EF_SEARCH_DEFAULT: u32 = 50;

const MAX_LEVEL: u8 = 16;

const NodeIdx = u32;

/// A node paired with its closeness to the query (higher = closer).
/// Used as the element type in the search heaps.
const Candidate = struct {
    idx: NodeIdx,
    score: f32,
};

/// Tracks which nodes a single searchLayer call has already expanded.
/// Start simple with a hash set; can be swapped for an epoch-stamped
/// array later if it shows up in profiling.
const Visited = std.AutoHashMapUnmanaged(NodeIdx, void);

const Node = struct {
    id: i64,
    level: u8,
    upper_neighbors: [][]NodeIdx,
};

pub const IndexHnsw = struct {
    allocator: Allocator,
    dim: u32,
    metric: metrics.Metric,

    // HNSW params
    m: u32,
    m_max0: u32, // = 2 * m
    ef_construction: u32,
    ml: f32, // 1/ln(m)

    vectors: std.ArrayList(f32),
    nodes: std.ArrayList(Node),

    // Access via `layer0NeighborsOf(idx)`.
    layer0_neighbors: std.ArrayList(NodeIdx),
    // reading first values by count
    layer0_counts: std.ArrayList(u8),

    // Graph entry point
    entry_point: ?NodeIdx,
    max_level: u8,

    // RNG for level selection in insert
    rng: std.Random.DefaultPrng,

    pub const Options = struct {
        m: u32 = M_DEFAULT,
        ef_construction: u32 = EF_CONSTRUCTION_DEFAULT,
        seed: u64 = 0,
    };

    pub fn init(
        allocator: Allocator,
        dim: u32,
        metric: metrics.Metric,
        opts: Options,
    ) IndexHnsw {
        return .{
            .m = opts.m,
            .m_max0 = 2 * opts.m,
            .ef_construction = opts.ef_construction,
            .ml = 1.0 / @log(@as(f32, @floatFromInt(opts.m))),
            .nodes = .empty,
            .vectors = .empty,
            .layer0_neighbors = .empty,
            .layer0_counts = .empty,
            .entry_point = null,
            .max_level = 0,
            .rng = std.Random.DefaultPrng.init(opts.seed),
            .allocator = allocator,
            .dim = dim,
            .metric = metric,
        };
    }

    pub fn deinit(self: *IndexHnsw) void {
        for (self.nodes.items) |node| {
            for (node.upper_neighbors) |neighb| {
                self.allocator.free(neighb);
            }
            self.allocator.free(node.upper_neighbors);
        }
        self.nodes.deinit(self.allocator);
        self.vectors.deinit(self.allocator);
        self.layer0_neighbors.deinit(self.allocator);
        self.layer0_counts.deinit(self.allocator);
    }

    pub fn len(self: *const IndexHnsw) usize {
        return self.nodes.items.len;
    }

    // Utils

    fn vectorAt(self: *const IndexHnsw, idx: NodeIdx) []const f32 {
        return self.vectors.items[idx * self.dim .. (idx + 1) * self.dim];
    }

    fn layer0NeighborsOf(self: *const IndexHnsw, idx: NodeIdx) []const NodeIdx {
        const start = @as(usize, idx) * self.m_max0;
        const count = self.layer0_counts.items[idx];
        return self.layer0_neighbors.items[start .. start + count];
    }

    fn neighborsOf(self: *const IndexHnsw, idx: NodeIdx, layer: u8) []const NodeIdx {
        if (layer == 0) return self.layer0NeighborsOf(idx);
        const node = &self.nodes.items[idx];
        return node.upper_neighbors[layer - 1];
    }

    fn randomLevel(self: *IndexHnsw) u8 {
        const u = 1.0 - self.rng.random().float(f32);
        const l_f = @floor(-@log(u) * self.ml);
        const lim = @min(l_f, @as(f32, MAX_LEVEL - 1));

        return @intFromFloat(lim);
    }

    /// Unifies similarity
    fn closeness(self: *const IndexHnsw, a: []const f32, b: []const f32) f32 {
        const s = metrics.similarity(self.metric, a, b);
        return switch (self.metric) {
            .cosine, .dot => s,
            .euclid, .manhattan => -s,
        };
    }

    /// Store a new point WITHOUT linking it into the graph.
    fn appendNode(self: *IndexHnsw, id: i64, vector: []const f32, level: u8) !NodeIdx {
        _ = self;
        _ = id;
        _ = vector;
        _ = level;
        @panic("TODO: appendNode");
    }

    pub fn search(self: *IndexHnsw, query: []const f32, k: usize) ![]types.SearchResult {
        _ = self;
        _ = query;
        _ = k;
        @panic("TODO: search");
    }
};

test "init and deinit" {
    // TODO
}

test "randomLevel distribution" {
    var index = IndexHnsw.init(std.testing.allocator, 4, .cosine, .{});
    defer index.deinit();

    var counts = [_]usize{0} ** MAX_LEVEL;
    for (0..100_000) |_| {
        counts[index.randomLevel()] += 1;
    }

    // Level 0 should dominate (~ 1 - 1/16 = 93.75% at m=16)
    try std.testing.expect(counts[0] > 90_000);
    // And each higher level should be rarer than the one below it
    try std.testing.expect(counts[0] > counts[1]);
    try std.testing.expect(counts[1] > counts[2]);
}
