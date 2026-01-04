# slack-libpurple Docker Setup

This directory contains a Docker setup for building [dylex/slack-libpurple](https://github.com/dylex/slack-libpurple).

## Important Note

**This is a libpurple PLUGIN, NOT a standalone CLI tool.**

slack-libpurple is a plugin that adds Slack protocol support to libpurple-based clients like:

* **Pidgin** - GTK-based graphical IM client
* **Finch** - ncurses-based text UI client (included in this image)

The plugin (`libslack.so`) must be loaded by one of these clients to function. There is no standalone command-line interface.

## Files

* `Dockerfile` - Multi-stage build: compiles the plugin from source, then creates a minimal runtime image with Finch
* `manage.sh` - Management script for building, testing, and cleaning up Docker artifacts

## Usage

```bash
# Build the Docker image
./manage.sh build

# Test that the plugin compiled successfully
./manage.sh test

# Start an interactive Finch session
./manage.sh run

# Get a shell inside the container
./manage.sh shell

# Clean up Docker artifacts
./manage.sh clean
```

## Configuration

To use Slack with Finch, you need to:

1. Run the container interactively: `./manage.sh run`
2. Configure a new Slack account within Finch
3. Provide your Slack workspace credentials

Note: For persistent configuration, you may want to mount a volume for `~/.purple/`.

## Verification

The `test` command verifies that `libslack.so` was successfully compiled and installed in `/usr/lib/purple-2/`.
