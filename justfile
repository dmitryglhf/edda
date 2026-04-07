# Usage: just bump 0.1.2
bump version:
    sed -i.bak 's/__version__ = .*/__version__ = "{{ version }}"/' python/edda/__init__.py
    rm python/edda/__init__.py.bak
    git add python/edda/__init__.py
    git commit -m "Bump version to {{ version }}"
    git tag v{{ version }}
    @echo "Tagged v{{ version }}. Run 'just release' to push."

# Bump to a dev version (publishes to TestPyPI when pushed).

# Usage: just bump-dev 0.1.3 1   (creates 0.1.3.dev1)
bump-dev version dev:
    sed -i.bak 's/__version__ = .*/__version__ = "{{ version }}.dev{{ dev }}"/' python/edda/__init__.py
    rm python/edda/__init__.py.bak
    git add python/edda/__init__.py
    git commit -m "Bump version to {{ version }}.dev{{ dev }}"
    git tag v{{ version }}.dev{{ dev }}
    @echo "Tagged v{{ version }}.dev{{ dev }}. Run 'just release' to push."

# Push current branch and all tags to origin. Triggers the release workflow.
release:
    git push
    git push --tags

# just test-install 0.1.3.dev1       (specific version)
test-install version="":
    #!/usr/bin/env bash
    set -euo pipefail
    VENV=$(mktemp -d)/test-pyedda
    python -m venv "$VENV"
    source "$VENV/bin/activate"

    if [ -z "{{ version }}" ]; then
        uv pip install --quiet \
            --index-url https://test.pypi.org/simple/ \
            --extra-index-url https://pypi.org/simple/ \
            --pre \
            pyedda
    else
        uv pip install --quiet \
            --index-url https://test.pypi.org/simple/ \
            --extra-index-url https://pypi.org/simple/ \
            "pyedda=={{ version }}"
    fi

    python -c "
    import edda
    import numpy as np
    print('version:', edda.__version__)
    idx = edda.IndexFlat(dim=3, metric='cosine')
    idx.add(np.array([[1,0,0],[0,1,0],[0,0,1]], dtype=np.float32))
    print('len:', len(idx))
    result = idx.search(np.array([[1,0,0]], dtype=np.float32), k=2)
    print('top ids:', result.ids[0])
    print('OK')
    "

# Same as test-install but from production PyPI.
# Usage: just test-install-prod

# just test-install-prod 0.1.2
test-install-prod version="":
    #!/usr/bin/env bash
    set -euo pipefail
    VENV=$(mktemp -d)/test-pyedda-prod
    python -m venv "$VENV"
    source "$VENV/bin/activate"

    if [ -z "{{ version }}" ]; then
        uv pip install --quiet pyedda
    else
        uv pip install --quiet "pyedda=={{ version }}"
    fi

    python -c "
    import edda
    import numpy as np
    print('version:', edda.__version__)
    idx = edda.IndexFlat(dim=3, metric='cosine')
    idx.add(np.array([[1,0,0],[0,1,0]], dtype=np.float32))
    print('len:', len(idx))
    print('OK')
    "

# Show current version
version:
    @grep '__version__' python/edda/__init__.py | head -1

# Build the Zig library locally for development
build:
    rm -rf zig-out
    zig build -Doptimize=ReleaseFast
    cp zig-out/lib/libedda.* python/edda/_edda.* 2>/dev/null || true

# Run all tests (Zig + Python)
test:
    zig build test
    uv run pytest python/tests -v

# Clean all build artifacts
clean:
    rm -rf zig-out dist build *.egg-info
    find . -type d -name __pycache__ -exec rm -rf {} +
    find . -type f -name '*.pyc' -delete

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
