FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    curl \
    unzip \
    ant \
    build-essential \
    zip \
    python-is-python3 \
    dos2unix \
    python3 \
    python3-pip \
    openjdk-11-jdk \
    bash \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . /workspace

RUN find /workspace -type f -name "*.sh" -exec dos2unix {} \; \
 && find /workspace -type f -name "*.sh" -exec chmod +x {} \;

RUN pip3 install --no-cache-dir \
  "datasets==2.19.1" \
  "huggingface_hub==0.23.4" \
  "pyarrow==16.1.0"

ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
