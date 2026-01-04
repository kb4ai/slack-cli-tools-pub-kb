# Multi-stage build for rusq/slackdump
# https://github.com/rusq/slackdump

FROM golang:1.24-alpine AS builder
RUN apk add --no-cache git
WORKDIR /build
RUN git clone --depth 1 https://github.com/rusq/slackdump.git .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o slackdump ./cmd/slackdump

FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=builder /build/slackdump /usr/local/bin/
ENTRYPOINT ["slackdump"]
CMD ["--help"]
