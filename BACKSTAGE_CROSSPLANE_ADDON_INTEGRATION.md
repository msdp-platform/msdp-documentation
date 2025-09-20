# Backstage & Crossplane Addon Integration Strategy

## Overview

This document outlines how the new Backstage and Crossplane addon modules integrate into the existing MSDP DevOps infrastructure, following established patterns and maintaining consistency with the current addon ecosystem.

## Module Architecture

### Following Established Patterns

Both modules follow the exact same structure as existing addons (ArgoCD, Prometheus, etc.):

```
infrastructure/addons/terraform/modules/
├── backstage/
│   ├── main.tf          # Main Terraform configuration
│   ├── variables.tf     # Module variables
│   └── values.yaml      # Helm values template
└── crossplane/
    ├── main.tf          # Main Terraform configuration  
    ├── variables.tf     # Module variables
    ├── values.yaml      # Helm values template
    └── compositions/    # MSDP-specific compositions
        ├── README.md
        ├── aurora-serverless.yaml
        └── azure-postgresql.yaml
```

### Key Design Principles

1. **Consistent with Existing Addons**: Same Terraform patterns, Helm usage, and variable structures
2. **Environment Agnostic**: Works across dev/staging/prod environments
3. **Modular & Optional**: Can be enabled/disabled independently
4. **MSDP-Specific**: Pre-configured for MSDP platform needs

## Integration Points

### 1. Environment Configuration

The modules integrate into the existing `azure-dev` environment configuration:

```hcl
# main.tf - Local plugins configuration
locals {
  plugins = {
    # Existing plugins...
    argocd = {
      enabled  = var.plugins.argocd.enabled
      hostname = local.argocd_hostname
    }
    
    # New Platform Engineering plugins
    backstage = {
      enabled  = var.plugins.backstage.enabled
      hostname = local.backstage_hostname
    }
    crossplane = {
      enabled = var.plugins.crossplane.enabled
    }
  }
}
```

### 2. Terraform Variables Integration

New variables are added to `variables.tf` and `terraform.tfvars`:

```hcl
# Platform Engineering Variables
variable "backstage_hostname" {
  description = "Backstage ingress hostname"
  type        = string
  default     = ""
}

variable "github_client_id" {
  description = "GitHub OAuth client ID for Backstage authentication"
  type        = string
  default     = ""
  sensitive   = true
}

# Crossplane provider configurations
variable "crossplane_providers" {
  description = "Crossplane provider configurations"
  type = object({
    azure = object({
      enabled = bool
      version = string
    })
    aws = object({
      enabled = bool
      version = string
    })
    kubernetes = object({
      enabled = bool
      version = string
    })
  })
}
```

### 3. Module Dependencies

Both modules follow the established dependency patterns:

```hcl
# Backstage depends on ingress infrastructure
module "backstage" {
  source = "../../modules/backstage"
  # ... configuration ...
  
  depends_on = [
    module.cert_manager,
    module.nginx_ingress
  ]
}

# Crossplane is foundational (no dependencies)
module "crossplane" {
  source = "../../modules/crossplane"
  # ... configuration ...
  
  # No dependencies - Crossplane is foundational
}
```

## MSDP-Specific Configurations

### Backstage Configuration

Pre-configured for MSDP platform with:

1. **Service Integration**: Proxy configuration for MSDP services
2. **ArgoCD Integration**: Automatic discovery of ArgoCD applications
3. **GitHub Integration**: OAuth and repository access
4. **MSDP Catalog**: Pre-loaded with MSDP services and teams

```yaml
# App configuration with MSDP integrations
app_config = {
  app = {
    title   = "MSDP Platform"
    baseUrl = "https://backstage.dev.aztech-msdp.com"
  }
  # Integration with existing ArgoCD
  catalog = {
    providers = {
      argocd = {
        "msdp-production" = {
          baseUrl = "https://argocd.dev.aztech-msdp.com"
          schedule = { frequency = { minutes = 5 } }
          filters = [
            { labelSelector = "app.kubernetes.io/part-of=msdp-platform" }
          ]
        }
      }
    }
  }
  # Proxy to MSDP services
  proxy = {
    "/api/msdp" = {
      target       = "http://192.168.1.189:3000"
      changeOrigin = true
      headers = {
        "X-Platform-Source" = "backstage"
      }
    }
  }
}
```

