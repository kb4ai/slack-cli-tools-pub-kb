# Multi-stage build for bcicen/slackcat
# A CLI tool to pipe content to Slack channels

FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git
WORKDIR /build
RUN git clone --depth 1 https://github.com/bcicen/slackcat.git .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o slackcat .

FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=builder /build/slackcat /usr/local/bin/
ENTRYPOINT ["slackcat"]
CMD ["--help"]
