import ctypes
from dataclasses import dataclass
from typing import Sequence, Union

import numpy.typing as npt

from . import _bindings as _lib

_METRICS = {"cosine": 0}

VectorLike = Union[Sequence[Sequence[float]], npt.NDArray]
QueryLike = Union[Sequence[float], npt.NDArray]


@dataclass
class SearchResult:
    id: int
    score: float


class IndexFlat:
    def __init__(self, dim: int, metric: str = "cosine"):
        if metric not in _METRICS:
            raise ValueError(f"Unknown metric: {metric}. Supported: {list(_METRICS)}")
        self._handle = _lib._lib.edda_index_create(dim, _METRICS[metric])
        if not self._handle:
            raise MemoryError("Failed to create index")
        self._dim = dim
        self._metric = metric

    def __del__(self):
        if getattr(self, "_handle", None):
            _lib._lib.edda_index_destroy(self._handle)

    def add(self, ids: Sequence[int], vectors: VectorLike) -> None:
        if len(ids) != len(vectors):
            raise ValueError("ids and vectors must have the same length")
        flat = [x for vec in vectors for x in vec]
        count = len(ids)
        ids_arr = (ctypes.c_uint64 * count)(*ids)
        vec_arr = (ctypes.c_float * len(flat))(*flat)
        rc = _lib._lib.edda_index_add(self._handle, ids_arr, vec_arr, count)
        if rc != 0:
            raise RuntimeError("Failed to add vectors")

    def search(self, query: QueryLike, k: int = 10) -> list[SearchResult]:
        query_arr = (ctypes.c_float * len(query))(*query)
        out_ids = (ctypes.c_uint64 * k)()
        out_scores = (ctypes.c_float * k)()
        n = _lib._lib.edda_index_search(
            self._handle, query_arr, len(query), k, out_ids, out_scores
        )
        if n < 0:
            raise RuntimeError("Search failed")
        return [
            SearchResult(id=int(out_ids[i]), score=float(out_scores[i]))
            for i in range(n)
        ]

    def save(self, path: str) -> None:
        path_bytes = path.encode("utf-8")
        rc = _lib._lib.edda_index_save(self._handle, path_bytes, len(path_bytes))
        if rc != 0:
            raise RuntimeError(f"Failed to save index to {path}")

    @classmethod
    def load(cls, path: str, dim: int = 0, metric: str = "cosine") -> "IndexFlat":
        path_bytes = path.encode("utf-8")
        handle = _lib._lib.edda_index_load(path_bytes, len(path_bytes))
        if not handle:
            raise RuntimeError(f"Failed to load index from {path}")
        obj = object.__new__(cls)
        obj._handle = handle
        obj._dim = dim
        obj._metric = metric
        return obj

    @property
    def dim(self) -> int:
        return self._dim

    @property
    def metric(self) -> str:
        return self._metric

    def __len__(self) -> int:
        raise NotImplementedError("len() not yet supported via FFI")

    def __repr__(self) -> str:
        return f"Index(dim={self._dim}, metric='{self._metric}')"
