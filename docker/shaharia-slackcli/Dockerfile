FROM oven/bun:alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
RUN git clone --depth 1 https://github.com/shaharia-lab/slackcli.git .
RUN bun install && bun run build

FROM oven/bun:alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json .
ENTRYPOINT ["bun", "run", "dist/index.js"]
CMD ["--help"]
