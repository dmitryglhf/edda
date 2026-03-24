import platform
import shutil
import subprocess
import sys
from pathlib import Path

from hatchling.builders.hooks.plugin.interface import BuildHookInterface

# Map (os, machine) to Zig library filename produced by `zig build`.
_LIB_INFO = {
    "Darwin": ("lib", "libedda.dylib"),
    "Linux": ("lib", "libedda.so"),
    "Windows": ("bin", "edda.dll"),
}


class CustomBuildHook(BuildHookInterface):
    def initialize(self, version: str, build_data: dict) -> None:
        root = Path(self.root)

        # 1. Compile shared library
        subprocess.run(
            ["zig", "build", "-Doptimize=ReleaseFast"],
            cwd=root,
            check=True,
        )

        # 2. Find the compiled artifact
        lib_info = _LIB_INFO.get(platform.system())
        if lib_info is None:
            sys.exit(f"Unsupported platform: {platform.system()}")

        subdir, lib_name = lib_info
        src = root / "zig-out" / subdir / lib_name
        if not src.exists():
            sys.exit(f"Build artifact not found: {src}")

        # 3. Copy into the Python package so it ends up in the wheel
        dst = root / "python" / "edda" / f"_edda{src.suffix}"
        shutil.copy2(src, dst)

        # 4. Tell hatchling to include the artifact
        build_data.setdefault("force_include", {})[str(dst)] = f"edda/_edda{src.suffix}"

        # 5. Mark wheel as platform-specific
        build_data["pure_python"] = False
        build_data["infer_tag"] = True
