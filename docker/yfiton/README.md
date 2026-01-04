# yfiton Docker Setup

**STATUS: ABANDONED** - Last commit 2017. Build may fail due to outdated dependencies.

## Overview

[yfiton](https://github.com/yfiton/yfiton) is a multi-service notification tool written in Java. It supports sending notifications to various services including:

* Slack
* Email (SMTP)
* Pushbullet
* Pushover
* Telegram
* Twitter
* Facebook
* And more

**Note:** Slack is just one of many supported notification services. This tool is included in this collection for completeness but is not Slack-specific.

## Usage

```bash
# Build the Docker image
./manage.sh build

# Run yfiton with help
./manage.sh run --help

# Run yfiton with custom arguments
./manage.sh run slack --token YOUR_TOKEN --channel general --message "Hello"

# Test the setup
./manage.sh test
```

## Management Commands

```bash
./manage.sh status   # Check image/container status
./manage.sh build    # Build Docker image
./manage.sh start    # Start container
./manage.sh stop     # Stop container
./manage.sh shell    # Open shell in container
./manage.sh run      # Run yfiton with arguments
./manage.sh test     # Run basic tests
./manage.sh verify   # Verify installation
./manage.sh clean    # Remove image and container
./manage.sh logs     # View container logs
```

## Known Issues

* Project is abandoned since 2017
* Dependencies may be outdated and incompatible with modern Java
* Build may fail due to Gradle/dependency resolution issues
* Some notification services may have changed their APIs

## References

* GitHub: https://github.com/yfiton/yfiton
* Documentation: https://yfiton.github.io/ (may be offline)
