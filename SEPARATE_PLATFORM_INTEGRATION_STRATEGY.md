# Integrating ArgoCD + Backstage + Crossplane (Separate Installations)

## 🎯 **Integration Strategy for Separately Deployed Components**

When ArgoCD, Backstage, and Crossplane are installed via different pipelines, they need **integration configuration** to work together as a unified platform.

---

## 🔗 **Integration Architecture**

### **🏗️ How They Communicate:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SEPARATE BUT INTEGRATED PLATFORM                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  🎛️ BACKSTAGE (Separate Pipeline):                                         │
│  ├── Namespace: backstage                                                  │
│  ├── Service: backstage-service:3000                                       │
│  ├── API: backstage-service:7007                                           │
│  └── Database: backstage-postgresql                                        │
│                                    │                                       │
│                                    ▼ API Calls                            │
│  🚀 ARGOCD (Existing Addon Pipeline):                                     │
│  ├── Namespace: argocd                                                     │
│  ├── Service: argocd-server:80                                             │
│  ├── API: argocd-server:443                                                │
│  └── Database: argocd-redis                                                │
│                                    │                                       │
│                                    ▼ Resource Management                   │
│  ⚡ CROSSPLANE (Platform Engineering Pipeline):                           │
│  ├── Namespace: crossplane-system                                          │
│  ├── API: crossplane:8080                                                  │
│  ├── Providers: Azure, AWS, Kubernetes                                     │
│  └── Compositions: Infrastructure templates                                │
│                                                                             │
│  🔗 INTEGRATION POINTS:                                                    │
│  ├── Backstage → ArgoCD API (application discovery)                       │
│  ├── Backstage → Crossplane API (resource status)                         │
│  ├── ArgoCD → Crossplane Resources (deploy infrastructure)                │
│  └── Shared RBAC and authentication                                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 **Integration Configuration**

### **1. Backstage → ArgoCD Integration**

#### **Backstage Configuration (app-config.yaml):**
```yaml
# Backstage integrates with existing ArgoCD
argocd:
  baseUrl: 'https://argocd.msdp.platform'  # Your existing ArgoCD
  apiVersion: 'v1alpha1'
  instances:
    - name: 'msdp-argocd'
      url: 'https://argocd.msdp.platform'
      token: '${ARGOCD_AUTH_TOKEN}'  # Service account token

# Catalog provider for ArgoCD applications
catalog:
  providers:
    argocd:
      msdp-production:
        baseUrl: 'https://argocd.msdp.platform'
        schedule:
          frequency: { minutes: 5 }
        filters:
          - labelSelector: 'app.kubernetes.io/part-of=msdp'

# Proxy for ArgoCD API access
proxy:
  '/argocd/api':
    target: 'https://argocd.msdp.platform'
    changeOrigin: true
    headers:
      Authorization: 'Bearer ${ARGOCD_AUTH_TOKEN}'
```

#### **ArgoCD Service Account for Backstage:**
```yaml
# Create in ArgoCD namespace
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backstage-argocd-reader
  namespace: argocd
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backstage-argocd-reader
rules:
- apiGroups: ["argoproj.io"]
  resources: ["applications", "appprojects"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: backstage-argocd-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: backstage-argocd-reader
subjects:
- kind: ServiceAccount
  name: backstage-argocd-reader
  namespace: argocd
```

### **2. Backstage → Crossplane Integration**

#### **Backstage Configuration for Crossplane:**
```yaml
# Crossplane integration in Backstage
catalog:
  providers:
    crossplane:
      msdp-production:
        baseUrl: 'https://crossplane-api.msdp.platform'
        schedule:
          frequency: { minutes: 10 }
        filters:
          - labelSelector: 'msdp.platform/managed-by=crossplane'

# Proxy for Crossplane API
proxy:
  '/crossplane/api':
    target: 'http://crossplane.crossplane-system:8080'
    changeOrigin: true

# Templates that trigger Crossplane resources
scaffolder:
  defaultAuthor:
    name: MSDP Platform
    email: platform@msdp.local
  
  # Custom actions for Crossplane
  actions:
    - id: 'crossplane:create-aurora'
      description: 'Create Aurora Serverless cluster via Crossplane'
      action: 'http:request'
      input:
        method: 'POST'
        url: 'http://crossplane.crossplane-system:8080/v1/compositeresources'
        headers:
          'Content-Type': 'application/json'
        body:
          apiVersion: 'msdp.platform/v1alpha1'
          kind: 'XAuroraServerless'
          metadata:
            name: '{{ parameters.clusterName }}'
          spec:
            parameters:
              region: '{{ parameters.region }}'
              minCapacity: 0.5
              maxCapacity: 16
```

