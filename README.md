<div align="center">

<img src="./assets/logo.svg" alt="logo" width="275"/>

# `edda`

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-3776ab.svg)](https://python.org)
[![Zig 0.15+](https://img.shields.io/badge/zig-0.15+-f7a41d.svg)](https://ziglang.org)

</div>

> Early development. API will change.

Edda is a lightweight vector similarity search engine. It provides a simple API to store, index, and search vectors with a Python interface and a Zig core for performance.
You may find Edda useful for semantic search, RAG, matching, and recommendation systems. It also ships as an [MCP server](./edda-mcp/) so AI agents can use it as a tool out of the box.

## Quickstart

Soon..

```bash
pip install edda
```

```python
from edda import IndexFlat

index = IndexFlat(dim=3, metric="cosine")

index.add(
    ids=[0, 1, 2],
    vectors=[
        [0.1, 0.2, 0.3],
        [0.9, 0.1, 0.0],
        [0.1, 0.3, 0.28],
    ],
)

results = index.search(query=[0.1, 0.2, 0.3], k=2)
for r in results:
    print(f"id={r.id}, score={r.score:.4f}")
```

## Development

Requires [Zig 0.15+](https://ziglang.org/download/), [uv](https://docs.astral.sh/uv/), [just](https://github.com/casey/just).

```bash
git clone https://github.com/dmitryglhf/edda.git
cd edda
just build
uv pip install -e .
```

## License

[MIT](LICENSE)
