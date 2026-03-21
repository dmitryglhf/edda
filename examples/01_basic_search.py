from edda import Index

# Create an in-memory index for 3-dimensional vectors
index = Index(dim=3, metric="cosine")

# Add vectors with IDs
index.add(
    ids=[0, 1, 2],
    vectors=[
        [0.1, 0.2, 0.3],
        [0.9, 0.1, 0.0],
        [0.1, 0.3, 0.28],
    ],
)

# Search: find 2 most similar vectors to query
results = index.search(query=[0.1, 0.2, 0.3], k=2)

for result in results:
    print(f"id={result.id}, score={result.score:.4f}")
# Expected:
#   id=0, score=1.0000  (exact match)
#   id=2, score=0.9972  (very similar)
