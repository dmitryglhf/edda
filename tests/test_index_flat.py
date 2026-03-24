import os

import pytest

from edda import IndexFlat, SearchResult


@pytest.fixture
def index():
    idx = IndexFlat(dim=3)
    idx.add(
        ids=[0, 1, 2],
        vectors=[[0.1, 0.2, 0.3], [0.9, 0.1, 0.0], [0.1, 0.3, 0.28]],
    )
    return idx


class TestInit:
    def test_default_metric(self):
        idx = IndexFlat(dim=5)
        assert idx.dim == 5
        assert idx.metric == "cosine"

    def test_unknown_metric(self):
        with pytest.raises(ValueError, match="Unknown metric"):
            IndexFlat(dim=3, metric="hamming")


class TestAdd:
    def test_add_and_search(self, index):
        results = index.search(query=[0.1, 0.2, 0.3], k=2)
        assert len(results) == 2
        assert all(isinstance(r, SearchResult) for r in results)

    def test_ids_vectors_mismatch(self, index):
        with pytest.raises(ValueError, match="same length"):
            index.add(ids=[10, 11], vectors=[[1.0, 2.0, 3.0]])


class TestSearch:
    def test_top_k(self, index):
        results = index.search(query=[0.1, 0.2, 0.3], k=1)
        assert len(results) == 1
        assert results[0].id == 0

    def test_k_larger_than_count(self, index):
        results = index.search(query=[0.1, 0.2, 0.3], k=100)
        assert len(results) == 3

    def test_scores_descending(self, index):
        results = index.search(query=[0.1, 0.2, 0.3], k=3)
        scores = [r.score for r in results]
        assert scores == sorted(scores, reverse=True)


class TestPersistence:
    def test_save_and_load(self, index, tmp_path):
        path = str(tmp_path / "test.edda")
        index.save(path)
        assert os.path.exists(path)

        loaded = IndexFlat.load(path)
        results = loaded.search(query=[0.1, 0.2, 0.3], k=2)
        assert len(results) == 2
        assert results[0].id == 0
