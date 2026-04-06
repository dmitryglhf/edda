import argparse
import gc
import time

import numpy as np
from edda import IndexFlat
from tabulate import tabulate


def generate_data(n_vectors: int, dim: int, n_queries: int, seed: int = 42):
    rng = np.random.default_rng(seed)
    vectors = rng.random((n_vectors, dim), dtype=np.float32)
    queries = rng.random((n_queries, dim), dtype=np.float32)
    ids = list(range(n_vectors))
    return vectors, queries, ids


def bench_edda_add(ids, vectors, dim):
    idx = IndexFlat(dim=dim, metric="cosine")
    gc.collect()
    t0 = time.perf_counter()
    idx.add(ids, vectors.tolist())
    elapsed = time.perf_counter() - t0
    return idx, elapsed


def bench_edda_search(idx, queries, k):
    latencies = []
    for q in queries:
        t0 = time.perf_counter()
        idx.search(q.tolist(), k=k)
        latencies.append(time.perf_counter() - t0)
    return latencies


def bench_chroma_add(ids, vectors, dim):
    import chromadb

    client = chromadb.Client()
    col = client.create_collection("bench", metadata={"hnsw:space": "cosine"})
    str_ids = [str(i) for i in ids]
    gc.collect()
    t0 = time.perf_counter()
    # chroma limits batch size, insert in chunks
    batch = 5000
    for start in range(0, len(ids), batch):
        end = min(start + batch, len(ids))
        col.add(
            ids=str_ids[start:end],
            embeddings=vectors[start:end].tolist(),
        )
    elapsed = time.perf_counter() - t0
    return col, elapsed


def bench_chroma_search(col, queries, k):
    latencies = []
    for q in queries:
        t0 = time.perf_counter()
        col.query(query_embeddings=[q.tolist()], n_results=k)
        latencies.append(time.perf_counter() - t0)
    return latencies


def run(n_vectors: int, dim: int, n_queries: int, k: int):
    print(f"Config: {n_vectors} vectors, dim={dim}, {n_queries} queries, k={k}\n")

    vectors, queries, ids = generate_data(n_vectors, dim, n_queries)

    # add
    edda_idx, edda_add_t = bench_edda_add(ids, vectors, dim)
    chroma_col, chroma_add_t = bench_chroma_add(ids, vectors, dim)

    # search
    edda_lats = bench_edda_search(edda_idx, queries, k)
    chroma_lats = bench_chroma_search(chroma_col, queries, k)

    def stats(lats):
        arr = np.array(lats) * 1000  # ms
        return {
            "mean_ms": f"{arr.mean():.3f}",
            "p50_ms": f"{np.median(arr):.3f}",
            "p99_ms": f"{np.percentile(arr, 99):.3f}",
        }

    edda_s = stats(edda_lats)
    chroma_s = stats(chroma_lats)

    rows = [
        ["Add time (s)", f"{edda_add_t:.4f}", f"{chroma_add_t:.4f}"],
        ["Search mean (ms)", edda_s["mean_ms"], chroma_s["mean_ms"]],
        ["Search p50 (ms)", edda_s["p50_ms"], chroma_s["p50_ms"]],
        ["Search p99 (ms)", edda_s["p99_ms"], chroma_s["p99_ms"]],
    ]

    print(tabulate(rows, headers=["Metric", "edda", "chromadb"], tablefmt="github"))


def main():
    parser = argparse.ArgumentParser(description="edda vs chromadb benchmark")
    parser.add_argument("-n", "--n-vectors", type=int, default=10_000)
    parser.add_argument("-d", "--dim", type=int, default=128)
    parser.add_argument("-q", "--n-queries", type=int, default=100)
    parser.add_argument("-k", type=int, default=10)
    args = parser.parse_args()
    run(args.n_vectors, args.dim, args.n_queries, args.k)


if __name__ == "__main__":
    main()
