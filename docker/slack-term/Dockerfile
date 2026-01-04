# Multi-stage build for slack-term
# https://github.com/jpbruinsslot/slack-term

FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git

WORKDIR /build

RUN git clone --depth 1 https://github.com/jpbruinsslot/slack-term.git .

RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o slack-term .

FROM alpine:3.19

RUN apk add --no-cache ca-certificates

COPY --from=builder /build/slack-term /usr/local/bin/

ENTRYPOINT ["slack-term"]
CMD ["--help"]
