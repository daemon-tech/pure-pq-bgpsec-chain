# Dockerfile for Pure Post-Quantum BGPsec Chain
# Author: Sam Moes
# Date: December 2024

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    ninja-build \
    build-essential \
    libssl-dev \
    python3 \
    python3-pip \
    rpki-client \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Build and install liboqs
RUN cd /tmp && \
    git clone --depth=1 https://github.com/open-quantum-safe/liboqs.git && \
    cd liboqs && \
    mkdir build && cd build && \
    cmake -GNinja -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    ninja && \
    ninja install && \
    cd / && rm -rf /tmp/liboqs && \
    ldconfig

# Set library paths
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Note: oqs-provider will be built separately or mounted from host
# For now, we assume it's built externally or will be built in the container
# If building in container, uncomment the next section:

# WORKDIR /tmp
# RUN git clone --depth=1 https://github.com/open-quantum-safe/oqs-provider.git oqs-provider && \
#     cd oqs-provider && \
#     mkdir build && cd build && \
#     cmake -GNinja .. && \
#     ninja && \
#     ninja install && \
#     cd / && rm -rf /tmp/oqs-provider

WORKDIR /work

# Copy scripts
COPY *.sh *.py ./
RUN chmod +x *.sh 2>/dev/null || true

# Set default command
CMD ["bash"]

