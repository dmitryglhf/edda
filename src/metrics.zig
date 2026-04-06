const std = @import("std");
const types = @import("types.zig");

pub const Metric = enum(u8) {
    cosine = 0,
    dot = 1,
    euclid = 2,
    manhattan = 3,
};

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

pub fn dot(a: []const f32, b: []const f32) f32 {
    var dot_product: f32 = 0.0;
    for (a, b) |a_val, b_val| {
        dot_product += a_val * b_val;
    }

    return dot_product;
}

pub fn euclid(a: []const f32, b: []const f32) f32 {
    var l2: f32 = 0.0;
    for (a, b) |a_val, b_val| {
        l2 += std.math.pow(f32, a_val - b_val, 2);
    }
    return @sqrt(l2);
}

pub fn manhattan(a: []const f32, b: []const f32) f32 {
    var man: f32 = 0.0;
    for (a, b) |a_val, b_val| {
        man += @abs(a_val - b_val);
    }
    return man;
}

pub fn similarity(metric: Metric, a: []const f32, b: []const f32) f32 {
    return switch (metric) {
        .cosine => cosineSimilarity(a, b),
        .dot => dot(a, b),
        .euclid => euclid(a, b),
        .manhattan => manhattan(a, b),
    };
}

test "cosine" {
    const a = [_]f32{ 0.1, 0.2, 0.3 };
    const b = [_]f32{ 0.1, 0.2, 0.3 };

    const val = similarity(Metric.cosine, &a, &b);
    try std.testing.expect(val - 1 < 0.0001);
}

test "dot product" {
    const a = [_]f32{ 0.1, 0.2, 0.3 };
    const b = [_]f32{ 0.1, 0.2, 0.3 };

    const val = similarity(Metric.dot, &a, &b);
    // expected result of provided vectors is 0.14
    try std.testing.expect(val - 0.14 < 0.001);
}

test "euclid distance" {
    const a = [_]f32{ 0.1, 0.2, 0.3 };
    const b = [_]f32{ 0.1, 0.2, 0.3 };

    const val = similarity(Metric.euclid, &a, &b);
    // expected result of provided vectors is 0
    try std.testing.expect(val == 0);
}

test "manhattan distance" {
    const a = [_]f32{ 0.1, 0.2, 0.3 };
    const b = [_]f32{ 0.1, 0.2, 0.3 };

    const val = similarity(Metric.manhattan, &a, &b);
    // expected result of provided vectors is 0
    try std.testing.expect(val == 0);
}
