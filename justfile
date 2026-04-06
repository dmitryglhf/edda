root := justfile_directory()
lib_ext := if os() == "macos" { "dylib" } else if os() == "linux" { "so" } else { error("unsupported OS") }
lib_name := "libedda." + lib_ext
py_name := "_edda." + lib_ext

build:
    zig build -Doptimize=ReleaseFast
    cp {{ root }}/zig-out/lib/{{ lib_name }} {{ root }}/python/edda/{{ py_name }}

venv-dev:
    uv sync --group dev
    uv run prek install
    @echo "Dev environment ready"

upd-hooks:
    prek uninstall
    prek install

bench *ARGS:
    uv run --group bench python benchmarks/bench_vs_chroma.py {{ ARGS }}

lint:
    uv run ruff check . --fix
    uv run ruff format .
