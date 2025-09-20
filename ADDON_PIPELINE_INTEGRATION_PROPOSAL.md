# Addon Pipeline Integration Proposal: Backstage & Crossplane

## 🎯 **Integration Strategy**

Based on your existing Terraform addon pipeline, I propose integrating Backstage and Crossplane as **additional addon modules** within your current `k8s-addons-terraform.yml` workflow, following your established patterns.

---

## 🏗️ **Current Addon Pipeline Analysis**

### **✅ Existing Structure (Well Designed!):**

```
infrastructure/addons/terraform/
├── environments/
│   ├── azure-dev/
│   │   ├── main.tf              # Module orchestration
│   │   ├── terraform.tfvars     # Plugin configuration
│   │   └── variables.tf         # Variable definitions
│   └── aws-dev/                 # AWS environment
├── modules/
│   ├── argocd/                  # ✅ Already exists!
│   ├── cert-manager/
│   ├── external-dns/
│   ├── nginx-ingress/
│   ├── prometheus-stack/
│   └── [other addons...]
└── workflows/
    └── k8s-addons-terraform.yml # ✅ Established workflow
```

### **✅ Current Plugin System:**

```hcl
# terraform.tfvars - Plugin Configuration
plugins = {
  external_dns     = { enabled = true }
  cert_manager     = { enabled = true }
  nginx_ingress    = { enabled = true }
  prometheus_stack = { enabled = true }
  argocd          = { enabled = true }  # ✅ Already configured!
  
  # NEW: Platform Engineering
  backstage       = { enabled = true }  # 🆕 Add this
  crossplane      = { enabled = true }  # 🆕 Add this
}
```

---

## 🔧 **Proposed Integration**

### **1. Add Backstage & Crossplane as Addon Modules**

#### **Move Existing Modules into Addon Structure:**

```bash
# Move platform-engineering modules to addon modules
infrastructure/addons/terraform/modules/
├── backstage/              # 🆕 Move from platform-engineering/
│   ├── main.tf
│   ├── variables.tf
│   ├── values.yaml
│   └── outputs.tf
├── crossplane/             # 🆕 Move from platform-engineering/
│   ├── main.tf
│   ├── variables.tf
│   ├── compositions/       # 🆕 MSDP compositions
│   └── outputs.tf
└── [existing modules...]
```

### **2. Update Addon Environment Configuration**

#### **Enhanced `azure-dev/main.tf`:**

```hcl
# Add to existing azure-dev/main.tf

# Backstage (Developer Portal)
module "backstage" {
  source = "../../modules/backstage"
  
  enabled = local.plugins.backstage.enabled
  
  # Configuration following your patterns
  namespace     = "backstage"
  chart_version = local.plugins.backstage.chart_version
  
  # MSDP-specific configuration
  app_config = {
    app = {
      title   = "MSDP Platform"
      baseUrl = "https://${local.backstage_hostname}"
    }
    backend = {
      baseUrl = "https://${local.backstage_hostname}"
      listen = {
        port = 7007
        host = "0.0.0.0"
      }
    }
    
    # Integration with existing ArgoCD
    catalog = {
      providers = {
        argocd = {
          msdp-production = {
            baseUrl = "https://${local.argocd_hostname}"
            schedule = {
              frequency = { minutes = 5 }
            }
            filters = [
              { labelSelector = "app.kubernetes.io/part-of=msdp-platform" }
            ]
          }
        }
      }
    }
    
    # Proxy to MSDP services (your laptop for now)
    proxy = {
      "/api/msdp" = {
        target      = "http://192.168.1.189:3000"
        changeOrigin = true
      }
    }
  }
  
  # Database configuration
  postgresql = {
    enabled = true
    auth = {
      username = "backstage"
      password = "backstage-dev-password"
      database = "backstage"
    }
  }
  
  # Ingress configuration (following your patterns)
  ingress = {
    enabled = true
    hosts = [{
      host = local.backstage_hostname
      paths = [{
        path = "/"
        pathType = "Prefix"
      }]
    }]
    tls = [{
      secretName = var.backstage_tls_secret_name
      hosts      = [local.backstage_hostname]
    }]
    className   = local.ingress_class_name
    annotations = {
      "cert-manager.io/cluster-issuer" = local.plugins.cert_manager.cluster_issuer
    }
  }
  
  # Dependencies
  depends_on = [
    module.cert_manager,
    module.nginx_ingress
  ]
}

# Crossplane (Infrastructure Engine)
module "crossplane" {
  source = "../../modules/crossplane"
  
  enabled = local.plugins.crossplane.enabled
  
  # Configuration following your patterns  
  namespace     = "crossplane-system"
  chart_version = local.plugins.crossplane.chart_version
  
  # Provider configuration
  providers = {
    azure = {
      enabled = true
      version = "v0.21.0"
    }
    aws = {
      enabled = true
      version = "v0.44.0"
    }
    kubernetes = {
      enabled = true
      version = "v0.11.0"
    }
  }
  
  # MSDP-specific compositions
  compositions = [
    "msdp-aurora-serverless",
    "msdp-azure-postgresql",
    "msdp-redis-cache"
  ]
  
  # Credentials (using existing secrets pattern)
  azure_client_id       = var.azure_client_id
  azure_client_secret   = var.azure_client_secret
  azure_tenant_id       = var.azure_tenant_id
  azure_subscription_id = var.azure_subscription_id
  
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_region           = var.aws_region
  
  # Dependencies (none - Crossplane is foundational)
}
```

