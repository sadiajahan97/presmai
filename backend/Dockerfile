FROM python:3.12-slim-bookworm
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    libatomic1 \
    libgomp1 \
    openssl \
    && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir --extra-index-url https://download.pytorch.org/whl/cpu -r requirements.txt
COPY prisma ./prisma
RUN python -m prisma generate
COPY . .
CMD ["sh", "-c", "python -m prisma migrate deploy && uvicorn main:app --host 0.0.0.0 --port ${PORT}"]