# BBHealthApp Helm Deployment Guide

This guide provides instructions for deploying the BBHealthApp using Helm charts.

## Prerequisites

- Kubernetes cluster (minikube, kind, EKS, GKE, etc.)
- kubectl installed and configured
- Helm 3.x installed
- Docker installed (for building images)

## Quick Start

### 1. Install Helm Chart

```bash
cd helm
helm install bbhealthapp ./bbhealthapp --namespace bbhealthapp --create-namespace
```

### 2. Using Deployment Script

```bash
chmod +x deploy-helm.sh
./deploy-helm.sh
```

### 3. With Custom Values

```bash
helm install bbhealthapp ./bbhealthapp \
  --namespace bbhealthapp \
  --create-namespace \
  --values bbhealthapp/values.yaml \
  --set image.registry=your-registry.com \
  --set image.tag=v1.0.0
```

## Configuration

### Values File

The `values.yaml` file contains all configurable parameters:

```yaml
# Global settings
global:
  namespace: bbhealthapp
  environment: dev
  imagePullPolicy: IfNotPresent

# Image configuration
image:
  registry: windsurf-project-3
  tag: latest

# Service configurations
masterService:
  enabled: true
  replicaCount: 2
  resources:
    requests:
      memory: 512Mi
      cpu: 500m
    limits:
      memory: 1Gi
      cpu: 1000m

# ... and more
```

### Environment-Specific Values

Create separate value files for different environments:

**values-dev.yaml**
```yaml
global:
  environment: dev

masterService:
  replicaCount: 2

autoscaling:
  enabled: false
```

**values-prod.yaml**
```yaml
global:
  environment: prod

masterService:
  replicaCount: 3

autoscaling:
  enabled: true
  masterService:
    minReplicas: 3
    maxReplicas: 10
```

Deploy with environment-specific values:

```bash
helm install bbhealthapp ./bbhealthapp \
  --namespace bbhealthapp \
  --values bbhealthapp/values-prod.yaml
```

## Deployment Options

### Local Development (minikube)

```bash
# Start minikube
minikube start

# Use minikube's Docker daemon
eval $(minikube docker-env)

# Build images
docker build -t windsurf-project-3/master-service:latest ../bbhealthapp-backend/bbhealthapp-api-master
docker build -t windsurf-project-3/register-service:latest ../bbhealthapp-backend/bbhealthapp-api-register
docker build -t windsurf-project-3/document-service:latest ../bbhealthapp-backend/bbhealthapp-api-document
docker build -t windsurf-project-3/frontend:latest ../bbhealthapp-frontend

# Deploy with Helm
helm install bbhealthapp ./bbhealthapp --namespace bbhealthapp --create-namespace

# Get URL
minikube service frontend -n bbhealthapp --url
```

### EKS Deployment

```bash
# Update kubeconfig
aws eks update-kubeconfig --name your-cluster-name --region us-west-2

# Build and push to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com

# Build and push images
docker build -t <account-id>.dkr.ecr.us-west-2.amazonaws.com/bbhealthapp-master-service:latest ../bbhealthapp-backend/bbhealthapp-api-master
docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/bbhealthapp-master-service:latest

# Deploy with EKS-specific values
helm install bbhealthapp ./bbhealthapp \
  --namespace bbhealthapp \
  --create-namespace \
  --set image.registry=<account-id>.dkr.ecr.us-west-2.amazonaws.com \
  --set eks.enabled=true
```

### Docker Registry Deployment

```bash
# Login to registry
docker login your-registry.com

# Build and tag images
docker build -t your-registry.com/bbhealthapp-master-service:latest ../bbhealthapp-backend/bbhealthapp-api-master
docker push your-registry.com/bbhealthapp-master-service:latest

# Deploy
helm install bbhealthapp ./bbhealthapp \
  --namespace bbhealthapp \
  --create-namespace \
  --set image.registry=your-registry.com
```

## Helm Commands

### Install

```bash
helm install bbhealthapp ./bbhealthapp --namespace bbhealthapp --create-namespace
```

### Upgrade

```bash
helm upgrade bbhealthapp ./bbhealthapp --namespace bbhealthapp
```

### Rollback

```bash
helm rollback bbhealthapp --namespace bbhealthapp
```

### Uninstall

```bash
helm uninstall bbhealthapp --namespace bbhealthapp
```

### List Releases

```bash
helm list --namespace bbhealthapp
```

### Get Release Status

```bash
helm status bbhealthapp --namespace bbhealthapp
```

### Get Values

```bash
helm get values bbhealthapp --namespace bbhealthapp
```

### Get Manifests

```bash
helm get manifest bbhealthapp --namespace bbhealthapp
```

### History

```bash
helm history bbhealthapp --namespace bbhealthapp
```

## Scaling

### Manual Scaling

```bash
# Scale master service to 5 replicas
kubectl scale deployment master-service --replicas=5 -n bbhealthapp
```

