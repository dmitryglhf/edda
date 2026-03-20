from edda import bf_search, cosine_similarity

if __name__ == "__main__":
    a = [1.0, 2.0, 3.0, 4.0, 5.0]
    b = [6.0, 7.0, 8.0, 9.0, 10.0]

    print(f"cosine similarity: {cosine_similarity(a, b)}")
    collection = [
        [1.0, 2.0, 3.0, 4.0, 5.0],
        [6.0, 7.0, 8.0, 9.0, 10.0],
        [11.0, 12.0, 13.0, 14.0, 15.0],
    ]
    print(f"bf_search result: {bf_search(a, collection)}")
