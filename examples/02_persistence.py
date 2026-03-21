from edda import Index

# Build index
index = Index(dim=3, metric="cosine")
index.add(
    ids=[0, 1, 2],
    vectors=[
        [0.1, 0.2, 0.3],
        [0.9, 0.1, 0.0],
        [0.1, 0.3, 0.28],
    ],
)

# Save to disk — single file, portable
index.save("my_index.edda")

# Load in another process / later
loaded = Index.load("my_index.edda")
results = loaded.search(query=[0.1, 0.2, 0.3], k=2)

for result in results:
    print(f"id={result.id}, score={result.score:.4f}")
