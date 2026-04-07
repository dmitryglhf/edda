"""Brute-force flat index."""

from __future__ import annotations

import ctypes
from typing import Optional

import numpy as np
import numpy.typing as npt

from ._bindings import _lib
from ._common import METRICS, SearchResult, as_float32_2d, as_int64_1d


class IndexFlat:
    """Exact brute-force vector index."""

    def __init__(self, dim: int, metric: str = "cosine"):
        if metric not in METRICS:
            raise ValueError(f"Unknown metric: {metric!r}. Supported: {list(METRICS)}")
        if dim <= 0:
            raise ValueError(f"dim must be positive, got {dim}")

        self._handle = _lib.edda_index_create(dim, METRICS[metric])
        if not self._handle:
            raise MemoryError("Failed to create index")

        self._dim = dim
        self._metric = metric
        self._next_id = 0

    def __del__(self):
        if getattr(self, "_handle", None):
            _lib.edda_index_destroy(self._handle)
            self._handle = None

    def add(
        self,
        vectors: npt.ArrayLike,
        ids: Optional[npt.ArrayLike] = None,
    ) -> None:
        vecs = as_float32_2d(vectors, "vectors")
        if vecs.shape[1] != self._dim:
            raise ValueError(
                f"vectors have dim {vecs.shape[1]}, index expects {self._dim}"
            )

        n = vecs.shape[0]

        if ids is None:
            ids_arr = np.arange(self._next_id, self._next_id + n, dtype=np.int64)
            self._next_id += n
        else:
            ids_arr = as_int64_1d(ids, "ids")
            if len(ids_arr) != n:
                raise ValueError(
                    f"ids length ({len(ids_arr)}) does not match vectors count ({n})"
                )

        # TODO: should delegate it to zig?
        if self._metric == "cosine":
            vecs = vecs.copy()
            norms = np.linalg.norm(vecs, axis=1, keepdims=True)
            np.divide(vecs, norms, out=vecs, where=norms > 0)

        rc = _lib.edda_index_add(
            self._handle,
            ids_arr.ctypes.data_as(ctypes.POINTER(ctypes.c_int64)),
            vecs.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
            ctypes.c_size_t(n),
        )
        if rc != 0:
            raise RuntimeError(f"edda_index_add failed with code {rc}")

    def search(self, queries: npt.ArrayLike, k: int = 10) -> SearchResult:
        if k <= 0:
            raise ValueError(f"k must be positive, got {k}")

        q = as_float32_2d(queries, "queries")
        if q.shape[1] != self._dim:
            raise ValueError(
                f"queries have dim {q.shape[1]}, index expects {self._dim}"
            )

        if self._metric == "cosine":
            q = q.copy()
            norms = np.linalg.norm(q, axis=1, keepdims=True)
            np.divide(q, norms, out=q, where=norms > 0)

        n_queries = q.shape[0]
        out_ids = np.full((n_queries, k), -1, dtype=np.int64)
        out_scores = np.zeros((n_queries, k), dtype=np.float32)

        rc = _lib.edda_index_search_batch(
            self._handle,
            q.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
            ctypes.c_size_t(n_queries),
            ctypes.c_size_t(k),
            out_ids.ctypes.data_as(ctypes.POINTER(ctypes.c_int64)),
            out_scores.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
        )
        if rc < 0:
            raise RuntimeError(f"edda_index_search_batch failed with code {rc}")

        return SearchResult(ids=out_ids, scores=out_scores)

    def save(self, path: str) -> None:
        path_bytes = path.encode("utf-8")
        rc = _lib.edda_index_save(
            self._handle, path_bytes, ctypes.c_size_t(len(path_bytes))
        )
        if rc != 0:
            raise RuntimeError(f"Failed to save index to {path!r} (code {rc})")

    @classmethod
    def load(cls, path: str) -> "IndexFlat":
        path_bytes = path.encode("utf-8")
        out_dim = ctypes.c_uint32(0)
        out_metric = ctypes.c_uint32(0)

        handle = _lib.edda_index_load(
            path_bytes,
            ctypes.c_size_t(len(path_bytes)),
            ctypes.byref(out_dim),
            ctypes.byref(out_metric),
        )
        if not handle:
            raise RuntimeError(f"Failed to load index from {path!r}")

        metric_name = next(
            (name for name, code in METRICS.items() if code == out_metric.value),
            None,
        )
        if metric_name is None:
            _lib.edda_index_destroy(handle)
            raise RuntimeError(f"Unknown metric code in file: {out_metric.value}")

        obj = object.__new__(cls)
        obj._handle = handle
        obj._dim = out_dim.value
        obj._metric = metric_name
        obj._next_id = len(obj)
        return obj

    @property
    def dim(self) -> int:
        return self._dim

    @property
    def metric(self) -> str:
        return self._metric

    def __len__(self) -> int:
        return int(_lib.edda_index_len(self._handle))

    def __repr__(self) -> str:
        return f"IndexFlat(dim={self._dim}, metric={self._metric!r}, size={len(self)})"
