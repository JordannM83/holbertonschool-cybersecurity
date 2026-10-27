# syntax=docker/dockerfile:1

FROM python:3.11-slim

LABEL org.opencontainers.image.title="DevStream Secure Python Development" \
      org.opencontainers.image.description="Minimal non-root Python 3.11 development environment" \
      org.opencontainers.image.vendor="DevStream" \
      org.opencontainers.image.version="1.0" \
      org.opencontainers.image.source="holbertonschool-cybersecurity"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

# Install only the runtime utility required by the HTTP health check.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 devuser \
    && useradd --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin devuser \
    && python -m venv "$VIRTUAL_ENV" \
    && "$VIRTUAL_ENV/bin/pip" install --no-cache-dir \
        black \
        Flask \
        mypy \
        pylint \
        pytest \
    && rm -rf /root/.cache

WORKDIR /app

# Copy only application sources; credentials must be supplied at runtime.
COPY --chown=devuser:devuser app.py requirements.txt ./
RUN "$VIRTUAL_ENV/bin/pip" install --no-cache-dir -r requirements.txt \
    && rm -rf /root/.cache

USER devuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD-SHELL curl -fsS http://localhost:5000/health || exit 1

CMD ["python", "app.py"]
