pub const Metric = enum(u8) {
    cosine = 0,
};

pub const SearchResult = extern struct {
    id: u64,
    score: f32,
};
