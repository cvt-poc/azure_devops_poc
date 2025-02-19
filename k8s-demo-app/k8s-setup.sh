#!/bin/bash

# Create base directory structure
mkdir -p kubernetes/{base,overlays/{dev,prod},monitoring}

# Create base manifests
cat > kubernetes/base/namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: demo-app
  labels:
    name: demo-app
EOF

cat > kubernetes/base/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  labels:
    app: demo-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: demo-app
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: ${ACR_NAME}.azurecr.io/demo-app:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
        env:
        - name: NODE_ENV
          valueFrom:
            configMapKeyRef:
              name: demo-app-config
              key: NODE_ENV
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
      volumes:
      - name: config-volume
        configMap:
          name: demo-app-config
EOF

cat > kubernetes/base/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  labels:
    app: demo-app
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: demo-app
EOF

cat > kubernetes/base/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-app-config
data:
  NODE_ENV: "production"
  config.json: |
    {
      "logLevel": "info",
      "metricsEnabled": true
    }
EOF

cat > kubernetes/base/hpa.yaml << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: demo-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: demo-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

cat > kubernetes/base/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-app-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-app
            port:
              number: 80
EOF

cat > kubernetes/base/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- namespace.yaml
- deployment.yaml
- service.yaml
- configmap.yaml
- hpa.yaml
- ingress.yaml
EOF

# Create development overlay
mkdir -p kubernetes/overlays/dev

cat > kubernetes/overlays/dev/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
- ../../base

namespace: demo-app-dev

commonLabels:
  environment: development

patches:
- path: patches/deployment-patch.yaml

configMapGenerator:
- name: demo-app-config
  behavior: merge
  literals:
  - NODE_ENV=development
EOF

mkdir -p kubernetes/overlays/dev/patches

cat > kubernetes/overlays/dev/patches/deployment-patch.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  template:
    spec:
      containers:
      - name: demo-app
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "100m"
            memory: "128Mi"
EOF

# Create production overlay
mkdir -p kubernetes/overlays/prod

cat > kubernetes/overlays/prod/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
- ../../base

namespace: demo-app-prod

commonLabels:
  environment: production

patches:
- path: patches/deployment-patch.yaml

configMapGenerator:
- name: demo-app-config
  behavior: merge
  literals:
  - NODE_ENV=production
EOF

mkdir -p kubernetes/overlays/prod/patches

cat > kubernetes/overlays/prod/patches/deployment-patch.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  template:
    spec:
      containers:
      - name: demo-app
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "400m"
            memory: "512Mi"
EOF

# Create monitoring configurations
cat > kubernetes/monitoring/prometheus.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config-volume
          mountPath: /etc/prometheus/
      volumes:
      - name: config-volume
        configMap:
          name: prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
EOF

cat > kubernetes/monitoring/grafana.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana
        ports:
        - containerPort: 3000
        env:
        - name: GF_AUTH_ANONYMOUS_ENABLED
          value: "true"
        - name: GF_AUTH_ANONYMOUS_ORG_ROLE
          value: "Viewer"
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
  type: LoadBalancer
EOF

# Create network policies
cat > kubernetes/base/network-policy.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: demo-app-network-policy
spec:
  podSelector:
    matchLabels:
      app: demo-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090
EOF

# Create README
cat > kubernetes/README.md << 'EOF'
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
EOF

echo "Kubernetes configuration files have been created successfully!"
echo "Next steps:"
echo "1. Update the ACR name in the deployment configurations"
echo "2. Create the necessary namespaces"
echo "3. Apply the configurations using kustomize"
echo "4. Verify the deployments"
EOF