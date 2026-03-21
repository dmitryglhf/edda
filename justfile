build:
    zig build -Doptimize=ReleaseFast

venv-dev:
    uv sync --group dev
    uv run prek install
    @echo "Dev environment ready"

upd-hooks:
    prek uninstall
    prek install

lint:
    uv run ruff check . --fix
    uv run ruff format .
