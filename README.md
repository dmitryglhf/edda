<div align="center">

<img src="https://raw.githubusercontent.com/dmitryglhf/edda/main/assets/logo.svg" alt="logo" width="275"/>

# `edda`

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-3776ab.svg)](https://python.org)
[![Zig 0.15.2](https://img.shields.io/badge/zig-0.15.2-f7a41d.svg)](https://ziglang.org)
[![CI](https://github.com/dmitryglhf/edda/actions/workflows/ci.yml/badge.svg)](https://github.com/dmitryglhf/edda/actions/workflows/ci.yml)

</div>

> [!WARNING]
> Edda is in early development (v0.1). The API will change between versions.

Edda is a lightweight embedded vector search engine written in Zig with Python bindings. Unlike server-based vector databases (Qdrant, Weaviate, Milvus), Edda runs in-process. No daemon, no network, no infrastructure. Unlike pure-C++ libraries (FAISS, hnswlib), it ships with a clean Python API and zero compile-time dependencies for end users. Useful for prototyping RAG pipelines, embedding small-to-medium collections in applications, or learning how vector search works under the hood.

Named after the [Poetic Edda](https://en.wikipedia.org/wiki/Poetic_Edda).

## Installation
```bash
pip install pyedda
```

**Supported platforms** (prebuilt wheels):
- Linux x86_64
- macOS arm64 (Apple Silicon)
- Windows x86_64

On other platforms `pip install` will build from source, which requires [Zig 0.15.2+](https://ziglang.org/download/) to be installed.

## Quickstart
```python
import numpy as np
from edda import IndexFlat

# In a real pipeline these vectors come from an embedding model
# (OpenAI, sentence-transformers, BGE, etc.)
vectors = np.array([
    [0.1, 0.2, 0.3],
    [0.9, 0.1, 0.0],
    [0.1, 0.3, 0.28],
], dtype=np.float32)

idx = IndexFlat(dim=3, metric="cosine")
idx.add(vectors, ids=np.array([10, 20, 30], dtype=np.int64))
print(len(idx))  # 3

query = np.array([[0.1, 0.2, 0.3]], dtype=np.float32)
result = idx.search(query, k=2)
print("Top ids:", result.ids[0])
print("Scores:", result.scores[0])

# Persistence
idx.save("my_index.edda")
loaded = IndexFlat.load("my_index.edda")
print(len(loaded))  # 3
```

See [`examples/`](https://github.com/dmitryglhf/edda/tree/main/examples) for more usage scenarios.

## Roadmap

- **v0.1 (current)** brute-force flat index, persistence, Python bindings, save/load.
- **v0.2** HNSW index for sub-linear search, benchmarks against hnswlib and FAISS on standard ANN datasets.
- **v0.3** filtered search with metadata, batch deletions.
- **Later** MCP server (rebuild after API stabilizes), additional distance metrics, multi-threading.

## Development

Requires [Zig 0.15.2+](https://ziglang.org/download/), [uv](https://docs.astral.sh/uv/), and [just](https://github.com/casey/just).

### Setup
```bash
git clone https://github.com/dmitryglhf/edda.git
cd edda
just build              # compiles the Zig core into the Python package
uv pip install -e .     # installs pyedda in editable mode
```

After modifying Zig code, run `just build` again to rebuild the native library.

### Testing
```bash
just test               # runs both Zig unit tests and Python tests
```

Or run them separately:
```bash
zig build test          # Zig unit tests only
uv run pytest           # Python tests only
```

### Releasing

Releases are automated via GitHub Actions. Two flows are available:

**Dev release to TestPyPI** for iterating on a version before the final release:
```bash
just bump-dev 0.1.3 1   # creates version 0.1.3.dev1
just release            # pushes commit and tag, triggers TestPyPI workflow
just test-install 0.1.3.dev1   # installs from TestPyPI in a fresh venv and smoke-tests
```

**Production release to PyPI** for the final stable version:
```bash
just bump 0.1.3         # creates version 0.1.3
just release            # pushes commit and tag, triggers PyPI workflow
just test-install-prod 0.1.3
```

## License

[MIT](LICENSE)
