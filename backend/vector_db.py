import os

from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams

_client: QdrantClient | None = None
_model = None

BGE_MODEL_NAME = "BAAI/bge-small-en-v1.5"
VECTOR_SIZE = 384
COLLECTION_MEDICATIONS = "medications"

BGE_QUERY_PREFIX = "Represent this sentence for searching relevant passages: "
BGE_DOCUMENT_PREFIX = "Represent this passage for retrieval: "


def _get_model():
    global _model
    if _model is None:
        from sentence_transformers import SentenceTransformer

        _model = SentenceTransformer(BGE_MODEL_NAME)
    return _model


def _ensure_medications_collection(client: QdrantClient) -> None:
    names = {c.name for c in client.get_collections().collections}
    if COLLECTION_MEDICATIONS not in names:
        client.create_collection(
            collection_name=COLLECTION_MEDICATIONS,
            vectors_config=VectorParams(size=VECTOR_SIZE, distance=Distance.COSINE),
        )


def reset_medications_collection(client: QdrantClient) -> None:
    names = {c.name for c in client.get_collections().collections}
    if COLLECTION_MEDICATIONS in names:
        client.delete_collection(collection_name=COLLECTION_MEDICATIONS)
    client.create_collection(
        collection_name=COLLECTION_MEDICATIONS,
        vectors_config=VectorParams(size=VECTOR_SIZE, distance=Distance.COSINE),
    )


def _qdrant_timeout_seconds() -> int:
    raw = (os.environ.get("QDRANT_TIMEOUT") or "").strip()
    if raw:
        try:
            return max(30, int(raw))
        except ValueError:
            pass
    return 300


def _create_qdrant_client() -> QdrantClient:
    url = (os.environ.get("QDRANT_URL") or "").strip()
    timeout = _qdrant_timeout_seconds()
    if url:
        api_key = (os.environ.get("QDRANT_API_KEY") or "").strip() or None
        return QdrantClient(url=url, api_key=api_key, timeout=timeout)
    persist_directory = os.path.join(os.getcwd(), "storage", "qdrant")
    os.makedirs(persist_directory, exist_ok=True)
    return QdrantClient(path=persist_directory, timeout=timeout)


def init_qdrant() -> QdrantClient:
    global _client
    _client = _create_qdrant_client()
    _ensure_medications_collection(_client)
    return _client


def get_qdrant_client() -> QdrantClient:
    if _client is None:
        return init_qdrant()
    return _client


def _prepare_query_text(raw: str) -> str:
    text = (raw or "").strip()
    if not text:
        return text
    return BGE_QUERY_PREFIX + text


def _encode_query(raw: str) -> list[float]:
    text = _prepare_query_text(raw)
    if not text:
        return []
    model = _get_model()
    vec = model.encode(text, normalize_embeddings=True)
    return vec.tolist()


def encode_document_text(raw: str) -> list[float]:
    text = (raw or "").strip()
    if not text:
        return []
    model = _get_model()
    vec = model.encode(BGE_DOCUMENT_PREFIX + text, normalize_embeddings=True)
    return vec.tolist()


def query_medications(query_text: str, n_results: int = 5) -> list[tuple[str, dict]]:
    client = get_qdrant_client()
    vector = _encode_query(query_text)
    if not vector:
        return []

    results = client.search(
        collection_name=COLLECTION_MEDICATIONS,
        query_vector=vector,
        limit=n_results,
        with_payload=True,
    )

    matches: list[tuple[str, dict]] = []
    for hit in results:
        payload = hit.payload if isinstance(hit.payload, dict) else {}
        doc = (
            payload.get("text")
            or payload.get("document")
            or ""
        )
        matches.append((doc, payload))

    return matches
