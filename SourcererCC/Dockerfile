FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    python3 \
    python3-pip \
    git \
    ant \
    zip \
    python-is-python3 \
    dos2unix \
    build-essential

WORKDIR /workspace

COPY . /workspace
