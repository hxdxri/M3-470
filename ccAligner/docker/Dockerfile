FROM amazoncorretto:17

RUN yum -y update \
 && yum -y install \
    ca-certificates \
    git \
    curl \
    wget \
    unzip \
    tar \
    jq \
    python3 \
    python3-devel \
    python3-pip \
    gcc \
    gcc-c++ \
    make \
    flex \
    bison \
    boost-devel \
    file \
 && yum clean all \
 && rm -rf /var/cache/yum

RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install datasets==2.13.2 pyarrow==12.0.1 multiprocess==0.70.14 dill==0.3.6 requests==2.28.2

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

RUN useradd -ms /bin/bash appuser
USER appuser
WORKDIR /workspace

COPY --chown=appuser:appuser . /workspace

RUN chmod +x /workspace/docker/entrypoint.sh \
 && chmod +x /workspace/scripts/*.sh || true

RUN python3 -m pip install --no-cache-dir datasets==2.13.2 pyarrow==12.0.1 multiprocess==0.70.14 dill==0.3.6 requests==2.28.2

ENTRYPOINT ["/workspace/docker/entrypoint.sh"]
CMD ["bash", "scripts/run_full_pipeline.sh"]
