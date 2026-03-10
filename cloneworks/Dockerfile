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

# Install FreeTXL 10.8b (required by CloneWorks for source parsing)
RUN cd /tmp \
 && curl -sL -X POST "https://www.txl.ca/cgi-bin/txl-download.cgi" \
      -d "Platform=linux64&Submit=I+Agree" \
      -o response.html \
 && TXL_URL=$(grep -oP "HREF='\K[^']+\.tar\.gz" response.html | head -1) \
 && curl -sL -o txl.tar.gz "https://www.txl.ca/${TXL_URL}" \
 && tar xzf txl.tar.gz \
 && cd txl10.8b.linux64 \
 && cp bin/* /usr/local/bin/ \
 && mkdir -p /usr/local/lib/txl \
 && cp lib/* /usr/local/lib/txl/ \
 && mkdir -p /usr/local/share/man/man1 \
 && cp man/man1/* /usr/local/share/man/man1/ 2>/dev/null || true \
 && ldconfig \
 && cd / && rm -rf /tmp/txl* /tmp/response.html

RUN pip3 install --no-cache-dir datasets pandas numpy scikit-learn tqdm

# Set UTF-8 encoding for Java (prevents compilation errors on non-ASCII comments)
ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

# Clone the official CloneWorks artifact into the image
RUN git clone https://github.com/jeffsvajlenko/CloneWorks.git /opt/cloneworks_artifact

RUN useradd -ms /bin/bash appuser
USER appuser
WORKDIR /workspace

COPY --chown=appuser:appuser . /workspace

# Copy the pre-cloned artifact into the workspace (if not already present from COPY)
RUN mkdir -p /workspace/tools && \
    if [ ! -d /workspace/tools/cloneworks_artifact/src ]; then \
      rm -rf /workspace/tools/cloneworks_artifact && \
      cp -a /opt/cloneworks_artifact /workspace/tools/cloneworks_artifact; \
    fi

RUN chmod +x /workspace/docker/entrypoint.sh \
 && chmod +x /workspace/scripts/*.sh || true

ENTRYPOINT ["/workspace/docker/entrypoint.sh"]
CMD ["bash", "scripts/run_full_pipeline.sh"]