### Horizontal Pod Autoscaler

Enable autoscaling in values.yaml:

```yaml
autoscaling:
  enabled: true
  masterService:
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

Then upgrade:

```bash
helm upgrade bbhealthapp ./bbhealthapp --namespace bbhealthapp
```

## Ingress Configuration

### Default (nginx)

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: bbhealthapp.local
      paths:
        - path: /
          pathType: Prefix
          service: frontend
          port: 80
```

### EKS (ALB)

```yaml
ingress:
  enabled: true
eks:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
```

### SSL/TLS

```yaml
ingress:
  enabled: true
  tls:
    - secretName: bbhealthapp-tls
      hosts:
        - bbhealthapp.example.com
```

## Storage

### Default Storage

```yaml
masterService:
  persistence:
    enabled: true
    data:
      size: 10Gi
      storageClass: gp3
    uploads:
      size: 50Gi
      storageClass: gp3
```

### Disable Persistence

```yaml
masterService:
  persistence:
    enabled: false
```

## Monitoring

### Check Pods

```bash
kubectl get pods -n bbhealthapp
```

### Check Services

```bash
kubectl get svc -n bbhealthapp
```

### Check Ingress

```bash
kubectl get ingress -n bbhealthapp
```

### Check PVCs

```bash
kubectl get pvc -n bbhealthapp
```

### View Logs

```bash
# Master service
kubectl logs -f deployment/master-service -n bbhealthapp

# Register service
kubectl logs -f deployment/register-service -n bbhealthapp

# Document service
kubectl logs -f deployment/document-service -n bbhealthapp

# Frontend
kubectl logs -f deployment/frontend -n bbhealthapp
```

### Describe Resources

```bash
kubectl describe deployment master-service -n bbhealthapp
kubectl describe pod <pod-name> -n bbhealthapp
```

## Troubleshooting

### Helm Release Failed

```bash
# Check release status
helm status bbhealthapp -n bbhealthapp

# Check release history
helm history bbhealthapp -n bbhealthapp

# Get detailed error
helm get manifest bbhealthapp -n bbhealthapp
```

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n bbhealthapp

# Describe pod
kubectl describe pod <pod-name> -n bbhealthapp

# View logs
kubectl logs <pod-name> -n bbhealthapp
```

### Image Pull Errors

```bash
# Check image pull secrets
kubectl get secrets -n bbhealthapp

# Create image pull secret if needed
kubectl create secret docker-registry regcred \
  --docker-server=your-registry.com \
  --docker-username=your-username \
  --docker-password=your-password \
  --namespace bbhealthapp
```

### PVC Issues

```bash
# Check PVC status
kubectl get pvc -n bbhealthapp

# Describe PVC
kubectl describe pvc <pvc-name> -n bbhealthapp

# Check storage classes
kubectl get storageclass
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress
kubectl describe ingress bbhealthapp-ingress -n bbhealthapp

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## Advanced Usage

### Custom Resource Limits

```yaml
masterService:
  resources:
    requests:
      memory: 1Gi
      cpu: 1000m
    limits:
      memory: 2Gi
      cpu: 2000m
```

### Node Selectors

```yaml
nodeSelector:
  node-type: application
```

### Tolerations

```yaml
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "application"
    effect: "NoSchedule"
```

### Affinity

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - master-service
          topologyKey: kubernetes.io/hostname
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy with Helm

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Configure kubectl
        uses: azure/setup-kubectl@v1
        with:
          version: 'v1.28.0'
      
      - name: Install Helm
        uses: azure/setup-helm@v1
        with:
          version: 'v3.12.0'
      
      - name: Deploy with Helm
        run: |
          helm upgrade --install bbhealthapp ./helm/bbhealthapp \
            --namespace bbhealthapp \
            --create-namespace \
            --set image.tag=${{ github.sha }}
```

### GitLab CI

```yaml
deploy:
  stage: deploy
  script:
    - helm upgrade --install bbhealthapp ./helm/bbhealthapp \
      --namespace bbhealthapp \
      --create-namespace \
      --set image.tag=$CI_COMMIT_SHA
```

## Best Practices

1. **Use separate value files for different environments**
2. **Version your Helm charts**
3. **Use Helm secrets for sensitive data**
4. **Enable resource limits and requests**
5. **Use liveness and readiness probes**
6. **Implement proper logging and monitoring**
7. **Use Helm hooks for pre/post operations**
8. **Test charts in development first**
9. **Use Helm diff plugin to review changes**
10. **Implement proper rollback strategy**

## Cleanup

### Uninstall Release

```bash
helm uninstall bbhealthapp --namespace bbhealthapp
```

### Delete Namespace

```bash
kubectl delete namespace bbhealthapp
```

### Remove PVCs

```bash
kubectl delete pvc -n bbhealthapp --all
```

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
