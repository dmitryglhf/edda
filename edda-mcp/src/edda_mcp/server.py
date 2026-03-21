import os

from edda import Index
from fastmcp import FastMCP
from openai import OpenAI

_client = OpenAI(
    base_url=os.environ.get("EDDA_EMBEDDER_BASE_URL"),
    api_key=os.environ.get("EDDA_EMBEDDER_API_KEY", os.environ.get("OPENAI_API_KEY")),
)
_model = os.environ.get("EDDA_EMBEDDER_MODEL", "text-embedding-3-small")
_index_path = os.environ.get("EDDA_INDEX_PATH", "index.edda")
_metric = os.environ.get("EDDA_METRIC", "cosine")

_documents: dict[int, str] = {}
_next_id: int = 0


def _embed(texts: list[str]) -> list[list[float]]:
    response = _client.embeddings.create(model=_model, input=texts)
    return [d.embedding for d in response.data]


# Probe dimension and init index
_probe = _embed(["probe"])
_dim = len(_probe[0])

try:
    _index = Index.load(_index_path)
except FileNotFoundError:
    _index = Index(dim=_dim, metric=_metric)

mcp = FastMCP("edda")


@mcp.tool
def add(texts: list[str]) -> str:
    """Store documents in the index. Returns assigned IDs."""
    global _next_id

    vectors = _embed(texts)
    ids = list(range(_next_id, _next_id + len(texts)))
    _next_id += len(texts)

    _index.add(ids=ids, vectors=vectors)
    for doc_id, text in zip(ids, texts):
        _documents[doc_id] = text

    _index.save(_index_path)
    return f"Added {len(texts)} documents (ids: {ids}). Total: {len(_index)}"


@mcp.tool
def search(query: str, k: int = 5) -> list[dict]:
    """Find the most similar documents to a text query."""
    query_vector = _embed([query])[0]
    results = _index.search(query=query_vector, k=k)
    return [
        {"id": r.id, "score": r.score, "text": _documents.get(r.id, "")}
        for r in results
    ]


@mcp.tool
def info() -> dict:
    """Get index statistics."""
    return {"dim": _index.dim, "count": len(_index), "metric": _index.metric}


def main() -> None:
    mcp.run()
