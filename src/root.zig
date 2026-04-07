pub const IndexFlat = @import("flat.zig").IndexFlat;
pub const Metric = @import("metrics.zig").Metric;

comptime {
    _ = @import("c_api.zig");
}
