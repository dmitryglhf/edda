const impl = @import("main.zig");

pub const BruteForceResult = extern struct {
    similarity: f32,
    best_j: usize,
};

export fn edda_cosine_similarity(a_ptr: [*]const f32, a_len: usize, b_ptr: [*]const f32, b_len: usize) f32 {
    return impl.cosineSimilarity(a_ptr[0..a_len], b_ptr[0..b_len]);
}

export fn edda_brute_force_search(a_ptr: [*]const f32, a_len: usize, b_ptr: [*]const f32, b_count: usize) BruteForceResult {
    const a = a_ptr[0..a_len];
    const dim = a_len;
    const total = b_count * dim;
    const flat_b = b_ptr[0..total];

    var max_similarity: f32 = 0.0;
    var best_j: usize = 0;
    for (0..b_count) |j| {
        const row = flat_b[j * dim .. (j + 1) * dim];
        const similarity = impl.cosineSimilarity(a, row);
        if (similarity > max_similarity) {
            max_similarity = similarity;
            best_j = j;
        }
    }
    return .{ .similarity = max_similarity, .best_j = best_j };
}
