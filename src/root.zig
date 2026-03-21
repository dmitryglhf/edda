const impl = @import("main.zig");

export fn edda_cosine_similarity(a_ptr: [*]const f32, a_len: usize, b_ptr: [*]const f32, b_len: usize) f32 {
    return impl.cosineSimilarity(a_ptr[0..a_len], b_ptr[0..b_len]);
}

export fn edda_brute_force_search(a_ptr: [*]const f32, a_len: usize, b_ptr: [*]const f32, b_count: usize) impl.SearchResult {
    const a = a_ptr[0..a_len];
    const flat_b = b_ptr[0 .. b_count * a_len];
    return impl.bruteForceSearch(a, flat_b, b_count);
}
