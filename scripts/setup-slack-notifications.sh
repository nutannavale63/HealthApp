#!/bin/bash

# BBHealthApp - Slack Notification Setup Script
# This script sets up Slack notifications for Jenkins builds

set -e

# Configuration
SLACK_WORKSPACE="${SLACK_WORKSPACE:-}"
SLACK_CHANNEL="${SLACK_CHANNEL:-#devops}"
SLACK_TOKEN="${SLACK_TOKEN:-}"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"

echo "========================================="
echo "Slack Notification Setup for BBHealthApp"
echo "========================================="
echo "Slack Workspace: ${SLACK_WORKSPACE}"
echo "Slack Channel: ${SLACK_CHANNEL}"
echo "Jenkins URL: ${JENKINS_URL}"
echo "========================================="

# Check for Slack token
if [ -z "$SLACK_TOKEN" ]; then
    echo "Error: SLACK_TOKEN environment variable is required"
    echo "Create a Slack token at: https://api.slack.com/apps"
    echo "Required scopes: chat:write, channels:read"
    exit 1
fi

# Check for Slack workspace
if [ -z "$SLACK_WORKSPACE" ]; then
    echo "Error: SLACK_WORKSPACE environment variable is required"
    echo "Example: your-workspace-name"
    exit 1
fi

# Test Slack connection
echo "Testing Slack connection..."
curl -X POST "https://slack.com/api/chat.postMessage" \
  -H "Authorization: Bearer ${SLACK_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"channel\": \"${SLACK_CHANNEL}\",
    \"text\": \"🚀 Jenkins Slack notifications setup initiated for BBHealthApp\"
  }"

echo ""
echo "========================================="
echo "Slack connection successful!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Install Slack Notification plugin in Jenkins"
echo "   - Go to Manage Jenkins → Plugins → Available"
echo "   - Search for 'Slack Notification Plugin'"
echo "   - Install and restart Jenkins"
echo ""
echo "2. Configure Slack in Jenkins"
echo "   - Go to Manage Jenkins → Configure System"
echo "   - Scroll to Slack section"
echo "   - Workspace: ${SLACK_WORKSPACE}"
echo "   - Credential: Add 'Secret Text' credential with your token"
echo "   - Default Channel: ${SLACK_CHANNEL}"
echo "   - Click Test Connection"
echo "   - Save configuration"
echo ""
echo "3. Add notifications to Jenkinsfile"
echo "   Add the following to the post section:"
echo ""
echo "   post {"
echo "       success {"
echo "           slackSend("
echo "               color: 'good',"
echo "               message: \"✅ Deployment successful: \${env.JOB_NAME} - \${env.BUILD_NUMBER}\""
echo "           )"
echo "       }"
echo "       failure {"
echo "           slackSend("
echo "               color: 'danger',"
echo "               message: \"❌ Deployment failed: \${env.JOB_NAME} - \${env.BUILD_NUMBER}\""
echo "           )"
echo "       }"
echo "   }"
echo ""
echo "========================================="

# Create a sample notification configuration file
cat > slack-notification-config.json <<EOF
{
  "workspace": "${SLACK_WORKSPACE}",
  "channel": "${SLACK_CHANNEL}",
  "token": "${SLACK_TOKEN}",
  "jenkins_url": "${JENKINS_URL}",
  "notifications": {
    "success": {
      "color": "good",
      "emoji": "✅",
      "message": "Deployment successful"
    },
    "failure": {
      "color": "danger",
      "emoji": "❌",
      "message": "Deployment failed"
    },
    "started": {
      "color": "#36a64f",
      "emoji": "🚀",
      "message": "Deployment started"
    },
    "aborted": {
      "color": "warning",
      "emoji": "⚠️",
      "message": "Deployment aborted"
    }
  }
}
EOF

echo "Slack configuration saved to: slack-notification-config.json"
echo "⚠️  Keep this file secure and do not commit to Git!"
echo "========================================="
