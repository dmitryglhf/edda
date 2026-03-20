import ctypes
from pathlib import Path
from typing import Sequence

_lib_path = Path(__file__).parent / "_edda.so"
if not _lib_path.exists():
    _lib_path = Path(__file__).parent / "_edda.pyd"

_lib = ctypes.CDLL(str(_lib_path))


class BruteForceResult(ctypes.Structure):
    _fields_ = [("similarity", ctypes.c_float), ("best_j", ctypes.c_size_t)]


_lib.edda_cosine_similarity.argtypes = [
    ctypes.POINTER(ctypes.c_float),
    ctypes.c_size_t,
    ctypes.POINTER(ctypes.c_float),
    ctypes.c_size_t,
]
_lib.edda_cosine_similarity.restype = ctypes.c_float

_lib.edda_brute_force_search.argtypes = [
    ctypes.POINTER(ctypes.c_float),
    ctypes.c_size_t,
    ctypes.POINTER(ctypes.c_float),
    ctypes.c_size_t,
]
_lib.edda_brute_force_search.restype = BruteForceResult


def _as_c_array(data: Sequence[float]) -> tuple[ctypes.Array, int]:
    arr = (ctypes.c_float * len(data))(*data)
    return arr, len(data)


def cosine_similarity(a: Sequence[float], b: Sequence[float]) -> float:
    a_arr, a_len = _as_c_array(a)
    b_arr, b_len = _as_c_array(b)
    return _lib.edda_cosine_similarity(a_arr, a_len, b_arr, b_len)


def brute_force_search(
    a: Sequence[float], collection: Sequence[Sequence[float]]
) -> tuple[float, int]:
    if not collection or not collection[0]:
        raise ValueError("collection must be non-empty")
    dim = len(collection[0])
    if any(len(row) != dim for row in collection):
        raise ValueError("all vectors must have same dimension")

    a_arr, a_len = _as_c_array(a)
    flat_b = [x for row in collection for x in row]
    b_arr, _ = _as_c_array(flat_b)

    res = _lib.edda_brute_force_search(a_arr, a_len, b_arr, len(collection))
    return float(res.similarity), int(res.best_j)
