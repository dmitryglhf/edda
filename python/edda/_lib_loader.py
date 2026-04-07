"""Locate and load the native edda shared library."""

from __future__ import annotations

import ctypes
import os
import sys
from pathlib import Path


def _lib_filename() -> str:
    if sys.platform == "darwin":
        return "_edda.dylib"
    if sys.platform == "win32":
        return "_edda.dll"
    return "_edda.so"


def _candidate_paths() -> list[Path]:
    """Search locations in priority order.

    EDDA_LIB_PATH env var (explicit override, useful for debugging).
    """
    name = _lib_filename()
    here = Path(__file__).resolve().parent
    repo_root = here.parent.parent  # python/edda/ -> python/ -> repo root

    paths: list[Path] = []

    env_override = os.environ.get("EDDA_LIB_PATH")
    if env_override:
        paths.append(Path(env_override))

    paths.append(here / name)

    # Dev layout: zig build puts artifacts in zig-out/{lib,bin}
    if sys.platform == "win32":
        paths.append(repo_root / "zig-out" / "bin" / name)
    else:
        paths.append(repo_root / "zig-out" / "lib" / name)

    return paths


def load_library() -> ctypes.CDLL:
    candidates = _candidate_paths()
    for path in candidates:
        if path.exists():
            try:
                return ctypes.CDLL(str(path))
            except OSError as e:
                raise RuntimeError(f"Found {path} but failed to load it: {e}") from e

    tried = "\n  ".join(str(p) for p in candidates)
    raise RuntimeError(
        f"Could not locate the edda native library ({_lib_filename()}).\n"
        f"Searched:\n  {tried}\n"
        f"If you are developing locally, run `zig build` first.\n"
        f"You can also set EDDA_LIB_PATH to point at the .so/.dylib/.dll directly."
    )


_lib = load_library()
