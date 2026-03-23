const types = @import("types.zig");

pub fn cosineSimilarity(a: []const f32, b: []const f32) f32 {
    var dot_product: f32 = 0.0;
    var norm_a: f32 = 0.0;
    var norm_b: f32 = 0.0;
    for (a, b) |a_val, b_val| {
        dot_product += a_val * b_val;
        norm_a += a_val * a_val;
        norm_b += b_val * b_val;
    }
    return dot_product / (@sqrt(norm_a) * @sqrt(norm_b));
}

pub fn similarity(metric: types.Metric, a: []const f32, b: []const f32) f32 {
    return switch (metric) {
        .cosine => cosineSimilarity(a, b),
    };
}
