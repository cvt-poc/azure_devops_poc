variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "subnet_prefix" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "acr_name" {
  type    = string
  default = "acrdevdemo"
}

variable "kubernetes_version" {
  type    = string
  default = "1.26.3"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "node_vm_size" {
  type    = string
  default = "Standard_DS2_v2"
}

variable "min_node_count" {
  type    = number
  default = 1
}

variable "max_node_count" {
  type    = number
  default = 5
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "K8s Demo App"
  }
}
