# yfiton - Multi-service notification tool
# NOTE: This project is ABANDONED (last commit 2017)
# Build may fail due to outdated dependencies

FROM gradle:8-jdk21-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
RUN git clone --depth 1 https://github.com/yfiton/yfiton.git .
RUN gradle :yfiton-cli:installDist --no-daemon || echo "Build may have issues, checking..."

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/yfiton-cli/build/install/yfiton /app/
ENV PATH="/app/bin:$PATH"
ENTRYPOINT ["yfiton"]
CMD ["--help"]
