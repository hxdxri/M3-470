FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN rm -rf /var/lib/apt/lists/* \
 && apt-get clean \
 && apt-get update -o Acquire::Retries=5 \
 && apt-get install -y --no-install-recommends -o Acquire::Retries=5 \
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
    g++ \
    make \
    flex \
    bison \
    libboost-all-dev \
    file \
 && rm -rf /var/lib/apt/lists/*

# Install FreeTXL (needed by CCAligner extraction pipeline)
RUN cd /tmp \
 && curl -sL -X POST "https://www.txl.ca/cgi-bin/txl-download.cgi" \
      -d "Platform=linux64&Submit=I+Agree" \
      -o response.html \
 && TXL_URL=$(grep -oP "HREF='\\K[^']+\\.tar\\.gz" response.html | head -1) \
 && curl -sL -o txl.tar.gz "https://www.txl.ca/${TXL_URL}" \
 && tar xzf txl.tar.gz \
 && cd txl10.8b.linux64 \
 && cp bin/* /usr/local/bin/ \
 && mkdir -p /usr/local/lib/txl \
 && cp lib/* /usr/local/lib/txl/ \
 && ldconfig \
 && cd / && rm -rf /tmp/txl* /tmp/response.html

RUN pip3 install --no-cache-dir datasets pandas numpy scikit-learn tqdm

RUN useradd -ms /bin/bash appuser
USER appuser
WORKDIR /workspace

COPY --chown=appuser:appuser . /workspace

RUN chmod +x /workspace/docker/entrypoint.sh \
 && chmod +x /workspace/scripts/*.sh || true

ENTRYPOINT ["/workspace/docker/entrypoint.sh"]
CMD ["bash", "scripts/run_full_pipeline.sh"]
