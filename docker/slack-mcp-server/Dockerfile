# =============================================================================
# Slack MCP Server Docker Setup with CLI Access via mcptools
# =============================================================================
#
# This Dockerfile builds the korotovsky/slack-mcp-server (Go) and includes
# f/mcptools (https://github.com/f/mcptools) for CLI access to the MCP server.
#
# WHY mcptools?
# -------------
# mcptools provides a universal CLI interface to ANY MCP server. Instead of
# building custom CLI wrappers for each MCP server, mcptools acts as a
# "Swiss Army Knife" that can:
#   - List available tools: mcp tools <server-command>
#   - Call tools with params: mcp call <tool> --params '{}' <server-command>
#   - Interactive shell: mcp shell <server-command>
#   - Web interface: mcp web <server-command>
#
# This approach means:
#   1. One CLI tool works with ALL MCP servers (Slack, GitHub, filesystem, etc.)
#   2. No need to write/maintain server-specific CLI wrappers
#   3. Consistent interface across different MCP implementations
#   4. Easy debugging and exploration of MCP server capabilities
#
# =============================================================================

# Stage 1: Build both slack-mcp-server and mcptools from Go source
FROM golang:1.24-alpine AS builder

ENV CGO_ENABLED=0
ENV GOTOOLCHAIN=local

RUN apk add --no-cache git

WORKDIR /build

# Clone and build slack-mcp-server
RUN git clone --depth 1 https://github.com/korotovsky/slack-mcp-server.git slack-mcp-server
WORKDIR /build/slack-mcp-server
RUN go build -ldflags="-s -w" -o /go/bin/slack-mcp-server ./cmd/slack-mcp-server

# Install mcptools - the CLI Swiss Army Knife for MCP servers
# See: https://github.com/f/mcptools
RUN go install github.com/f/mcptools/cmd/mcptools@latest

# Stage 2: Final minimal runtime image
FROM alpine:3.22

RUN apk add --no-cache ca-certificates

# Copy binaries
COPY --from=builder /go/bin/slack-mcp-server /usr/local/bin/slack-mcp-server
COPY --from=builder /go/bin/mcptools /usr/local/bin/mcptools
# Create 'mcp' alias for convenience (matches homebrew installation naming)
RUN ln -s /usr/local/bin/mcptools /usr/local/bin/mcp

# Create directory for helper scripts
RUN mkdir -p /app/scripts
WORKDIR /app

# Copy helper scripts (WIP - to be tested)
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh 2>/dev/null || true

# Default entrypoint runs the MCP server in stdio mode
ENTRYPOINT ["slack-mcp-server"]
CMD ["--help"]
