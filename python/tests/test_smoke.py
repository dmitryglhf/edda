import numpy as np
from edda import IndexFlat


def test_create_and_search():
    idx = IndexFlat(dim=3, metric="cosine")
    vectors = np.array(
        [
            [0.1, 0.2, 0.3],
            [0.9, 0.1, 0.0],
            [0.1, 0.3, 0.28],
        ],
        dtype=np.float32,
    )
    idx.add(vectors)
    assert len(idx) == 3

    result = idx.search(np.array([[0.1, 0.2, 0.3]], dtype=np.float32), k=2)
    assert result.ids.shape == (1, 2)
    assert result.scores.shape == (1, 2)


def test_save_load(tmp_path):
    idx = IndexFlat(dim=3, metric="cosine")
    idx.add(np.array([[1.0, 0.0, 0.0]], dtype=np.float32))
    path = tmp_path / "test.edda"
    idx.save(str(path))

    loaded = IndexFlat.load(str(path))
    assert len(loaded) == 1
    assert loaded.dim == 3
    assert loaded.metric == "cosine"