#### **Enhanced `azure-dev/terraform.tfvars`:**

```hcl
# Add to existing terraform.tfvars

# Platform Engineering Configuration
backstage_hostname     = "backstage.dev.aztech-msdp.com"
crossplane_hostname    = "crossplane.dev.aztech-msdp.com"

# Plugin Configuration (add to existing plugins)
plugins = {
  # Existing plugins...
  external_dns     = { enabled = true }
  cert_manager     = { enabled = true }
  nginx_ingress    = { enabled = true }
  prometheus_stack = { enabled = true }
  argocd          = { enabled = true }
  
  # Platform Engineering (NEW)
  backstage = { 
    enabled       = true
    chart_version = "1.8.3"
  }
  crossplane = { 
    enabled       = true
    chart_version = "1.14.5"
  }
}

# TLS Secret Names (add to existing)
backstage_tls_secret_name   = "backstage-tls"
crossplane_tls_secret_name  = "crossplane-tls"
```

#### **Enhanced `azure-dev/variables.tf`:**

```hcl
# Add to existing variables.tf

# Platform Engineering Variables
variable "backstage_hostname" {
  description = "Backstage ingress hostname"
  type        = string
  default     = ""
}

variable "backstage_tls_secret_name" {
  description = "TLS secret name for Backstage"
  type        = string
  default     = "backstage-tls"
}

variable "crossplane_hostname" {
  description = "Crossplane dashboard hostname"
  type        = string
  default     = ""
}

variable "crossplane_tls_secret_name" {
  description = "TLS secret name for Crossplane"
  type        = string
  default     = "crossplane-tls"
}

# GitHub credentials for Backstage
variable "github_client_id" {
  description = "GitHub OAuth client ID for Backstage"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_client_secret" {
  description = "GitHub OAuth client secret for Backstage"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_token" {
  description = "GitHub token for Backstage"
  type        = string
  default     = ""
  sensitive   = true
}
```

### **3. Update Workflow to Include Platform Engineering**

#### **Enhanced `k8s-addons-terraform.yml` (No Changes Needed!):**

Your existing workflow already supports this! The workflow will automatically:

✅ **Detect new modules** in the terraform.tfvars plugins configuration
✅ **Deploy Backstage** when `plugins.backstage.enabled = true`
✅ **Deploy Crossplane** when `plugins.crossplane.enabled = true`
✅ **Handle dependencies** through Terraform depends_on
✅ **Validate deployments** in the existing validation step

