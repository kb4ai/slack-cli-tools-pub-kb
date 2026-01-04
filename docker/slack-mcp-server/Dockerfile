FROM node:20-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
RUN git clone --depth 1 https://github.com/korotovsky/slack-mcp-server.git .
RUN npm ci && npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json .
ENTRYPOINT ["node", "dist/index.js"]
CMD ["--help"]
