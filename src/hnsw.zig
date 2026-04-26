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
            .m_max0 = 2 * opts.m,
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
        // TODO:
        //  - u = self.rng.random().float(f32) BUT (0,1], not [0,1)
        //    var: u = 1.0 - self.rng.random().float(f32), to exclude 0
        //  - l_f = -@log(u) * self.ml
        //  - l = @as(u8, @intFromFloat(@floor(l_f)))
        //  - @min(l, MAX_LEVEL - 1)
        _ = self;
        return 0;
    }
};

test "init and deinit" {
    // TODO
}
