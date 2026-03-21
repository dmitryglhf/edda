import numpy as np
from edda import Index

# Typical RAG scenario: embed 1000 documents with 768-dim model
rng = np.random.default_rng(42)
vectors = rng.standard_normal((1000, 768)).astype(np.float32)
ids = list(range(1000))

index = Index(dim=768, metric="cosine")
index.add(ids=ids, vectors=vectors)  # accepts np.ndarray directly, zero-copy to Zig

# Search with a numpy query
query = rng.standard_normal(768).astype(np.float32)
results = index.search(query=query, k=5)

for result in results:
    print(f"id={result.id}, score={result.score:.4f}")
