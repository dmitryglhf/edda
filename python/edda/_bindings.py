import ctypes
import sys
from pathlib import Path

_pkg_dir = Path(__file__).parent
_suffixes = {
    "darwin": ".dylib",
    "linux": ".so",
    "win32": ".dll",
}
_suffix = _suffixes.get(sys.platform)
if _suffix is None:
    raise OSError(f"Unsupported platform: {sys.platform}")

_lib_path = _pkg_dir / f"_edda{_suffix}"
if not _lib_path.exists():
    raise OSError(
        f"Native library not found at {_lib_path}. "
        "Run 'zig build -Doptimize=ReleaseFast' and copy the artifact, "
        "or install the package with 'uv pip install .'"
    )

_lib = ctypes.CDLL(str(_lib_path))

# edda_index_create(dim: u32, metric: u8) -> *IndexFlat | null
_lib.edda_index_create.argtypes = [ctypes.c_uint32, ctypes.c_uint8]
_lib.edda_index_create.restype = ctypes.c_void_p

# edda_index_destroy(handle: *IndexFlat) -> void
_lib.edda_index_destroy.argtypes = [ctypes.c_void_p]
_lib.edda_index_destroy.restype = None

# edda_index_add(handle, ids_ptr, vectors_ptr, count) -> i32
_lib.edda_index_add.argtypes = [
    ctypes.c_void_p,
    ctypes.POINTER(ctypes.c_uint64),
    ctypes.POINTER(ctypes.c_float),
    ctypes.c_uint32,
]
_lib.edda_index_add.restype = ctypes.c_int32

# edda_index_search(handle, query_ptr, query_len, k, out_ids, out_scores) -> i32
_lib.edda_index_search.argtypes = [
    ctypes.c_void_p,
    ctypes.POINTER(ctypes.c_float),
    ctypes.c_uint32,
    ctypes.c_uint32,
    ctypes.POINTER(ctypes.c_uint64),
    ctypes.POINTER(ctypes.c_float),
]
_lib.edda_index_search.restype = ctypes.c_int32

# edda_index_save(handle, path_ptr, path_len) -> i32
_lib.edda_index_save.argtypes = [
    ctypes.c_void_p,
    ctypes.c_char_p,
    ctypes.c_uint32,
]
_lib.edda_index_save.restype = ctypes.c_int32

# edda_index_load(path_ptr, path_len) -> *IndexFlat | null
_lib.edda_index_load.argtypes = [ctypes.c_char_p, ctypes.c_uint32]
_lib.edda_index_load.restype = ctypes.c_void_p
