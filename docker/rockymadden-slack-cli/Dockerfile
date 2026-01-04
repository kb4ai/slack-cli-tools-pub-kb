FROM alpine:3.19
RUN apk add --no-cache bash curl jq git
WORKDIR /app
RUN git clone --depth 1 https://github.com/rockymadden/slack-cli.git . && \
    chmod +x src/slack && \
    ln -s /app/src/slack /usr/local/bin/slack
ENTRYPOINT ["slack"]
CMD ["--help"]
