<div align="center">

<img src="./assets/logo.svg" alt="logo" width="275"/>

# `edda`

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-3776ab.svg)](https://python.org)
[![Zig 0.15.2](https://img.shields.io/badge/zig-0.15.2-f7a41d.svg)](https://ziglang.org)

</div>

> Early development. API will change.

Edda is a lightweight vector similarity search engine. It provides a simple API to store, index, and search vectors with a Python interface and a Zig core for performance. You may find Edda useful for semantic search, RAG, matching, and recommendation systems.

Named afther the [Poetic Edda](https://en.wikipedia.org/wiki/Poetic_Edda).

## Quickstart

```bash
pip install pyedda
```

```python
import numpy as np
from edda import IndexFlat

idx = IndexFlat(dim=3, metric="cosine")
idx.add(np.array([[0.1, 0.2, 0.3], [0.9, 0.1, 0.0], [0.1, 0.3, 0.28]], dtype=np.float32))
print(len(idx))  # 3

result = idx.search(np.array([[0.1, 0.2, 0.3]], dtype=np.float32), k=2)
print(result.ids)
print(result.scores)

idx.save("test.edda")
loaded = IndexFlat.load("test.edda")
print(len(loaded))
```

## Development

Requires [Zig 0.15.2](https://ziglang.org/download/), [uv](https://docs.astral.sh/uv/), [just](https://github.com/casey/just).

```bash
git clone https://github.com/dmitryglhf/edda.git
cd edda
just build
uv pip install -e .
```

## Roadmap

- HNSW
- Benchmarking
- MCP-Server (when stable API)

## License

[MIT](LICENSE)