#### **Crossplane Service Account for Backstage:**
```yaml
# Create in crossplane-system namespace
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backstage-crossplane-reader
  namespace: crossplane-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backstage-crossplane-reader
rules:
- apiGroups: ["apiextensions.crossplane.io"]
  resources: ["compositions", "compositeresourcedefinitions"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
  resourceNames: ["crossplane-*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: backstage-crossplane-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: backstage-crossplane-reader
subjects:
- kind: ServiceAccount
  name: backstage-crossplane-reader
  namespace: crossplane-system
```

### **3. ArgoCD → Crossplane Integration**

#### **ArgoCD Application for Crossplane Resources:**
```yaml
# MSDP Infrastructure Application in ArgoCD
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: msdp-infrastructure
  namespace: argocd
  labels:
    app.kubernetes.io/part-of: msdp-platform
spec:
  project: msdp
  
  source:
    repoURL: https://github.com/msdp-platform/msdp-platform-core
    targetRevision: dev
    path: k8s/crossplane-resources
  
  destination:
    server: https://kubernetes.default.svc
    namespace: crossplane-system
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ApplyOutOfSyncOnly=true
  
  # Health checks for Crossplane resources
  ignoreDifferences:
  - group: apiextensions.crossplane.io
    kind: Composition
    jsonPointers:
    - /metadata/generation
```

#### **ArgoCD Project for MSDP:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: msdp
  namespace: argocd
spec:
  description: "MSDP Platform Applications and Infrastructure"
  
  sourceRepos:
  - 'https://github.com/msdp-platform/*'
  
  destinations:
  - namespace: 'msdp-*'
    server: https://kubernetes.default.svc
  - namespace: 'backstage'
    server: https://kubernetes.default.svc
  - namespace: 'crossplane-system'
    server: https://kubernetes.default.svc
  
  clusterResourceWhitelist:
  - group: 'apiextensions.crossplane.io'
    kind: '*'
  - group: 'pkg.crossplane.io'
    kind: '*'
  
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
```

---

## 🔄 **End-to-End Integration Workflow**

### **🌍 Example: Enable Singapore Location**

```
1. 🎛️ BACKSTAGE (User Action):
   ├── Admin uses "Enable Singapore" template
   ├── Template calls Crossplane API
   ├── Creates CompositeResource definition
   └── Commits infrastructure manifest to Git

2. ⚡ CROSSPLANE (Infrastructure Provisioning):
   ├── Detects new XAuroraServerless resource
   ├── Provisions AWS Aurora cluster in ap-southeast-1
   ├── Creates VPC, security groups, networking
   ├── Updates resource status
   └── Infrastructure ready in 10 minutes

3. 🚀 ARGOCD (Application Deployment):
   ├── Detects new application manifest in Git
   ├── Deploys MSDP services to Singapore cluster
   ├── Uses Crossplane-provisioned infrastructure
   ├── Monitors deployment health
   └── Services live in 5 minutes

4. 📊 BACKSTAGE (Status Update):
   ├── Discovers new ArgoCD applications
   ├── Shows Crossplane resource status
   ├── Updates service catalog
   ├── Notifies teams of completion
   └── Singapore visible in catalog
```

---

## 🔧 **Integration Setup Steps**

### **Step 1: Create Integration Secrets**

```bash
# ArgoCD API token for Backstage
kubectl create secret generic argocd-integration \
  --from-literal=token=$(argocd account generate-token --account backstage) \
  -n backstage

# Crossplane API access for Backstage
kubectl create secret generic crossplane-integration \
  --from-literal=endpoint=http://crossplane.crossplane-system:8080 \
  -n backstage
```

### **Step 2: Configure Service Discovery**

```yaml
# Backstage discovers ArgoCD applications
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-discovery
  namespace: backstage
data:
  config.yaml: |
    argocd:
      baseUrl: 'https://argocd.msdp.platform'
      instances:
        - name: 'msdp-cluster'
          url: 'https://argocd.msdp.platform'
          tokenRef:
            secretName: argocd-integration
            key: token