### **4. Modular Backstage Module**

#### **`modules/backstage/main.tf`:**

```hcl
# Modular Backstage following your addon patterns

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

# Namespace
resource "kubernetes_namespace" "backstage" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "backstage"
      "app.kubernetes.io/managed-by" = "terraform"
      "msdp.platform/component"      = "backstage"
    }
  }
}

# ConfigMap for app-config.yaml
resource "kubernetes_config_map" "backstage_config" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "backstage-app-config"
    namespace = kubernetes_namespace.backstage[0].metadata[0].name
  }

  data = {
    "app-config.yaml" = yamlencode(var.app_config)
  }
}

# Secrets for GitHub integration
resource "kubernetes_secret" "github_credentials" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = "github-credentials"
    namespace = kubernetes_namespace.backstage[0].metadata[0].name
  }

  data = {
    GITHUB_CLIENT_ID     = var.github_client_id
    GITHUB_CLIENT_SECRET = var.github_client_secret
    GITHUB_TOKEN         = var.github_token
  }

  type = "Opaque"
}

# Helm release
resource "helm_release" "backstage" {
  count = var.enabled ? 1 : 0

  name       = "backstage"
  repository = "https://backstage.github.io/charts"
  chart      = "backstage"
  version    = var.chart_version
  namespace  = kubernetes_namespace.backstage[0].metadata[0].name

  values = [
    yamlencode({
      backstage = {
        image = {
          repository = "backstage/backstage"
          tag        = "latest"
        }
        
        appConfig = {
          configMapRef = kubernetes_config_map.backstage_config[0].metadata[0].name
        }
        
        extraEnvVars = [
          {
            name = "GITHUB_CLIENT_ID"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.github_credentials[0].metadata[0].name
                key  = "GITHUB_CLIENT_ID"
              }
            }
          },
          {
            name = "GITHUB_CLIENT_SECRET"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.github_credentials[0].metadata[0].name
                key  = "GITHUB_CLIENT_SECRET"
              }
            }
          },
          {
            name = "GITHUB_TOKEN"
            valueFrom = {
              secretKeyRef = {
                name = kubernetes_secret.github_credentials[0].metadata[0].name
                key  = "GITHUB_TOKEN"
              }
            }
          }
        ]
      }
      
      postgresql = var.postgresql
      ingress    = var.ingress
    })
  ]

  timeout         = 900
  wait            = true
  wait_for_jobs   = true
  atomic          = true
  cleanup_on_fail = true

  depends_on = [
    kubernetes_namespace.backstage,
    kubernetes_config_map.backstage_config,
    kubernetes_secret.github_credentials
  ]
}

# Outputs
output "namespace" {
  description = "Backstage namespace"
  value       = var.enabled ? kubernetes_namespace.backstage[0].metadata[0].name : null
}

output "helm_release_version" {
  description = "Deployed Helm chart version"
  value       = var.enabled ? helm_release.backstage[0].version : null
}

output "helm_release_status" {
  description = "Helm release status"
  value       = var.enabled ? helm_release.backstage[0].status : null
}
```

#### **`modules/backstage/variables.tf`:**

```hcl
variable "enabled" {
  description = "Enable Backstage deployment"
  type        = bool
  default     = false
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "backstage"
}

variable "chart_version" {
  description = "Backstage Helm chart version"
  type        = string
  default     = "1.8.3"
}

variable "app_config" {
  description = "Backstage app configuration"
  type        = any
  default     = {}
}

variable "postgresql" {
  description = "PostgreSQL configuration"
  type        = any
  default     = {}
}

variable "ingress" {
  description = "Ingress configuration"
  type        = any
  default     = {}
}

variable "github_client_id" {
  description = "GitHub OAuth client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_client_secret" {
  description = "GitHub OAuth client secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "github_token" {
  description = "GitHub token"
  type        = string
  default     = ""
  sensitive   = true
}
```

### **5. Modular Crossplane Module**

#### **`modules/crossplane/main.tf`:**

