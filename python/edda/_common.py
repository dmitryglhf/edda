from __future__ import annotations

from dataclasses import dataclass

import numpy as np
import numpy.typing as npt

METRICS: dict[str, int] = {
    "cosine": 0,
    "dot": 1,
    "euclid": 2,
    "manhattan": 3,
}


@dataclass
class SearchResult:
    """Batch search result. Both arrays have shape (num_queries, k).

    Empty slots (when fewer than k vectors exist) are filled with -1 in `ids`
    and 0.0 in `scores`.
    """

    ids: npt.NDArray[np.int64]
    scores: npt.NDArray[np.float32]

    def __iter__(self):
        """Iterate per-query: yields (ids_row, scores_row) tuples."""
        for i in range(len(self.ids)):
            yield self.ids[i], self.scores[i]

    def __len__(self) -> int:
        return len(self.ids)


def as_float32_2d(arr, name: str = "array") -> np.ndarray:
    """Coerce input to contiguous float32 2D array. 1D inputs are reshaped to (1, n)."""
    a = np.ascontiguousarray(arr, dtype=np.float32)
    if a.ndim == 1:
        a = a.reshape(1, -1)
    elif a.ndim != 2:
        raise ValueError(f"{name} must be 1D or 2D, got {a.ndim}D")
    return a


def as_int64_1d(arr, name: str = "array") -> np.ndarray:
    """Coerce input to contiguous int64 1D array."""
    a = np.ascontiguousarray(arr, dtype=np.int64)
    if a.ndim != 1:
        raise ValueError(f"{name} must be 1D, got {a.ndim}D")
    return a
