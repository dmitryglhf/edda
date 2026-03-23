# edda-mcp

MCP server for [Edda](https://github.com/dmitryglhf/edda) vector search engine.

## Usage

```bash
# OpenAI (default)
export OPENAI_API_KEY=sk-...
uvx edda-mcp

# Ollama (local)
export EDDA_EMBEDDER_BASE_URL=http://localhost:11434/v1
export EDDA_EMBEDDER_API_KEY=ollama
export EDDA_EMBEDDER_MODEL=nomic-embed-text
uvx edda-mcp

# OpenRouter
export EDDA_EMBEDDER_BASE_URL=https://openrouter.ai/api/v1
export EDDA_EMBEDDER_API_KEY=sk-or-...
export EDDA_EMBEDDER_MODEL=openai/text-embedding-3-small
uvx edda-mcp
```

## Claude Desktop

Add to `~/.claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "edda": {
      "command": "uvx",
      "args": ["edda-mcp"],
      "env": {
        "OPENAI_API_KEY": "sk-..."
      }
    }
  }
}
```

## Tools

| Tool | Description |
|------|-------------|
| `add(texts)` | Store documents — embeds and indexes automatically |
| `search(query, k=5)` | Find similar documents by text query |
| `info()` | Get index stats: dimension, count, metric |

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `EDDA_EMBEDDER_MODEL` | `text-embedding-3-small` | Embedding model name |
| `EDDA_EMBEDDER_BASE_URL` | `https://api.openai.com/v1` | OpenAI-compatible API URL |
| `EDDA_EMBEDDER_API_KEY` | `$OPENAI_API_KEY` | API key (falls back to OPENAI_API_KEY) |
| `EDDA_INDEX_PATH` | `index.edda` | Path to index file |
| `EDDA_METRIC` | `cosine` | Distance metric |
