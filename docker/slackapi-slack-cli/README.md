# slackapi/slack-cli Docker Setup

This is the **OFFICIAL Slack CLI** for Slack app development.

**Important:** This CLI is designed for building and deploying Slack apps, not for daily messaging or workspace automation. It provides tools for:

* Creating new Slack apps from templates
* Deploying apps to Slack infrastructure
* Managing app manifests and configurations
* Running local development servers

## Usage

```bash
# Build the image
./manage.sh build

# Get help
./manage.sh run --help

# Run any slack CLI command
./manage.sh run <command> [args...]
```

## References

* [Slack CLI Documentation](https://api.slack.com/automation/cli)
* [GitHub: slackapi/slack-cli](https://github.com/slackapi/slack-cli)
