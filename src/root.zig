const std = @import("std");
const impl = @import("main.zig");

pub const BruteForceResult = extern struct {
    similarity: f32,
    best_j: usize,
};

export fn edda_cosine_similarity(a_ptr: [*]const f32, a_len: usize, b_ptr: [*]const f32, b_len: usize) callconv(.C) f32 {
    return impl.cosineSimilarity(a_ptr[0..a_len], b_ptr[0..b_len]);
}

export fn edda_brute_force_search(a_ptr: [*]const f32, a_len: usize, b_ptr: [*]const f32, b_count: usize) callconv(.C) BruteForceResult {
    const a = a_ptr[0..a_len];
    const b = @as([*]const [5]f32, @ptrCast(b_ptr))[0..b_count];
    const res = impl.bruteForceSearch(a, b);
    return .{ .similarity = res.similarity, .best_j = res.best_j };
}

// const main_mod = @import("main.zig");
//
// pub const cosineSimilarity = main_mod.cosineSimilarity;
// pub const bruteForceSearch = main_mod.bruteForceSearch;

// test "cosine similarity" {
//     const a = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0 };
//     const b = [_]f32{ 6.0, 7.0, 8.0, 9.0, 10.0 };
//     const similarity = cosineSimilarity(&a, &b);
//     std.debug.print("cosine similarity: {}\n", .{similarity});
// }
//
// test "brute force search" {
//     const a = [_]f32{ 1.0, 2.0, 3.0, 4.0, 5.0 };
//     const b = [_][5]f32{
//         .{ 6.0, 7.0, 8.0, 9.0, 10.0 },
//         .{ 11.0, 12.0, 13.0, 14.0, 15.0 },
//         .{ 16.0, 17.0, 18.0, 19.0, 20.0 },
//     };
//     const result = bruteForceSearch(&a, &b);
//     std.debug.print("brute force search: similarity={}, best_j={}\n", .{ result.similarity, result.best_j });
// }
