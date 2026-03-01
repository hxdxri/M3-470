### DRAFT


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
