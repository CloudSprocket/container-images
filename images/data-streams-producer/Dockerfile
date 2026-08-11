# syntax=docker/dockerfile:1

# Python 3.14.7-slim verified on Docker Hub (2026-08-11).
FROM docker.io/library/python:3.14.7-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --no-compile -r requirements.txt

COPY produce.py .

RUN useradd --create-home --shell /bin/bash --uid 1000 appuser \
    && chown -R appuser:appuser /app

USER appuser

CMD ["python", "produce.py"]
