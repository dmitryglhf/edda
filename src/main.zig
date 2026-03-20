const std = @import("std");

pub fn main() !void {
    const a = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0 };
    const b = [_][5]f32{
        .{ 11.0, 12.0, 13.0, 14.0, 15.0 },
        .{ 6.0, 7.0, 8.0, 9.0, 10.0 },
        .{ 16.0, 17.0, 18.0, 19.0, 20.0 },
    };
    const result = bruteForceSearch(&a, &b);
    std.debug.print("Max similarity: {d}; Idx of best match: {}\n", .{ result.similarity, result.best_j });
}

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

fn bruteForceSearch(input: []const f32, collection: []const [5]f32) struct { similarity: f32, best_j: usize } {
    var max_similarity: f32 = 0.0;
    var best_j: usize = 0;
    for (collection, 0..) |collection_val, j| {
        const similarity = cosineSimilarity(input, &collection_val);
        if (similarity > max_similarity) {
            max_similarity = similarity;
            best_j = j;
        }
    }
    return .{ .similarity = max_similarity, .best_j = best_j };
}
