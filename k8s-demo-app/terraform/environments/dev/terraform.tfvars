environment = "dev"
location = "eastus"
address_space = ["10.0.0.0/16"]
subnet_prefix = ["10.0.1.0/24"]
acr_name = "acrdevdemo"
kubernetes_version = "1.26.3"
node_count = 2
node_vm_size = "Standard_DS2_v2"
min_node_count = 1
max_node_count = 5

tags = {
  Environment = "Development"
  ManagedBy = "Terraform"
  Project = "K8s Demo App"
}
