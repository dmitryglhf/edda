import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

from hatchling.builders.hooks.plugin.interface import BuildHookInterface

_LIB_INFO = {
    "Darwin": ("lib", "libedda.dylib"),
    "Linux": ("lib", "libedda.so"),
    "Windows": ("bin", "edda.dll"),
}

# Map cibuildwheel ARCHFLAGS values to Zig target triples.
_MACOS_ZIG_TARGETS = {
    "arm64": "aarch64-macos",
    "x86_64": "x86_64-macos",
}


def _detect_macos_target() -> str | None:
    """Detect target arch from cibuildwheel-set environment, or None for native."""
    # cibuildwheel sets ARCHFLAGS to '-arch arm64' or '-arch x86_64'
    archflags = os.environ.get("ARCHFLAGS", "")
    for arch, target in _MACOS_ZIG_TARGETS.items():
        if arch in archflags:
            return target
    return None


class CustomBuildHook(BuildHookInterface):
    def initialize(self, version: str, build_data: dict) -> None:
        root = Path(self.root)

        zig_args = ["zig", "build", "-Doptimize=ReleaseFast"]

        # On macOS, explicitly pass the target arch so we don't accidentally
        # ship an arm64 dylib inside an x86_64 wheel (or vice versa).
        if platform.system() == "Darwin":
            target = _detect_macos_target()
            if target is not None:
                zig_args.append(f"-Dtarget={target}")
                print(f"=== Building for macOS target: {target}")

        # Wipe the build cache to make sure we never reuse an artifact built
        # for a different architecture in a previous cibuildwheel iteration.
        zig_out = root / "zig-out"
        if zig_out.exists():
            shutil.rmtree(zig_out)

        print(f"=== Running: {' '.join(zig_args)}")
        subprocess.run(zig_args, cwd=root, check=True)

        lib_info = _LIB_INFO.get(platform.system())
        if lib_info is None:
            sys.exit(f"Unsupported platform: {platform.system()}")

        subdir, lib_name = lib_info
        src = root / "zig-out" / subdir / lib_name
        if not src.exists():
            sys.exit(f"Build artifact not found: {src}")

        dst = root / "python" / "edda" / f"_edda{src.suffix}"
        shutil.copy2(src, dst)

        # Sanity check on macOS: confirm the dylib has the expected arch.
        if platform.system() == "Darwin":
            print("=== Built dylib info:")
            subprocess.run(["file", str(dst)], check=False)
            subprocess.run(["lipo", "-info", str(dst)], check=False)
            subprocess.run(["otool", "-D", str(dst)], check=False)

        build_data.setdefault("force_include", {})[str(dst)] = f"edda/_edda{src.suffix}"
        build_data["pure_python"] = False
        build_data["infer_tag"] = True
