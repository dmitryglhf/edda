import numpy as np
from edda import IndexFlat

if __name__ == "__main__":
    rng = np.random.default_rng(42)
    vectors = rng.standard_normal((1000, 768)).astype(np.float32)
    ids = list(range(1000))

    index = IndexFlat(dim=768, metric="cosine")
    index.add(ids=ids, vectors=vectors)

    # Search with a numpy query
    query = rng.standard_normal(768).astype(np.float32)
    results = index.search(query=query, k=5)

    for result in results:
        print(f"id={result.id}, score={result.score:.4f}")
