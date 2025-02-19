# Detailed Implementation Guide for Azure Kubernetes Environment

## Phase 1: Initial Setup and Prerequisites

### 1.1. Install Required Tools
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLI | bash

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install kubectl
sudo apt-get update
sudo apt-get install -y kubectl

# Verify installations
az --version
terraform --version
kubectl version --client
```

### 1.2. Azure Login and Subscription Setup
```bash
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Verify current subscription
az account show --output table
```

## Phase 2: Create Azure Kubernetes Environment

### 2.1. Resource Group and AKS Infrastructure Setup
```bash
# Create a resource group for Terraform state (optional but recommended)
az group create --name rg-terraform-state --location eastus

# Create a storage account for Terraform state
az storage account create \
    --name tfstate$RANDOM \
    --resource-group rg-terraform-state \
    --sku Standard_LRS \
    --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group rg-terraform-state --account-name <storage-account-name> --query '[0].value' -o tsv)

# Create blob container
az storage container create \
    --name tfstate \
    --account-name <storage-account-name> \
    --account-key $ACCOUNT_KEY
```

### 2.2. Create Terraform Configuration Directory
```bash
# Create directory structure
mkdir -p ~/azure-k8s-project/terraform
cd ~/azure-k8s-project/terraform

# Create main.tf, variables.tf, and outputs.tf using the provided terraform code from azure-infrastructure artifact

# Initialize Terraform
terraform init

# Verify the plan
terraform plan

# Apply the configuration
terraform apply -auto-approve

# Get AKS credentials
az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>

# Verify cluster connection
kubectl get nodes
```

## Phase 3: Azure DevOps Setup

### 3.1. Create Azure DevOps Project
1. Go to https://dev.azure.com
2. Create a new project:
   ```
   Name: k8s-deployment-project
   Description: Kubernetes deployment project
   Visibility: Private
   Version control: Git
   Work item process: Agile
   ```

### 3.2. Repository Setup
```bash
# Clone the repository locally
git clone https://dev.azure.com/<organization>/<project>/_git/<repository>

# Create project structure
mkdir -p src/app kubernetes terraform

# Copy files to respective directories
cp <terraform-files> terraform/
cp <kubernetes-manifests> kubernetes/
cp <application-files> src/app/

# Create pipeline file
touch azure-pipelines.yml

# Add files to repository
git add .
git commit -m "Initial project setup"
git push origin main
```

### 3.3. Service Connection Setup
1. Go to Project Settings > Service connections
2. Create Azure Resource Manager connection:
   ```
   Name: azure-subscription-connection
   Scope level: Subscription
   Subscription: <your-subscription>
   Resource Group: <your-resource-group>
   ```
3. Create ACR connection:
   ```
   Name: acr-service-connection
   Registry type: Azure Container Registry
   Subscription: <your-subscription>
   Registry: <your-acr-name>
   ```
4. Create AKS connection:
   ```
   Name: dev-aks-connection
   Namespace: default
   Cluster: <your-aks-cluster>
   ```

## Phase 4: Pipeline Setup

### 4.1. Create Pipeline
1. Go to Pipelines > New Pipeline
2. Select Azure Repos Git
3. Select your repository
4. Select "Existing Azure Pipelines YAML file"
5. Copy content from azure-pipeline artifact to azure-pipelines.yml
6. Update variables in pipeline:
   ```yaml
   variables:
     dockerRegistryServiceConnection: 'acr-service-connection'
     imageRepository: 'app'
     containerRegistry: '<your-acr-name>.azurecr.io'
     dockerfilePath: '$(Build.SourcesDirectory)/Dockerfile'
     tag: '$(Build.BuildId)'
   ```

### 4.2. Create Environment
1. Go to Pipelines > Environments
2. Create new environment:
   ```
   Name: development
   Resource: Kubernetes
   Provider: Azure Kubernetes Service
   Cluster: <your-aks-cluster>
   Namespace: default
   ```

## Phase 5: Application Deployment

### 5.1. Prepare Kubernetes Manifests
1. Update kubernetes/deployment.yml:
   ```yaml
   image: <your-acr-name>.azurecr.io/app:latest
   ```
2. Update container port and health check paths according to your application

### 5.2. Add Sample Application
1. Create a simple web application in src/app
2. Add Dockerfile:
   ```dockerfile
   FROM node:14
   WORKDIR /app
   COPY package*.json ./
   RUN npm install
   COPY . .
   EXPOSE 80
   CMD ["npm", "start"]
   ```

### 5.3. Run Pipeline
1. Commit and push all changes
2. Go to Pipelines
3. Run pipeline
4. Monitor build and deployment stages

### 5.4. Verify Deployment
```bash
# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services

# Get external IP
kubectl get service app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Test application
curl http://<external-ip>
```

## Phase 6: Monitoring and Verification

### 6.1. Enable Monitoring
```bash
# Enable container insights
az aks enable-addons -a monitoring -n <cluster-name> -g <resource-group>

# Configure log analytics
az monitor log-analytics workspace create \
    --resource-group <resource-group> \
    --workspace-name <workspace-name>

# Link workspace to cluster
az aks enable-addons -a monitoring \
    --resource-group <resource-group> \
    --name <cluster-name> \
    --workspace-resource-id <workspace-resource-id>
```

### 6.2. Setup Basic Alerts
1. Go to Azure Portal > Your AKS cluster
2. Navigate to Monitoring > Alerts
3. Create alert rules for:
   - Node CPU usage > 80%
   - Node memory usage > 80%
   - Pod restart count > 5
   - Failed deployments

### 6.3. Verify Security Settings
```bash
# Check RBAC status
kubectl auth can-i create pods --all-namespaces

# Verify network policies
kubectl get networkpolicies --all-namespaces

# Check pod security policies
kubectl get psp
```

## Troubleshooting Guide

### Common Issues and Solutions

1. Pipeline Connection Issues:
```bash
# Check service principal permissions
az role assignment list --assignee <service-principal-id>

# Verify ACR access
az acr login --name <acr-name>
```

2. Deployment Issues:
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

3. Network Issues:
```bash
# Test service connectivity
kubectl run -it --rm test --image=busybox --restart=Never -- wget -qO- http://app-service

# Check service endpoints
kubectl get endpoints app-service
```

### Validation Checklist
- [ ] AKS cluster is running and healthy
- [ ] Pipeline can build and push images to ACR
- [ ] Kubernetes deployments are successful
- [ ] Application is accessible via LoadBalancer IP
- [ ] Monitoring is enabled and working
- [ ] Alerts are configured
- [ ] RBAC is properly configured
- [ ] Network policies are in place
