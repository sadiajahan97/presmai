import os
import chromadb
from chromadb.config import Settings
from chromadb.api import ClientAPI
from chromadb.utils import embedding_functions

_client: ClientAPI | None = None


def init_chroma() -> ClientAPI:
    global _client
    persist_directory = os.path.join(os.getcwd(), "storage", "chroma_db")
    os.makedirs(persist_directory, exist_ok=True)
    
    _client = chromadb.PersistentClient(path=persist_directory)
    return _client


def get_chroma_client() -> ClientAPI:
    if _client is None:
        return init_chroma()
    return _client


def get_collection(name: str):
    client = get_chroma_client()
    
    bge_ef = embedding_functions.SentenceTransformerEmbeddingFunction(
        model_name="BAAI/bge-small-en-v1.5"
    )
    
    return client.get_or_create_collection(
        name=name,
        embedding_function=bge_ef
    )


def query_medications(query_text: str, n_results: int = 5) -> list[tuple[str, dict]]:
    collection = get_collection("medications")

    results = collection.query(
        query_texts=[query_text],
        n_results=n_results,
    )

    matches = []
    if results and results["documents"] and results["documents"][0]:
        docs = results["documents"][0]
        metas = results["metadatas"][0] if results["metadatas"] else [{}] * len(docs)
        for doc, meta in zip(docs, metas):
            matches.append((doc, meta))

    return matches
