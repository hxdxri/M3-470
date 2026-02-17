FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    wget \
    unzip \
    jq \
    python3 \
    python3-pip \
    openjdk-11-jdk \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir datasets pandas numpy scikit-learn tqdm

RUN useradd -ms /bin/bash appuser
USER appuser
WORKDIR /workspace

COPY --chown=appuser:appuser . /workspace

RUN chmod +x /workspace/docker/entrypoint.sh \
 && chmod +x /workspace/scripts/*.sh || true

ENTRYPOINT ["/workspace/docker/entrypoint.sh"]