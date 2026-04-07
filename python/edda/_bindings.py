"""ctypes signatures for the edda C API."""

import ctypes

from ._lib_loader import _lib


# Opaque pointer to IndexFlat (and future index types).
class _IndexHandle(ctypes.Structure):
    pass


_IndexPtr = ctypes.POINTER(_IndexHandle)


# edda_index_create(dim: u32, metric: u32) -> *IndexFlat
_lib.edda_index_create.argtypes = [ctypes.c_uint32, ctypes.c_uint32]
_lib.edda_index_create.restype = _IndexPtr

# edda_index_destroy(idx: *IndexFlat) -> void
_lib.edda_index_destroy.argtypes = [_IndexPtr]
_lib.edda_index_destroy.restype = None

# edda_index_len(idx: *IndexFlat) -> usize
_lib.edda_index_len.argtypes = [_IndexPtr]
_lib.edda_index_len.restype = ctypes.c_size_t

# edda_index_add(idx, ids_ptr, vectors_ptr, count) -> i32
_lib.edda_index_add.argtypes = [
    _IndexPtr,
    ctypes.POINTER(ctypes.c_int64),
    ctypes.POINTER(ctypes.c_float),
    ctypes.c_size_t,
]
_lib.edda_index_add.restype = ctypes.c_int32

# edda_index_search_batch(idx, queries, n_queries, k, out_ids, out_scores) -> i32
_lib.edda_index_search_batch.argtypes = [
    _IndexPtr,
    ctypes.POINTER(ctypes.c_float),
    ctypes.c_size_t,
    ctypes.c_size_t,
    ctypes.POINTER(ctypes.c_int64),
    ctypes.POINTER(ctypes.c_float),
]
_lib.edda_index_search_batch.restype = ctypes.c_int32

# edda_index_save(idx, path_ptr, path_len) -> i32
_lib.edda_index_save.argtypes = [
    _IndexPtr,
    ctypes.c_char_p,
    ctypes.c_size_t,
]
_lib.edda_index_save.restype = ctypes.c_int32

# edda_index_load(path_ptr, path_len, out_dim, out_metric) -> *IndexFlat
_lib.edda_index_load.argtypes = [
    ctypes.c_char_p,
    ctypes.c_size_t,
    ctypes.POINTER(ctypes.c_uint32),
    ctypes.POINTER(ctypes.c_uint32),
]
_lib.edda_index_load.restype = _IndexPtr


# Re-export for convenience
__all__ = ["_lib", "_IndexPtr"]
