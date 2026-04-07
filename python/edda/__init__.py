import ctypes
from dataclasses import dataclass
from typing import Optional

import numpy as np
import numpy.typing as npt

from . import _bindings as _lib

_METRICS = {"cosine": 0, "dot": 1, "euclid": 2, "manhattan": 3}


@dataclass
class SearchResult:
    """Batch search result. Both arrays have shape (num_queries, k)."""

    ids: npt.NDArray[np.int64]  # int64, -1 for empty slots if fewer than k found
    scores: npt.NDArray[np.float32]

    def __iter__(self):
        """Iterate per-query: yields (ids_row, scores_row) tuples."""
        for i in range(len(self.ids)):
            yield self.ids[i], self.scores[i]


def _as_float32_2d(arr, name: str) -> np.ndarray:
    """Coerce input to contiguous float32 2D array without copying when possible."""
    a = np.ascontiguousarray(arr, dtype=np.float32)
    if a.ndim == 1:
        a = a.reshape(1, -1)
    elif a.ndim != 2:
        raise ValueError(f"{name} must be 1D or 2D, got {a.ndim}D")
    return a


def _as_int64_1d(arr, name: str) -> np.ndarray:
    a = np.ascontiguousarray(arr, dtype=np.int64)
    if a.ndim != 1:
        raise ValueError(f"{name} must be 1D, got {a.ndim}D")
    return a


class IndexFlat:
    def __init__(self, dim: int, metric: str = "cosine"):
        if metric not in _METRICS:
            raise ValueError(f"Unknown metric: {metric!r}. Supported: {list(_METRICS)}")
        if dim <= 0:
            raise ValueError(f"dim must be positive, got {dim}")

        self._handle = _lib._lib.edda_index_create(dim, _METRICS[metric])
        if not self._handle:
            raise MemoryError("Failed to create index")

        self._dim = dim
        self._metric = metric
        self._next_id = 0  # for auto-generated ids

    def __del__(self):
        if getattr(self, "_handle", None):
            _lib._lib.edda_index_destroy(self._handle)
            self._handle = None

    def add(
        self,
        vectors: npt.ArrayLike,
        ids: Optional[npt.ArrayLike] = None,
    ) -> None:
        """Add vectors to the index.

        Parameters
        ----------
        vectors : array-like, shape (n, dim) or (dim,)
            Vectors to add. Will be coerced to float32.
        ids : array-like of int, optional
            Explicit ids. If None, ids are auto-generated starting from
            the current count.
        """
        vecs = _as_float32_2d(vectors, "vectors")

        if vecs.shape[1] != self._dim:
            raise ValueError(
                f"vectors have dim {vecs.shape[1]}, index expects {self._dim}"
            )

        n = vecs.shape[0]

        if ids is None:
            ids_arr = np.arange(self._next_id, self._next_id + n, dtype=np.int64)
            self._next_id += n
        else:
            ids_arr = _as_int64_1d(ids, "ids")
            if len(ids_arr) != n:
                raise ValueError(
                    f"ids length ({len(ids_arr)}) does not match vectors count ({n})"
                )

        # Cosine: normalize in-place on a copy so we don't mutate user data
        if self._metric == "cosine":
            vecs = vecs.copy()
            norms = np.linalg.norm(vecs, axis=1, keepdims=True)
            np.divide(vecs, norms, out=vecs, where=norms > 0)

        rc = _lib._lib.edda_index_add(
            self._handle,
            ids_arr.ctypes.data_as(ctypes.POINTER(ctypes.c_int64)),
            vecs.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
            ctypes.c_size_t(n),
        )
        if rc != 0:
            raise RuntimeError(f"edda_index_add failed with code {rc}")

    def search(
        self,
        queries: npt.ArrayLike,
        k: int = 10,
    ) -> SearchResult:
        """Search for k nearest neighbors.

        Parameters
        ----------
        queries : array-like, shape (n_queries, dim) or (dim,)
            Query vectors. A 1D input is treated as a single query.
        k : int
            Number of neighbors to return per query.

        Returns
        -------
        SearchResult with ids and scores arrays of shape (n_queries, k).
        Empty slots (when fewer than k vectors exist) are filled with -1.
        """
        if k <= 0:
            raise ValueError(f"k must be positive, got {k}")

        q = _as_float32_2d(queries, "queries")
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

        rc = _lib._lib.edda_index_search_batch(
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
        rc = _lib._lib.edda_index_save(
            self._handle, path_bytes, ctypes.c_size_t(len(path_bytes))
        )
        if rc != 0:
            raise RuntimeError(f"Failed to save index to {path!r} (code {rc})")

    @classmethod
    def load(cls, path: str) -> "IndexFlat":
        """Load an index from disk. dim and metric are read from the file."""
        path_bytes = path.encode("utf-8")

        out_dim = ctypes.c_uint32(0)
        out_metric = ctypes.c_uint32(0)

        handle = _lib._lib.edda_index_load(
            path_bytes,
            ctypes.c_size_t(len(path_bytes)),
            ctypes.byref(out_dim),
            ctypes.byref(out_metric),
        )
        if not handle:
            raise RuntimeError(f"Failed to load index from {path!r}")

        metric_name = next(
            (name for name, code in _METRICS.items() if code == out_metric.value),
            None,
        )
        if metric_name is None:
            _lib._lib.edda_index_destroy(handle)
            raise RuntimeError(f"Unknown metric code in file: {out_metric.value}")

        obj = object.__new__(cls)
        obj._handle = handle
        obj._dim = out_dim.value
        obj._metric = metric_name
        obj._next_id = len(obj)  # so subsequent auto-ids continue correctly
        return obj

    @property
    def dim(self) -> int:
        return self._dim

    @property
    def metric(self) -> str:
        return self._metric

    def __len__(self) -> int:
        return int(_lib._lib.edda_index_len(self._handle))

    def __repr__(self) -> str:
        return f"IndexFlat(dim={self._dim}, metric={self._metric!r}, size={len(self)})"
