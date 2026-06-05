FROM python:3.12-slim

ARG SKILLSPECTOR_REF=main

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        build-essential \
        libssl-dev \
        libmagic1 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "git+https://github.com/NVIDIA/SkillSpector.git@${SKILLSPECTOR_REF}"

WORKDIR /scan

ENTRYPOINT ["skillspector"]
CMD ["--help"]
