#!/bin/bash

# BBHealthApp - GitLab Webhook Setup Script
# This script automates the setup of GitLab webhooks to trigger Jenkins builds

set -e

# Configuration
GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"
GITLAB_PROJECT_ID="${GITLAB_PROJECT_ID:-}"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_JOB_NAME="${JENKINS_JOB_NAME:-bbhealthapp-cicd-pipeline}"
GITLAB_TOKEN="${GITLAB_TOKEN:-}"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-$(openssl rand -hex 32)}"

echo "========================================="
echo "GitLab Webhook Setup for BBHealthApp"
echo "========================================="
echo "GitLab URL: ${GITLAB_URL}"
echo "Project ID: ${GITLAB_PROJECT_ID}"
echo "Jenkins URL: ${JENKINS_URL}"
echo "Job Name: ${JENKINS_JOB_NAME}"
echo "========================================="

# Check for GitLab token
if [ -z "$GITLAB_TOKEN" ]; then
    echo "Error: GITLAB_TOKEN environment variable is required"
    echo "Create a personal access token at: ${GITLAB_URL}/profile/personal_access_tokens"
    echo "Required scopes: api, read_repository, read_api"
    exit 1
fi

# Check for Project ID
if [ -z "$GITLAB_PROJECT_ID" ]; then
    echo "Error: GITLAB_PROJECT_ID environment variable is required"
    echo "Find your project ID in the project settings or URL"
    exit 1
fi

# Create webhook payload
WEBHOOK_URL="${JENKINS_URL}/project/${JENKINS_JOB_NAME}"

echo "Creating webhook..."
echo "Webhook URL: ${WEBHOOK_URL}"
echo "Webhook Secret: ${WEBHOOK_SECRET}"

# Create webhook using GitLab API
curl -X POST "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/hooks" \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  --header "Content-Type: application/json" \
  --data "{
    \"url\": \"${WEBHOOK_URL}\",
    \"push_events\": true,
    \"merge_requests_events\": false,
    \"tag_push_events\": false,
    \"issues_events\": false,
    \"confidential_issues_events\": false,
    \"note_events\": false,
    \"confidential_note_events\": false,
    \"wiki_page_events\": false,
    \"pipeline_events\": false,
    \"wiki_page_events\": false,
    \"deployment_events\": false,
    \"releases_events\": false,
    \"job_events\": false,
    \"enable_ssl_verification\": true,
    \"token\": \"${WEBHOOK_SECRET}\"
  }"

echo ""
echo "========================================="
echo "Webhook created successfully!"
echo "========================================="
echo "Webhook URL: ${WEBHOOK_URL}"
echo "Webhook Secret: ${WEBHOOK_SECRET}"
echo ""
echo "Add this secret to Jenkins:"
echo "1. Go to Jenkins job configuration"
echo "2. Add 'Secret Text' credential with ID: gitlab-webhook-secret"
echo "3. Paste the secret: ${WEBHOOK_SECRET}"
echo ""
echo "Or set as environment variable in Jenkinsfile:"
echo "WEBHOOK_SECRET=${WEBHOOK_SECRET}"
echo "========================================="

# List webhooks
echo ""
echo "Current webhooks:"
curl -X GET "${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/hooks" \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}"

echo ""
echo "Test the webhook by pushing to the repository"
