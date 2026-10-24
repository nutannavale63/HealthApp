# BBHealthApp Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the BBHealth application to a Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured to access your cluster
- Docker registry (Docker Hub, AWS ECR, GCR, etc.)
- Docker installed locally

## Architecture

The deployment includes the following components:

- **Frontend**: React application served by Apache HTTP Server
- **Master Service**: Spring Boot service for authentication and user management
- **Register Service**: Spring Boot service for user registration
- **Document Service**: Spring Boot service for document management

## Files

| File | Description |
|------|-------------|
| `namespace.yaml` | Creates the `bbhealthapp` namespace |
| `configmap.yaml` | Configuration for environment variables |
| `secret.yaml` | Secrets for sensitive data (tokens, passwords) |
| `pvc.yaml` | Persistent volume claims for data persistence |
| `master-service-deployment.yaml` | Master service deployment and service |
| `register-service-deployment.yaml` | Register service deployment and service |
| `document-service-deployment.yaml` | Document service deployment and service |
| `frontend-deployment.yaml` | Frontend deployment and service |
| `ingress.yaml` | Ingress for external access |
| `build-images.sh` | Script to build and push Docker images |
| `deploy.sh` | Script to deploy to Kubernetes |

## Deployment Steps

### 1. Configure Docker Registry

Edit `build-images.sh` and set your Docker registry:

```bash
REGISTRY="your-registry.com"  # Change this to your registry
```

For Docker Hub, use:
```bash
REGISTRY="your-dockerhub-username"
```

For local development with minikube, you can use minikube's registry:
```bash
eval $(minikube docker-env)
```

### 2. Build and Push Docker Images

Make the script executable and run it:

```bash
chmod +x build-images.sh
./build-images.sh
```

This will build and push all Docker images to your registry.

### 3. Update Image References

If you're using a different registry than `your-registry.com`, update the image references in the deployment YAML files:

- `master-service-deployment.yaml`
- `register-service-deployment.yaml`
- `document-service-deployment.yaml`
- `frontend-deployment.yaml`

Change:
```yaml
image: windsurf-project-3-master-service:latest
```

To:
```yaml
image: your-registry.com/bbhealthapp-master-service:latest
```

### 4. Deploy to Kubernetes

Make the deploy script executable and run it:

```bash
chmod +x deploy.sh
./deploy.sh
```

This will:
- Create the namespace
- Apply ConfigMaps and Secrets
- Create PersistentVolumeClaims
- Deploy all services
- Apply Ingress

### 5. Verify Deployment

Check pod status:

```bash
kubectl get pods -n bbhealthapp
```

Expected output:
```
NAME                                READY   STATUS    RESTARTS   AGE
master-service-xxx-xxx              1/1     Running   0          2m
register-service-xxx-xxx            1/1     Running   0          2m
document-service-xxx-xxx            1/1     Running   0          2m
frontend-xxx-xxx                    1/1     Running   0          2m
```

Check services:

```bash
kubectl get svc -n bbhealthapp
```

### 6. Access the Application

Add the ingress hostname to your `/etc/hosts` file:

```bash
echo "127.0.0.1 bbhealthapp.local" | sudo tee -a /etc/hosts
```

Access the application at:
- **Frontend**: http://bbhealthapp.local
- **Master API**: http://bbhealthapp.local/api/master
- **Register API**: http://bbhealthapp.local/api/register
- **Document API**: http://bbhealthapp.local/api/document

## Local Development with Minikube

For local development with minikube:

```bash
# Start minikube
minikube start

# Use minikube's Docker daemon
eval $(minikube docker-env)

# Build images locally (no push needed)
docker build -t bbhealthapp-master-service:latest ../bbhealthapp-backend/bbhealthapp-api-master
docker build -t bbhealthapp-register-service:latest ../bbhealthapp-backend/bbhealthapp-api-register
docker build -t bbhealthapp-document-service:latest ../bbhealthapp-backend/bbhealthapp-api-document
docker build -t bbhealthapp-frontend:latest ../bbhealthapp-frontend

# Deploy
./deploy.sh

# Get the minikube IP
minikube ip

# Update /etc/hosts with minikube IP
echo "$(minikube ip) bbhealthapp.local" | sudo tee -a /etc/hosts
```

## Scaling Services

Scale a service using kubectl:

```bash
# Scale master service to 3 replicas
kubectl scale deployment master-service --replicas=3 -n bbhealthapp

# Scale frontend to 3 replicas
kubectl scale deployment frontend --replicas=3 -n bbhealthapp
```

## Viewing Logs

View logs for a specific service:

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

## Troubleshooting

### Pods Not Starting

Check pod events:

```bash
kubectl describe pod <pod-name> -n bbhealthapp
```

### Image Pull Errors

If you get image pull errors, ensure:
1. Images are pushed to your registry
2. ImagePullSecrets are configured if using a private registry
3. Image references in YAML files are correct

### Persistent Volume Issues

Check PVC status:

```bash
kubectl get pvc -n bbhealthapp
```

If PVCs are stuck in `Pending` state, check if your cluster has a default StorageClass or configure one.

### Ingress Not Working

Check ingress controller is installed:

```bash
kubectl get pods -n ingress-nginx
```

If not installed, install nginx ingress controller:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
```

## Cleanup

To remove the deployment:

```bash
kubectl delete -f ingress.yaml
kubectl delete -f frontend-deployment.yaml
kubectl delete -f document-service-deployment.yaml
kubectl delete -f register-service-deployment.yaml
kubectl delete -f master-service-deployment.yaml
kubectl delete -f pvc.yaml
kubectl delete -f secret.yaml
kubectl delete -f configmap.yaml
kubectl delete -f namespace.yaml
```

Or delete the entire namespace:

```bash
kubectl delete namespace bbhealthapp
```

## SSL/TLS Configuration

For production, enable SSL/TLS:

1. Install cert-manager:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

2. Uncomment the TLS section in `ingress.yaml`

3. Update the cluster-issuer annotation based on your cert-manager setup

## Monitoring

Consider adding monitoring and logging:
- **Prometheus + Grafana**: For metrics and monitoring
- **ELK Stack**: For centralized logging
- **Jaeger/Zipkin**: For distributed tracing

## Security Considerations

For production deployment:
1. Use a private Docker registry
2. Configure ImagePullSecrets
3. Enable NetworkPolicies
4. Use PodSecurityPolicies or Pod Security Standards
5. Enable RBAC with least privilege
6. Rotate secrets regularly
7. Enable SSL/TLS for all communications
8. Implement resource quotas and limits
9. Use sealed secrets or external secret management (Vault, AWS Secrets Manager)
