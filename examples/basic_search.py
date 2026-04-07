import numpy as np
from edda import IndexFlat

if __name__ == "__main__":
    idx = IndexFlat(dim=3, metric="cosine")
    idx.add(
        np.array([[0.1, 0.2, 0.3], [0.9, 0.1, 0.0], [0.1, 0.3, 0.28]], dtype=np.float32)
    )
    print(len(idx))  # 3

    result = idx.search(np.array([[0.1, 0.2, 0.3]], dtype=np.float32), k=2)
    print(result.ids)
    print(result.scores)

    idx.save("test.edda")
    loaded = IndexFlat.load("test.edda")
    print(len(loaded))
