# Kubernetes Configuration

## Directory Structure
```
kubernetes/
├── base/                  # Base configurations
├── overlays/             # Environment-specific overlays
│   ├── dev/             # Development environment
│   └── prod/            # Production environment
└── monitoring/          # Monitoring configurations
```

## Usage

### Development Deployment
```bash
kubectl apply -k overlays/dev
```

### Production Deployment
```bash
kubectl apply -k overlays/prod
```

### Monitoring Setup
```bash
kubectl create namespace monitoring
kubectl apply -f monitoring/
```

## Components
- Deployment with health checks and resource limits
- Service with LoadBalancer
- Horizontal Pod Autoscaler
- ConfigMaps for environment configuration
- Network Policies
- Monitoring with Prometheus and Grafana

## Customization
1. Update image repository in deployment.yaml
2. Adjust resource limits in environment overlays
3. Modify monitoring configurations as needed
