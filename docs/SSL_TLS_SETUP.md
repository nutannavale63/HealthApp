# SSL/TLS Configuration Guide for AWS EKS Deployment

This guide explains how to configure SSL/TLS certificates for your BBHealthApp deployment on AWS EKS.

## Overview

For production deployments, you should enable HTTPS for your application. This guide covers two approaches:
1. AWS Certificate Manager (ACM) with AWS Load Balancer Controller
2. Cert-Manager with Let's Encrypt

## Option 1: AWS Certificate Manager (ACM) - Recommended for Production

### Prerequisites
- AWS account with appropriate permissions
- Registered domain name (e.g., bbhealthapp.example.com)
- EKS cluster with AWS Load Balancer Controller installed

### Step 1: Request SSL Certificate in ACM

```bash
# Request a certificate for your domain
aws acm request-certificate \
  --domain-name bbhealthapp.example.com \
  --validation-method DNS \
  --subject-alternative-names www.bbhealthapp.example.com \
  --region us-west-2
```

Note the certificate ARN from the output.

### Step 2: Validate the Certificate

ACM will send validation emails to the domain's registered email addresses. Follow the instructions in the email to validate the certificate.

Alternatively, use DNS validation:

```bash
# Get DNS validation records
aws acm describe-certificate \
  --certificate-arn <CERTIFICATE_ARN> \
  --region us-west-2
```

Add the CNAME records to your domain's DNS configuration.

### Step 3: Wait for Certificate Validation

```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn <CERTIFICATE_ARN> \
  --region us-west-2 \
  --query 'Certificate.Status'
```

Wait until the status shows "ISSUED".

### Step 4: Update Helm Values

Update `helm/bbhealthapp/values.yaml`:

```yaml
ingress:
  enabled: true
  className: alb
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/certificate-arn: "<YOUR_CERTIFICATE_ARN>"
    alb.ingress.kubernetes.io/ssl-redirect: "443"
  hosts:
    - host: bbhealthapp.example.com
      paths:
        - path: /
          pathType: Prefix
          service: frontend
          port: 80
        - path: /api/master
          pathType: Prefix
          service: master-service
          port: 8080
        - path: /api/register
          pathType: Prefix
          service: register-service
          port: 8082
        - path: /api/document
          pathType: Prefix
          service: document-service
          port: 8080
```

### Step 5: Deploy with Helm

```bash
helm upgrade bbhealthapp ./helm/bbhealthapp \
  --namespace bbhealthapp \
  --install
```

## Option 2: Cert-Manager with Let's Encrypt - Good for Development/Staging

### Step 1: Install Cert-Manager

```bash
# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0
```

### Step 2: Create ClusterIssuer

Create `k8s/cert-manager-clusterissuer.yaml`:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

Apply it:

```bash
kubectl apply -f k8s/cert-manager-clusterissuer.yaml
```

### Step 3: Update Helm Values for Cert-Manager

Update `helm/bbhealthapp/values.yaml`:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: bbhealthapp.example.com
      paths:
        - path: /
          pathType: Prefix
          service: frontend
          port: 80
  tls:
    - secretName: bbhealthapp-tls
      hosts:
        - bbhealthapp.example.com
        - www.bbhealthapp.example.com
```

### Step 4: Deploy with Helm

```bash
helm upgrade bbhealthapp ./helm/bbhealthapp \
  --namespace bbhealthapp \
  --install
```

## Verification

### Check Certificate Status

```bash
# For ACM
aws acm describe-certificate \
  --certificate-arn <CERTIFICATE_ARN> \
  --region us-west-2

# For Cert-Manager
kubectl get certificate -n bbhealthapp
kubectl describe certificate bbhealthapp-tls -n bbhealthapp
```

### Test HTTPS Access

```bash
curl -I https://bbhealthapp.example.com
```

## Troubleshooting

### Certificate Not Issued

1. Check DNS validation records are correct
2. Ensure domain is properly configured
3. Check AWS Load Balancer Controller logs:
   ```bash
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   ```

### SSL Redirect Not Working

1. Verify ingress annotations are correct
2. Check ALB/Nginx controller logs
3. Ensure certificate is in "ISSUED" state

### Certificate Expiry

- ACM certificates auto-renew if DNS validation is configured
- Cert-Manager certificates auto-renew before expiry
- Set up monitoring for certificate expiry

## Security Best Practices

1. **Use strong TLS versions**: Only TLS 1.2 and 1.3
2. **Disable weak ciphers**: Configure ALB/Nginx to use only strong ciphers
3. **Enable HSTS**: Add HTTP Strict Transport Security headers
4. **Monitor certificate expiry**: Set up CloudWatch alerts
5. **Use certificate pinning**: For mobile apps (optional)

## Cost Considerations

- ACM certificates are free in AWS
- ALB costs apply (~$0.025 per hour)
- Cert-Manager with Let's Encrypt is free
- Consider using AWS WAF for additional security

## Additional Resources

- [AWS Certificate Manager Documentation](https://docs.aws.amazon.com/acm/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Cert-Manager Documentation](https://cert-manager.io/)
- [Let's Encrypt](https://letsencrypt.org/)
