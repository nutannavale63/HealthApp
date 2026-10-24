#!/bin/bash

# BBHealthApp - Webhook Test Script
# This script tests webhooks by simulating a GitHub push event

set -e

# Configuration
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-}"
GITHUB_REPO="${GITHUB_REPO:-Ishikapbhatt/healthapp-aws}"
BRANCH="${BRANCH:-main}"

echo "========================================="
echo "Webhook Test for BBHealthApp"
echo "========================================="
echo "Jenkins URL: ${JENKINS_URL}"
echo "Repository: ${GITHUB_REPO}"
echo "Branch: ${BRANCH}"
echo "========================================="

# Generate test payload
PAYLOAD=$(cat <<EOF
{
  "ref": "refs/heads/${BRANCH}",
  "repository": {
    "name": "healthapp-aws",
    "full_name": "${GITHUB_REPO}",
    "owner": {
      "name": "Ishikapbhatt",
      "email": "ishika@example.com"
    },
    "private": false,
    "html_url": "https://github.com/${GITHUB_REPO}"
  },
  "pusher": {
    "name": "test-user",
    "email": "test@example.com"
  },
  "sender": {
    "login": "test-user",
    "id": 123456789
  },
  "head_commit": {
    "id": "$(git rev-parse HEAD)",
    "message": "Test webhook trigger",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "url": "https://github.com/${GITHUB_REPO}/commit/$(git rev-parse HEAD)"
  }
}
EOF
)

echo "Test payload:"
echo "$PAYLOAD" | jq .

# Calculate signature if secret is provided
if [ -n "$WEBHOOK_SECRET" ]; then
    SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')
    echo "X-Hub-Signature-256: sha256=${SIGNATURE}"
    echo ""
fi

# Send webhook
echo "Sending webhook to Jenkins..."
RESPONSE=$(curl -X POST "${JENKINS_URL}/github-webhook/" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -H "X-Hub-Signature-256: sha256=${SIGNATURE}" \
  -d "$PAYLOAD" \
  -w "\n%{http_code}" \
  -s)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status Code: $HTTP_CODE"
echo "Response Body:"
echo "$BODY"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
    echo ""
    echo "✅ Webhook sent successfully!"
    echo "Check Jenkins for triggered build"
else
    echo ""
    echo "❌ Webhook failed with status code: $HTTP_CODE"
    exit 1
fi

echo "========================================="
