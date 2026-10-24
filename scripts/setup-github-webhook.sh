#!/bin/bash

# BBHealthApp - GitHub Webhook Setup Script
# This script automates the setup of GitHub webhooks to trigger Jenkins builds

set -e

# Configuration
GITHUB_REPO_OWNER="${GITHUB_REPO_OWNER:-Ishikapbhatt}"
GITHUB_REPO_NAME="${GITHUB_REPO_NAME:-healthapp-aws}"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_JOB_NAME="${JENKINS_JOB_NAME:-bbhealthapp-cicd-pipeline}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-$(openssl rand -hex 32)}"

echo "========================================="
echo "GitHub Webhook Setup for BBHealthApp"
echo "========================================="
echo "Repository: ${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}"
echo "Jenkins URL: ${JENKINS_URL}"
echo "Job Name: ${JENKINS_JOB_NAME}"
echo "========================================="

# Check for GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    echo "Create a personal access token at: https://github.com/settings/tokens"
    echo "Required scopes: repo, admin:repo_hook"
    exit 1
fi

# Check for GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI not found. Installing..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y gh
        else
            echo "Please install GitHub CLI manually"
            exit 1
        fi
    fi
fi

# Authenticate with GitHub
echo "Authenticating with GitHub..."
echo "$GITHUB_TOKEN" | gh auth login --with-token

# Create webhook payload
WEBHOOK_URL="${JENKINS_URL}/github-webhook/"

echo "Creating webhook..."
echo "Webhook URL: ${WEBHOOK_URL}"
echo "Webhook Secret: ${WEBHOOK_SECRET}"

# Create webhook using GitHub API
gh api \
  --method POST \
  -H "Accept: application/vnd.github.v3+json" \
  "/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/hooks" \
  -f name="web" \
  -f active=true \
  -f events='["push"]' \
  -f config="{
    \"url\": \"${WEBHOOK_URL}\",
    \"content_type\": \"json\",
    \"secret\": \"${WEBHOOK_SECRET}\",
    \"insecure_ssl\": \"0\"
  }"

echo "========================================="
echo "Webhook created successfully!"
echo "========================================="
echo "Webhook URL: ${WEBHOOK_URL}"
echo "Webhook Secret: ${WEBHOOK_SECRET}"
echo ""
echo "Add this secret to Jenkins:"
echo "1. Go to Jenkins job configuration"
echo "2. Add 'Secret Text' credential with ID: github-webhook-secret"
echo "3. Paste the secret: ${WEBHOOK_SECRET}"
echo ""
echo "Or set as environment variable in Jenkinsfile:"
echo "WEBHOOK_SECRET=${WEBHOOK_SECRET}"
echo "========================================="

# List webhooks
echo ""
echo "Current webhooks:"
gh api "/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/hooks"

echo ""
echo "Test the webhook by pushing to the repository"
