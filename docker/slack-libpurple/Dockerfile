FROM debian:bookworm-slim AS builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential pkg-config \
    libpurple-dev libglib2.0-dev libjson-glib-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN git clone --depth 1 https://github.com/dylex/slack-libpurple.git .
RUN make

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpurple0 libglib2.0-0 libjson-glib-1.0-0 finch \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/libslack.so /usr/lib/purple-2/
# Note: This is a Pidgin/Finch plugin, not standalone CLI
ENTRYPOINT ["finch"]
CMD ["--help"]