```hcl
# Modular Crossplane following your addon patterns

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

# Namespace
resource "kubernetes_namespace" "crossplane_system" {
  count = var.enabled ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"       = "crossplane"
      "app.kubernetes.io/managed-by" = "terraform"
      "msdp.platform/component"      = "crossplane"
    }
  }
}

# Provider credentials
resource "kubernetes_secret" "azure_credentials" {
  count = var.enabled && var.providers.azure.enabled ? 1 : 0

  metadata {
    name      = "azure-secret"
    namespace = kubernetes_namespace.crossplane_system[0].metadata[0].name
  }

  data = {
    creds = jsonencode({
      clientId       = var.azure_client_id
      clientSecret   = var.azure_client_secret
      tenantId       = var.azure_tenant_id
      subscriptionId = var.azure_subscription_id
    })
  }

  type = "Opaque"
}

resource "kubernetes_secret" "aws_credentials" {
  count = var.enabled && var.providers.aws.enabled ? 1 : 0

  metadata {
    name      = "aws-secret"
    namespace = kubernetes_namespace.crossplane_system[0].metadata[0].name
  }

  data = {
    creds = jsonencode({
      accessKeyId     = var.aws_access_key_id
      secretAccessKey = var.aws_secret_access_key
      region          = var.aws_region
    })
  }

  type = "Opaque"
}

# Helm release
resource "helm_release" "crossplane" {
  count = var.enabled ? 1 : 0

  name       = "crossplane"
  repository = "https://charts.crossplane.io/stable"
  chart      = "crossplane"
  version    = var.chart_version
  namespace  = kubernetes_namespace.crossplane_system[0].metadata[0].name

  values = [
    yamlencode({
      args = [
        "--enable-composition-revisions",
        "--enable-environment-configs",
        "--enable-usages"
      ]
      
      metrics = {
        enabled = true
      }
      
      resourcesCrossplane = {
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
        requests = {
          cpu    = "100m"
          memory = "256Mi"
        }
      }
    })
  ]

  timeout         = 600
  wait            = true
  wait_for_jobs   = true
  atomic          = true
  cleanup_on_fail = true

  depends_on = [kubernetes_namespace.crossplane_system]
}

# Provider installations (using kubectl_manifest)
resource "kubectl_manifest" "azure_provider" {
  count = var.enabled && var.providers.azure.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name = "provider-azure"
    }
    spec = {
      package = "xpkg.upbound.io/crossplane-contrib/provider-azure:${var.providers.azure.version}"
    }
  })

  depends_on = [helm_release.crossplane]
}

resource "kubectl_manifest" "aws_provider" {
  count = var.enabled && var.providers.aws.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "pkg.crossplane.io/v1"
    kind       = "Provider"
    metadata = {
      name = "provider-aws"
    }
    spec = {
      package = "xpkg.upbound.io/crossplane-contrib/provider-aws:${var.providers.aws.version}"
    }
  })

  depends_on = [helm_release.crossplane]
}

# Wait for providers
resource "time_sleep" "wait_for_providers" {
  count = var.enabled ? 1 : 0

  depends_on = [
    kubectl_manifest.azure_provider,
    kubectl_manifest.aws_provider
  ]

  create_duration = "60s"
}

# Provider configs (credentials)
resource "kubectl_manifest" "azure_provider_config" {
  count = var.enabled && var.providers.azure.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "azure.crossplane.io/v1beta1"
    kind       = "ProviderConfig"
    metadata = {
      name = "default"
    }
    spec = {
      credentials = {
        source = "Secret"
        secretRef = {
          namespace = kubernetes_namespace.crossplane_system[0].metadata[0].name
          name      = kubernetes_secret.azure_credentials[0].metadata[0].name
          key       = "creds"
        }
      }
    }
  })

  depends_on = [time_sleep.wait_for_providers]
}

resource "kubectl_manifest" "aws_provider_config" {
  count = var.enabled && var.providers.aws.enabled ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "aws.crossplane.io/v1beta1"
    kind       = "ProviderConfig"
    metadata = {
      name = "default"
    }
    spec = {
      credentials = {
        source = "Secret"
        secretRef = {
          namespace = kubernetes_namespace.crossplane_system[0].metadata[0].name
          name      = kubernetes_secret.aws_credentials[0].metadata[0].name
          key       = "creds"
        }
      }
    }
  })

  depends_on = [time_sleep.wait_for_providers]
}

# Outputs
output "namespace" {
  description = "Crossplane namespace"
  value       = var.enabled ? kubernetes_namespace.crossplane_system[0].metadata[0].name : null
}

output "helm_release_version" {
  description = "Deployed Helm chart version"
  value       = var.enabled ? helm_release.crossplane[0].version : null
}

output "helm_release_status" {
  description = "Helm release status"
  value       = var.enabled ? helm_release.crossplane[0].status : null
}
```