```

### **Step 3: Configure Cross-Component RBAC**

```yaml
# Shared RBAC for platform components
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: msdp-platform-integration
rules:
# Backstage reads ArgoCD applications
- apiGroups: ["argoproj.io"]
  resources: ["applications", "appprojects"]
  verbs: ["get", "list", "watch"]

# Backstage reads Crossplane resources
- apiGroups: ["apiextensions.crossplane.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]

# ArgoCD manages Crossplane resources
- apiGroups: ["apiextensions.crossplane.io"]
  resources: ["*"]
  verbs: ["*"]
```

### **Step 4: Configure Shared Monitoring**

```yaml
# Prometheus scrape configs for all components
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-platform-config
  namespace: monitoring
data:
  platform-scrape-configs.yaml: |
    scrape_configs:
    # Backstage metrics
    - job_name: 'backstage'
      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ['backstage']
    
    # ArgoCD metrics
    - job_name: 'argocd'
      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ['argocd']
    
    # Crossplane metrics
    - job_name: 'crossplane'
      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ['crossplane-system']
```

---

## 🎯 **Integration Patterns**

### **Pattern 1: Service Discovery Integration**

```yaml
# Each component discovers others via Kubernetes services
apiVersion: v1
kind: Service
metadata:
  name: platform-integration
  namespace: msdp-platform
spec:
  type: ExternalName
  externalName: backstage-service.backstage.svc.cluster.local
  ports:
  - port: 3000
    name: backstage-frontend
  - port: 7007
    name: backstage-api
---
apiVersion: v1
kind: Service
metadata:
  name: argocd-integration
  namespace: msdp-platform
spec:
  type: ExternalName
  externalName: argocd-server.argocd.svc.cluster.local
  ports:
  - port: 80
    name: argocd-api
---
apiVersion: v1
kind: Service
metadata:
  name: crossplane-integration
  namespace: msdp-platform
spec:
  type: ExternalName
  externalName: crossplane.crossplane-system.svc.cluster.local
  ports:
  - port: 8080
    name: crossplane-api
```

### **Pattern 2: Event-Driven Integration**

```yaml
# Crossplane publishes events that ArgoCD and Backstage consume
apiVersion: v1
kind: ConfigMap
metadata:
  name: integration-events
  namespace: msdp-platform
data:
  event-config.yaml: |
    events:
      crossplane:
        # When Crossplane creates infrastructure
        resource_ready:
          webhook: 'http://backstage-service.backstage:7007/api/webhooks/crossplane'
          payload:
            resource_type: '{{ .resource.kind }}'
            resource_name: '{{ .resource.metadata.name }}'
            status: 'ready'
      
      argocd:
        # When ArgoCD deploys applications
        app_synced:
          webhook: 'http://backstage-service.backstage:7007/api/webhooks/argocd'
          payload:
            app_name: '{{ .app.metadata.name }}'
            sync_status: '{{ .app.status.sync.status }}'
```

### **Pattern 3: Shared Configuration**

```yaml
# Shared ConfigMap for platform-wide settings
apiVersion: v1
kind: ConfigMap
metadata:
  name: msdp-platform-config
  namespace: msdp-platform
data:
  # Shared endpoints
  backstage_url: 'https://backstage.msdp.platform'
  argocd_url: 'https://argocd.msdp.platform'
  crossplane_api: 'http://crossplane.crossplane-system:8080'
  
  # MSDP service endpoints (for all components to use)
  msdp_api_gateway: 'http://192.168.1.189:3000'
  msdp_location_service: 'http://192.168.1.189:3001'
  msdp_merchant_service: 'http://192.168.1.189:3002'
  msdp_user_service: 'http://192.168.1.189:3003'
  msdp_order_service: 'http://192.168.1.189:3006'
  msdp_payment_service: 'http://192.168.1.189:3007'
  
  # Future: AWS Lambda endpoints
  # msdp_location_service: 'https://api.msdp.platform/location'
```

---

## 🚀 **Integration Implementation Steps**

### **Step 1: Deploy Components Separately**

```bash
# 1. Deploy ArgoCD (your existing addon pipeline)
gh workflow run addons.yml -f addon=argocd -f action=apply

# 2. Deploy Crossplane (platform engineering pipeline)
gh workflow run platform-engineering.yml -f component=crossplane -f action=apply

# 3. Deploy Backstage (platform engineering pipeline)
gh workflow run platform-engineering.yml -f component=backstage -f action=apply
```

### **Step 2: Configure Integration**

```bash
# Create integration namespace
kubectl create namespace msdp-platform

# Apply integration configurations
kubectl apply -f integration/service-discovery.yaml
kubectl apply -f integration/rbac-integration.yaml
kubectl apply -f integration/shared-config.yaml
```

### **Step 3: Configure Backstage Integration**

```bash
# Update Backstage configuration
kubectl patch configmap backstage-app-config -n backstage --patch '
data:
  app-config.yaml: |
    # Include ArgoCD and Crossplane integration
    argocd:
      baseUrl: "https://argocd.msdp.platform"
    
    catalog:
      providers:
        argocd:
          production:
            baseUrl: "https://argocd.msdp.platform"
        crossplane:
          production:
            baseUrl: "http://crossplane.crossplane-system:8080"
'

# Restart Backstage to pick up new config
kubectl rollout restart deployment/backstage -n backstage
```

### **Step 4: Configure ArgoCD for Crossplane**

```bash
# Add Crossplane resource health checks to ArgoCD
kubectl patch configmap argocd-cm -n argocd --patch '
data:
  resource.customizations.health.apiextensions.crossplane.io_Composition: |
    hs = {}
    if obj.status ~= nil and obj.status.conditions ~= nil then
      for i, condition in ipairs(obj.status.conditions) do
        if condition.type == "Offered" and condition.status == "True" then
          hs.status = "Healthy"
          hs.message = "Composition is ready"
          return hs
        end
      end
    end
    hs.status = "Progressing"
    hs.message = "Composition not ready"
    return hs
'
```

---

## 📊 **Integration Validation**

### **✅ How to Verify Integration Works:**

#### **1. Backstage Integration Check:**
```bash
# Check if Backstage can see ArgoCD applications
curl -H "Authorization: Bearer $BACKSTAGE_TOKEN" \
  https://backstage.msdp.platform/api/catalog/entities?filter=kind=component,metadata.annotations.argocd.argoproj.io/app-name

# Check if Backstage can see Crossplane resources
curl -H "Authorization: Bearer $BACKSTAGE_TOKEN" \
  https://backstage.msdp.platform/api/catalog/entities?filter=kind=resource,metadata.labels.crossplane.io/managed=true
```

#### **2. ArgoCD Integration Check:**
```bash
# Check if ArgoCD can manage Crossplane resources
argocd app list | grep crossplane

# Check if ArgoCD applications appear in Backstage
kubectl get applications -n argocd -o jsonpath='{.items[*].metadata.name}'
```

#### **3. Crossplane Integration Check:**
```bash
# Check if Crossplane resources are healthy
kubectl get compositions
kubectl get providers
kubectl get compositeresourcedefinitions
```

---

## 🎯 **Benefits of Separate Installation + Integration**

### **✅ Advantages:**

```
🔧 DEPLOYMENT FLEXIBILITY:
├── ✅ Independent upgrade cycles
├── ✅ Component-specific configuration
├── ✅ Isolated troubleshooting
├── ✅ Different teams can manage different components
└── ✅ No single point of failure

🚀 OPERATIONAL BENEFITS:
├── ✅ Existing ArgoCD pipeline preserved
├── ✅ Platform engineering stack focused
├── ✅ Clear separation of concerns
├── ✅ Easy to add/remove components
└── ✅ Follows your DevOps patterns
```

### **🔗 Integration Benefits:**
- **Unified Interface**: Backstage shows all platform components
- **Automated Workflows**: Templates trigger Crossplane + ArgoCD
- **Service Discovery**: All components visible in catalog
- **Shared Authentication**: Single sign-on across platform
- **Coordinated Monitoring**: Unified observability

---

## 💡 **Recommended Integration Approach**

### **🎯 Phase 1: Basic Integration**
1. **Deploy components** via separate pipelines
2. **Configure service discovery** between components
3. **Set up basic RBAC** for cross-component access
4. **Test basic integration** functionality

### **🎯 Phase 2: Advanced Integration**
1. **Configure Backstage templates** to trigger Crossplane
2. **Set up ArgoCD applications** for Crossplane resources
3. **Implement event-driven workflows**
4. **Add shared monitoring and alerting**

### **🎯 Phase 3: Production Integration**
1. **Shared authentication** (Azure AD across all components)
2. **Advanced RBAC** and security policies
3. **Cross-component backup** and disaster recovery
4. **Performance optimization** and scaling

**This approach gives you maximum flexibility while maintaining tight integration between all platform components!** 🚀

**Would you like me to create the specific integration configurations for your existing ArgoCD installation?**
