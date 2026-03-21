"""PydanticAI agent with Edda as a knowledge retrieval tool.

Install:  uv sync --group examples
Run:      uv run python examples/04_pydantic_ai.py
"""

from dataclasses import dataclass

from edda import Index
from pydantic_ai import Agent, RunContext


@dataclass
class Deps:
    index: Index
    documents: dict[int, str]  # id → original text


agent = Agent(
    "anthropic:claude-sonnet-4-6",
    deps_type=Deps,
    instructions="You answer questions using the knowledge base. "
    "Always search before answering. Cite document IDs.",
)


@agent.tool
def search_knowledge(
    ctx: RunContext[Deps], query_vector: list[float], k: int = 3
) -> list[dict]:
    """Search the knowledge base for relevant documents."""
    results = ctx.deps.index.search(query=query_vector, k=k)
    return [
        {"id": r.id, "score": r.score, "text": ctx.deps.documents.get(r.id, "")}
        for r in results
    ]


if __name__ == "__main__":
    # Build a small index for demo
    index = Index(dim=3, metric="cosine")
    documents = {
        0: "Cats sleep 16 hours a day",
        1: "Dogs love to play fetch",
        2: "Parrots can mimic human speech",
    }
    index.add(
        ids=list(documents.keys()),
        vectors=[
            [0.9, 0.1, 0.0],  # cat-like
            [0.1, 0.9, 0.0],  # dog-like
            [0.0, 0.1, 0.9],  # bird-like
        ],
    )

    result = agent.run_sync(
        "What animals sleep a lot?",
        deps=Deps(index=index, documents=documents),
    )
    print(result.data)
