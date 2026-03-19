const std = @import("std");
const edda = @import("edda");

pub fn main() !void {
    var a = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0 };
    var b = [_]f32{ 6.0, 7.0, 8.0, 9.0, 10.0 };
    const similarity = cosineSimilarity(a[0..], b[0..]);
    std.debug.print("Cosine similarity: {}\n", .{similarity});
}

pub fn cosineSimilarity(a: []f32, b: []f32) f32 {
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
