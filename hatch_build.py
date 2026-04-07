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


class CustomBuildHook(BuildHookInterface):
    def initialize(self, version: str, build_data: dict) -> None:
        root = Path(self.root)

        # Wipe build cache to avoid stale artifacts between cibuildwheel iterations.
        zig_out = root / "zig-out"
        if zig_out.exists():
            shutil.rmtree(zig_out)

        subprocess.run(
            ["zig", "build", "-Doptimize=ReleaseFast"],
            cwd=root,
            check=True,
        )

        lib_info = _LIB_INFO.get(platform.system())
        if lib_info is None:
            sys.exit(f"Unsupported platform: {platform.system()}")

        subdir, lib_name = lib_info
        src = root / "zig-out" / subdir / lib_name
        if not src.exists():
            sys.exit(f"Build artifact not found: {src}")

        dst = root / "python" / "edda" / f"_edda{src.suffix}"
        shutil.copy2(src, dst)

        build_data.setdefault("force_include", {})[str(dst)] = f"edda/_edda{src.suffix}"
        build_data["pure_python"] = False
        build_data["infer_tag"] = True
