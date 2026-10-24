#!/bin/bash

# BBHealthApp - Monitoring and Metrics Setup Script
# This script sets up monitoring for Jenkins and the deployed application

set -e

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-bbhealthapp-cluster}"
NAMESPACE="${NAMESPACE:-bbhealthapp}"
AWS_REGION="${AWS_REGION:-us-west-2}"

echo "========================================="
echo "Monitoring Setup for BBHealthApp"
echo "========================================="
echo "Cluster: ${CLUSTER_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Region: ${AWS_REGION}"
echo "========================================="

# Install kubectl monitoring plugins
echo "Installing kubectl plugins..."
if ! command -v kubectl-krew &> /dev/null; then
    echo "Installing krew..."
    (
      set -x; cd "$(mktemp -d)" &&
      curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz" &&
      tar zxvf krew-linux_amd64.tar.gz &&
      ./krew-linux_amd64 install krew
    )
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
fi

# Install monitoring tools
echo "Installing monitoring tools..."

# Install kube-state-metrics (if not installed)
echo "Checking for kube-state-metrics..."
if ! kubectl get deployment -n kube-system kube-state-metrics &> /dev/null; then
    echo "Installing kube-state-metrics..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/kube-state-metrics/master/examples/standard/cluster-role-binding.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/kube-state-metrics/master/examples/standard/cluster-role.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/kube-state-metrics/master/examples/standard/deployment.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/kube-state-metrics/master/examples/standard/service.yaml
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/kube-state-metrics/master/examples/standard/serviceaccount.yaml
fi

# Create monitoring namespace
echo "Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus (optional - requires Helm)
if command -v helm &> /dev/null; then
    echo "Checking for Prometheus..."
    if ! helm list -n monitoring | grep -q prometheus; then
        echo "Installing Prometheus with Helm..."
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
    fi
fi

# Install metrics-server (if not installed)
echo "Checking for metrics-server..."
if ! kubectl get deployment -n kube-system metrics-server &> /dev/null; then
    echo "Installing metrics-server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
fi

# Create custom monitoring scripts
cat > monitor-deployment.sh <<'EOF'
#!/bin/bash

# BBHealthApp - Deployment Monitoring Script
# This script monitors the deployment status

CLUSTER_NAME="${CLUSTER_NAME:-bbhealthapp-cluster}"
NAMESPACE="${NAMESPACE:-bbhealthapp}"
HELM_RELEASE="${HELM_RELEASE:-bbhealthapp}"

echo "========================================="
echo "Deployment Monitoring - BBHealthApp"
echo "========================================="
echo "Cluster: ${CLUSTER_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Release: ${HELM_RELEASE}"
echo "========================================="

# Update kubeconfig
aws eks update-kubeconfig --name ${CLUSTER_NAME} --region us-west-2

# Check pod status
echo ""
echo "📊 Pod Status:"
kubectl get pods -n ${NAMESPACE} -o wide

# Check service status
echo ""
echo "🌐 Service Status:"
kubectl get services -n ${NAMESPACE}

# Check ingress status
echo ""
echo "🔀 Ingress Status:"
kubectl get ingress -n ${NAMESPACE}

# Check Helm release status
echo ""
echo "📦 Helm Release Status:"
helm status ${HELM_RELEASE} -n ${NAMESPACE}

# Check resource usage
echo ""
echo "💾 Resource Usage:"
kubectl top pods -n ${NAMESPACE} --containers=true

# Check events
echo ""
echo "📋 Recent Events:"
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | tail -20

# Check logs for any pod with errors
echo ""
echo "❌ Pods with Errors:"
kubectl get pods -n ${NAMESPACE} -o json | jq -r '.items[] | select(.status.phase=="Failed" or .status.containerStatuses[].state.waiting.reason=="CrashLoopBackOff") | .metadata.name'

echo ""
echo "========================================="
echo "Monitoring complete!"
echo "========================================="
EOF

chmod +x monitor-deployment.sh

# Create health check script
cat > health-check.sh <<'EOF'
#!/bin/bash

# BBHealthApp - Health Check Script
# This script performs health checks on the application

NAMESPACE="${NAMESPACE:-bbhealthapp}"
HELM_RELEASE="${HELM_RELEASE:-bbhealthapp}"

echo "========================================="
echo "Health Check - BBHealthApp"
echo "========================================="

# Get Load Balancer URL
LB_URL=$(kubectl get ingress -n ${NAMESPACE} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$LB_URL" ]; then
    echo "⚠️  Load Balancer URL not found"
    exit 1
fi

echo "Load Balancer URL: http://${LB_URL}"
echo ""

# Test frontend
echo "Testing Frontend..."
if curl -f -s -o /dev/null -w "Status: %{http_code}\n" http://${LB_URL}/; then
    echo "✅ Frontend is healthy"
else
    echo "❌ Frontend health check failed"
fi

# Test master service
echo ""
echo "Testing Master Service..."
if curl -f -s -o /dev/null -w "Status: %{http_code}\n" http://${LB_URL}/api/master/actuator/health; then
    echo "✅ Master Service is healthy"
else
    echo "❌ Master Service health check failed"
fi

# Test register service
echo ""
echo "Testing Register Service..."
if curl -f -s -o /dev/null -w "Status: %{http_code}\n" http://${LB_URL}/api/register/actuator/health; then
    echo "✅ Register Service is healthy"
else
    echo "❌ Register Service health check failed"
fi

# Test document service
echo ""
echo "Testing Document Service..."
if curl -f -s -o /dev/null -w "Status: %{http_code}\n" http://${LB_URL}/api/document/actuator/health; then
    echo "✅ Document Service is healthy"
else
    echo "❌ Document Service health check failed"
fi

echo ""
echo "========================================="
echo "Health check complete!"
echo "========================================="
EOF

chmod +x health-check.sh

# Create alerting rules
cat > prometheus-alerts.yaml <<'EOF'
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: bbhealthapp-alerts
  namespace: monitoring
  labels:
    release: prometheus
spec:
  groups:
    - name: bbhealthapp.rules
      rules:
        - alert: HighPodRestartCount
          expr: rate(kube_pod_container_status_restarts_total[1h]) > 0.5
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High pod restart count"
            description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has high restart count"

        - alert: PodNotReady
          expr: kube_pod_status_ready{namespace="bbhealthapp"} == 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Pod not ready"
            description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is not ready"

        - alert: HighMemoryUsage
          expr: container_memory_usage_bytes{namespace="bbhealthapp"} / container_spec_memory_limit_bytes{namespace="bbhealthapp"} > 0.9
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High memory usage"
            description: "Container {{ $labels.container }} in pod {{ $labels.pod }} is using more than 90% memory"

        - alert: HighCPUUsage
          expr: rate(container_cpu_usage_seconds_total{namespace="bbhealthapp"}[5m]) > 0.8
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High CPU usage"
            description: "Container {{ $labels.container }} in pod {{ $labels.pod }} is using more than 80% CPU"
EOF

echo "Creating alerting rules..."
kubectl apply -f prometheus-alerts.yaml --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "========================================="
echo "Monitoring setup complete!"
echo "========================================="
echo ""
echo "Created scripts:"
echo "  - monitor-deployment.sh: Monitor deployment status"
echo "  - health-check.sh: Perform health checks"
echo "  - prometheus-alerts.yaml: Prometheus alerting rules"
echo ""
echo "To monitor deployment:"
echo "  ./monitor-deployment.sh"
echo ""
echo "To perform health checks:"
echo "  ./health-check.sh"
echo ""
echo "========================================="
