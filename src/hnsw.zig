const std = @import("std");
const Allocator = std.mem.Allocator;
const metrics = @import("metrics.zig");

pub const IndexHNSW = struct {
    allocator: Allocator,
    dim: u32,
    metric: metrics.Metric,

    pub fn init(allocator: Allocator, dim: u32, metric: metrics.Metric) IndexHNSW {
        return .{
            .allocator = allocator,
            .dim = dim,
            .metric = metric,
        };
    }

    pub fn deinit(self: *IndexHNSW) void {}

    pub fn add(
        self: *IndexHNSW,
    ) void {}

    pub fn search(
        self: *IndexHNSW,
    ) void {}
};