### Crossplane Configuration

Pre-configured with MSDP-specific providers and compositions:

1. **Multi-Cloud Providers**: Azure, AWS, and Kubernetes providers
2. **MSDP Compositions**: Aurora Serverless, Azure PostgreSQL, Redis, Storage
3. **Service-Specific Namespaces**: Support for multi-namespace strategy

## Deployment Strategy

### Current Status: Disabled by Default

The modules are currently disabled in the configuration to allow for controlled testing:

```hcl
# Platform Engineering (disabled for now)
backstage = {
  enabled  = false
  hostname = local.backstage_hostname
}

crossplane = {
  enabled = false
}
```

### Enabling the Modules

To enable the modules, update the local plugins configuration:

```hcl
# Platform Engineering
backstage = {
  enabled  = var.plugins.backstage.enabled  # Enable this
  hostname = local.backstage_hostname
}

crossplane = {
  enabled = var.plugins.crossplane.enabled  # Enable this
}
```

And update `terraform.tfvars`:

```hcl
plugins = {
  # ... existing plugins ...
  
  # Platform Engineering
  backstage = { 
    enabled           = true
    chart_version     = "1.8.3"
    backstage_version = "latest"
  }
  crossplane = { 
    enabled             = true
    chart_version       = "1.14.5"
    crossplane_version  = "v1.14.5"
  }
}
```

## Multi-Namespace Strategy

### Shared Platform Components

- **ONE Crossplane** instance (`crossplane-system`) managing ALL infrastructure
- **ONE ArgoCD** instance (`argocd`) deploying ALL applications  
- **ONE Backstage** instance (`backstage`) showing ALL services

### Service-Specific Namespaces

Each MSDP service operates in its own namespace:

- `msdp-location-service` - Location and geographic services
- `msdp-merchant-service` - VendaBuddy marketplace services
- `msdp-user-service` - User authentication services
- `msdp-order-service` - Order processing services
- `msdp-payment-service` - Payment processing (PCI compliant)
- `msdp-frontend-apps` - All frontend applications

### Benefits

1. **Cost Optimization**: No duplicate platform resources
2. **Single Source of Truth**: All services in one interface
3. **Consistent Workflows**: Same deployment patterns
4. **Centralized Management**: Unified monitoring and security
5. **Service Isolation**: Namespace boundaries provide security isolation

## Testing & Validation

### Local Testing

Both modules have been tested locally:

```bash
# Backstage module
cd infrastructure/addons/terraform/modules/backstage
terraform init && terraform validate
# ✅ Success! The configuration is valid.

# Crossplane module  
cd infrastructure/addons/terraform/modules/crossplane
terraform init && terraform validate
# ✅ Success! The configuration is valid.
```

### Integration Testing

Before enabling in production:

1. **Plan Phase**: Run `terraform plan` to verify configuration
2. **Staged Deployment**: Enable one module at a time
3. **Dependency Verification**: Ensure cert-manager and nginx-ingress are working
4. **Credential Validation**: Verify GitHub and cloud provider credentials

## Next Steps

1. **Credential Setup**: Configure GitHub OAuth credentials and cloud provider credentials
2. **DNS Configuration**: Ensure `backstage.dev.aztech-msdp.com` resolves correctly
3. **Enable Backstage**: Start with Backstage module first
4. **Enable Crossplane**: Add Crossplane after Backstage is stable
5. **MSDP Service Migration**: Gradually migrate MSDP services to use Crossplane compositions

## Security Considerations

### Credentials Management

- GitHub credentials stored as Kubernetes secrets
- Cloud provider credentials (Azure/AWS) stored as Kubernetes secrets
- TLS certificates managed by cert-manager with Let's Encrypt

### Network Security

- Ingress protected by NGINX Ingress Controller
- TLS termination with automatic certificate renewal
- CORS configuration for secure API access

### RBAC Integration

- Service accounts with minimal required permissions
- Integration with existing AKS RBAC policies
- Namespace-based isolation for service-specific resources

This integration strategy ensures that Backstage and Crossplane modules fit seamlessly into the existing MSDP DevOps infrastructure while maintaining security, scalability, and operational excellence.