---

## 🚀 **Deployment Strategy**

### **Phase 1: Add Modules (No Branch Push)**

```bash
# 1. Create new addon modules (local development)
mkdir -p infrastructure/addons/terraform/modules/backstage
mkdir -p infrastructure/addons/terraform/modules/crossplane

# 2. Copy/create module files
# - modules/backstage/{main.tf, variables.tf, outputs.tf}
# - modules/crossplane/{main.tf, variables.tf, outputs.tf}

# 3. Update environment configuration
# - environments/azure-dev/main.tf (add module calls)
# - environments/azure-dev/terraform.tfvars (add plugin config)
# - environments/azure-dev/variables.tf (add variables)
```

### **Phase 2: Test Locally**

```bash
# 4. Test configuration locally
cd infrastructure/addons/terraform/environments/azure-dev

# 5. Initialize Terraform
terraform init

# 6. Plan deployment (with new modules disabled initially)
terraform plan

# 7. Enable modules one by one and test
# terraform.tfvars: backstage = { enabled = true }
# terraform.tfvars: crossplane = { enabled = true }
```

### **Phase 3: Deploy via Existing Workflow**

```bash
# 8. Use existing workflow to deploy
gh workflow run k8s-addons-terraform.yml \
  -f cluster_name=aks-msdp-dev-01 \
  -f environment=dev \
  -f cloud_provider=azure \
  -f action=plan

# 9. Apply when ready
gh workflow run k8s-addons-terraform.yml \
  -f cluster_name=aks-msdp-dev-01 \
  -f environment=dev \
  -f cloud_provider=azure \
  -f action=apply \
  -f auto_approve=true
```

---

## ✅ **Benefits of This Approach**

### **🔧 Leverages Existing Infrastructure:**
- ✅ **Reuses your proven addon pipeline**
- ✅ **Follows your established patterns**
- ✅ **No workflow changes needed**
- ✅ **Same validation and deployment process**

### **🎯 Modular and Maintainable:**
- ✅ **Each component is a separate module**
- ✅ **Can enable/disable independently**
- ✅ **Easy to update versions**
- ✅ **Clear dependency management**

### **🔒 Security and Compliance:**
- ✅ **Uses your existing OIDC authentication**
- ✅ **Follows your secret management patterns**
- ✅ **Same backend and state management**
- ✅ **Consistent tagging and labeling**

### **📊 Operational Consistency:**
- ✅ **Same monitoring and logging**
- ✅ **Same backup and disaster recovery**
- ✅ **Same troubleshooting procedures**
- ✅ **Unified addon management**

---

## 💡 **Next Steps**

1. **Review the proposal** and confirm the approach
2. **Create the module files** locally (I can provide complete files)
3. **Test locally** with Terraform plan/apply
4. **Deploy to dev environment** using existing workflow
5. **Validate integration** between ArgoCD, Backstage, and Crossplane
6. **Document the new addons** in your existing documentation

**This approach gives you platform engineering capabilities while maintaining your proven infrastructure patterns!** 🚀

**Would you like me to create the complete module files for this integration?**
