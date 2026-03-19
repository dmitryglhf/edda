from edda import EddaClient

client = EddaClient()

vector = [0.1, 0.2, 0.3]

client.insert(id="doc1", vector=vector, metadata={"text": ""})

results = client.search(vector=vector, top_k=5)
print(results)
