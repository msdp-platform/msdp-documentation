# Backstage Official Helm Chart Deployment Plan for AKS

## 🎯 **Official Backstage Helm Chart Analysis**

Based on the official [Backstage Helm Charts repository](https://github.com/backstage/charts), here's the proper deployment plan for your AKS cluster.

---

## 📊 **Official Helm Chart Benefits**

### **✅ Why Use Official Helm Charts:**

```
🏗️ OFFICIAL HELM CHART ADVANTAGES:
├── ✅ Production-ready configuration
├── ✅ Best practices built-in
├── ✅ Regular updates and security patches
├── ✅ Community-tested and validated
├── ✅ Proper resource management
├── ✅ Configurable for different environments
├── ✅ Supports external databases
└── ✅ Ingress and networking pre-configured
```

### **🔧 Chart Repository Information:**
- **Repository**: `https://backstage.github.io/charts`
- **Latest Version**: `backstage-2.6.1` (as of Aug 2025)
- **OCI Format**: `oci://ghcr.io/backstage/charts/backstage`
- **License**: Apache-2.0
- **Maintained by**: Backstage community

---

## 🏗️ **AKS Deployment Plan Using Official Helm Chart**

### **Phase 1: Preparation (No Code - Planning Only)**

#### **1.1: AKS Cluster Requirements**
```
🐳 AKS CLUSTER SPECIFICATIONS:
├── 📊 Minimum Nodes: 3 (already have ✅)
├── 💾 Node Size: Standard_B2s or higher (check current)
├── 🔧 Kubernetes Version: 1.28+ (you have 1.31.2 ✅)
├── 🔌 Add-ons Required:
│   ├── ✅ nginx-ingress (already installed)
│   ├── ✅ cert-manager (already installed)
│   ├── ✅ external-dns (already installed)
│   └── ✅ KEDA (already installed)
└── 🌐 Network: Standard networking (default)
```

#### **1.2: Prerequisites Validation**
```
✅ YOUR CURRENT AKS STATUS:
├── ✅ Cluster: aks-msdp-dev-01 (ready)
├── ✅ Nodes: 3 nodes running
├── ✅ Region: UK South
├── ✅ Essential plugins: All installed
├── ✅ kubectl access: Working
└── ✅ Helm: Need to verify installation
```

### **Phase 2: Helm Chart Configuration Planning**

#### **2.1: Official Chart Installation Method**
```bash
# Method 1: Chart Repository (Recommended)
helm repo add backstage https://backstage.github.io/charts
helm repo update
helm install msdp-backstage backstage/backstage

# Method 2: OCI Registry (Alternative)
helm install msdp-backstage oci://ghcr.io/backstage/charts/backstage --version=2.6.1
```

#### **2.2: MSDP-Specific Values Configuration**
```yaml
# values-msdp.yaml (Planning)
backstage:
  image:
    # Use official Backstage image or custom MSDP image
    repository: backstage/backstage
    tag: "latest"
  
  # MSDP-specific configuration
  appConfig:
    app:
      title: "MSDP Service Catalog"
      baseUrl: "https://backstage.msdp.platform"
    
    backend:
      baseUrl: "https://backstage-api.msdp.platform"
      database:
        # Option 1: Use included PostgreSQL
        client: pg
        connection:
          host: "{{ include \"backstage.postgresql.host\" . }}"
          port: 5432
        # Option 2: External Aurora Serverless (future)
        # connection:
        #   host: "aurora-cluster.amazonaws.com"
    
    auth:
      environment: production
      providers:
        guest: {}
        # Azure AD integration (future)
        # azureEasyAuth:
        #   signIn:
        #     resolvers:
        #       - resolver: emailMatchingUserEntityName

# PostgreSQL configuration
postgresql:
  enabled: true  # Use included PostgreSQL initially
  auth:
    username: backstage
    database: backstage
  primary:
    persistence:
      enabled: true
      size: 8Gi

# Ingress configuration
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: backstage.msdp.platform
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: backstage-tls
      hosts:
        - backstage.msdp.platform

# Service configuration
service:
  type: ClusterIP
  ports:
    backend: 7007
    frontend: 3000
```

#### **2.3: MSDP Service Catalog Integration**
```yaml
# MSDP catalog configuration (Planning)
catalog:
  rules:
    - allow: [Component, System, API, Resource, Location, User, Group, Template]
  
  locations:
    # MSDP services from GitHub repositories
    - type: url
      target: https://github.com/msdp-platform/msdp-platform-core/blob/dev/backstage-platform/catalog/msdp-services.yaml
    
    # MSDP teams and users
    - type: url
      target: https://github.com/msdp-platform/msdp-platform-core/blob/dev/backstage-platform/catalog/msdp-teams.yaml
    
    # MSDP templates
    - type: url
      target: https://github.com/msdp-platform/msdp-platform-core/blob/dev/backstage-platform/templates/

# Proxy configuration for MSDP services
proxy:
  '/api/msdp':
    # Initially point to your laptop for testing
    target: 'http://192.168.1.189:3000'
    changeOrigin: true
    # Later: point to AWS Lambda/API Gateway
    # target: 'https://api.msdp.platform'
```

---

## 🎯 **Deployment Strategy Planning**

### **Phase 1: Basic Helm Deployment (Week 1)**

#### **Day 1-2: Environment Preparation**
```
📋 PREPARATION TASKS:
├── Verify Helm installation on local machine
├── Add official Backstage Helm repository
├── Review official chart documentation
├── Plan MSDP-specific values configuration
└── Prepare namespace and RBAC settings
```

#### **Day 3-4: Initial Deployment**
```
🚀 DEPLOYMENT TASKS:
├── Create msdp-backstage namespace
├── Deploy with minimal configuration
├── Verify basic functionality
├── Test ingress and external access
└── Validate all pods are running
```

#### **Day 5-7: MSDP Integration**
```
🔧 INTEGRATION TASKS:
├── Add MSDP service catalog
├── Configure API proxies to laptop services
├── Set up authentication (guest initially)
├── Test service discovery
└── Validate complete functionality
```

### **Phase 2: Production Configuration (Week 2)**

#### **Database Integration Planning**
```
🗄️ DATABASE OPTIONS:
├── Option 1: Included PostgreSQL (Helm chart default)
│   ├── Pros: Simple, managed by Helm
│   ├── Cons: Not serverless, fixed costs
│   └── Use for: Initial deployment and testing
│
├── Option 2: Azure Database for PostgreSQL
│   ├── Pros: Azure native, good integration
│   ├── Cons: Fixed costs, not serverless
│   └── Use for: Azure-focused deployment
│
├── Option 3: AWS Aurora Serverless (Your preference)
│   ├── Pros: True serverless, cost-effective
│   ├── Cons: Cross-cloud complexity
│   └── Use for: Production hybrid architecture
```

#### **Authentication Integration Planning**
```
🔐 AUTHENTICATION OPTIONS:
├── Option 1: Guest (current)
├── Option 2: Azure AD (Azure native)
├── Option 3: GitHub OAuth (developer-friendly)
├── Option 4: AWS Cognito (if using AWS backend)
└── Recommendation: Start with guest, add Azure AD later
```

### **Phase 3: Hybrid Cloud Integration (Week 3)**

#### **AWS Backend Integration Planning**
```
🔗 AWS INTEGRATION:
├── Update proxy configuration to point to AWS API Gateway
├── Configure authentication for cross-cloud access
├── Set up monitoring for hybrid architecture
├── Implement health checks for AWS services
└── Configure failover and disaster recovery
```

---

## 📋 **Helm Chart Configuration Planning**

### **Namespace Strategy:**
```yaml
# Dedicated namespace for MSDP Backstage
apiVersion: v1
kind: Namespace
metadata:
  name: msdp-backstage
  labels:
    name: msdp-backstage
    app.kubernetes.io/name: backstage
    app.kubernetes.io/instance: msdp
```

### **Resource Planning:**
```yaml
# Resource allocation planning
resources:
  backend:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "500m"
  
  frontend:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "250m"

# Scaling configuration
replicaCount: 2  # High availability
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### **Storage Planning:**
```yaml
# Persistent storage for Backstage data
persistence:
  enabled: true
  storageClass: "managed-csi"  # Azure managed storage
  size: 10Gi
  accessMode: ReadWriteOnce
```

---

## 🌐 **Network and Security Planning**

### **Ingress Configuration:**
```yaml
# External access planning
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: backstage.msdp.platform
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: backstage-tls
      hosts:
        - backstage.msdp.platform
```

### **Security Configuration:**
```yaml
# Security planning
serviceAccount:
  create: true
  annotations:
    azure.workload.identity/client-id: "client-id"

podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
```

---

## 🎯 **Integration with Your Hybrid Architecture**

### **Azure Web Portals + AWS Backend Integration:**

```yaml
# Backstage configuration for hybrid cloud
appConfig:
  proxy:
    # AWS Lambda functions (future)
    '/api/location':
      target: 'https://api.msdp.platform/location'
      changeOrigin: true
      headers:
        Authorization: 'Bearer ${AWS_API_TOKEN}'
    
    '/api/merchant':
      target: 'https://api.msdp.platform/merchant'
      changeOrigin: true
    
    # During migration - point to laptop services
    '/api/location-local':
      target: 'http://192.168.1.189:3001'
      changeOrigin: true

  catalog:
    providers:
      # Auto-discovery from AWS API Gateway
      aws:
        production:
          region: us-east-1
          apiGatewayArn: "arn:aws:apigateway:us-east-1::/restapis/xyz"
```

---

## 💡 **Deployment Planning Recommendations**

### **🎯 Phased Approach:**

#### **Phase 1: Official Helm Deployment**
```
📋 WEEK 1 PLAN:
├── Day 1: Install Helm, add Backstage repo
├── Day 2: Deploy with minimal configuration
├── Day 3: Configure ingress and external access
├── Day 4: Add MSDP service catalog
├── Day 5: Test and validate functionality
```

#### **Phase 2: Hybrid Integration**
```
📋 WEEK 2 PLAN:
├── Day 1: Set up AWS Aurora Serverless test
├── Day 2: Migrate one database (User Service)
├── Day 3: Test hybrid connectivity
├── Day 4: Configure Backstage for AWS integration
├── Day 5: Validate hybrid architecture
```

#### **Phase 3: Production Readiness**
```
📋 WEEK 3 PLAN:
├── Day 1: Configure Azure AD authentication
├── Day 2: Set up TLS certificates and security
├── Day 3: Configure monitoring and alerting
├── Day 4: Performance testing and optimization
├── Day 5: Documentation and runbooks
```

---

## 🔧 **Technical Planning Considerations**

### **Helm Chart Customization:**
```
🎛️ CUSTOMIZATION AREAS:
├── MSDP-specific branding and theming
├── Custom plugins for location management
├── Integration with AWS services
├── Azure AD authentication setup
├── Custom service catalog providers
├── MSDP-specific templates and workflows
└── Monitoring and observability integration
```

### **Configuration Management:**
```
⚙️ CONFIGURATION STRATEGY:
├── values-dev.yaml (development environment)
├── values-staging.yaml (staging environment)
├── values-prod.yaml (production environment)
├── secrets.yaml (sensitive configuration)
└── configmaps.yaml (environment-specific settings)
```

### **Backup and Disaster Recovery:**
```
🔒 DR PLANNING:
├── Database backups to Azure Storage
├── Configuration backup to Git
├── Cross-region deployment capability
├── Automated failover procedures
└── Recovery time objectives (RTO/RPO)
```

---

## 🎯 **Integration with Your Hybrid Strategy**

### **Azure AKS (Web Layer) + AWS Serverless (API Layer):**

```
🔗 INTEGRATION POINTS:
├── Backstage in AKS manages AWS Lambda functions
├── Service catalog discovers AWS API Gateway endpoints
├── Authentication flows between Azure AD and AWS
├── Monitoring aggregates metrics from both clouds
├── Templates create resources in both environments
└── Single interface for hybrid infrastructure management
```

### **Benefits of Official Helm Chart for Hybrid:**
```
✅ HYBRID CLOUD BENEFITS:
├── Standard deployment patterns
├── Easy integration with external services
├── Configurable for multi-cloud environments
├── Production-ready security and networking
├── Scalable and maintainable
├── Community support and updates
└── Enterprise-grade reliability
```

---

## 📋 **Pre-Deployment Checklist**

### **Before Implementation:**
- [ ] **Verify Helm installation** on local machine
- [ ] **Check AKS cluster permissions** for Helm deployments
- [ ] **Plan namespace strategy** (msdp-backstage vs msdp-platform)
- [ ] **Design values.yaml** for MSDP-specific configuration
- [ ] **Plan ingress domain names** (backstage.msdp.platform)
- [ ] **Prepare SSL certificate strategy** (Let's Encrypt vs Azure certificates)
- [ ] **Design secret management** (Azure Key Vault integration)
- [ ] **Plan monitoring integration** (Azure Monitor + Backstage)

### **Configuration Planning:**
- [ ] **MSDP service catalog structure**
- [ ] **API proxy configuration** for laptop services (initial)
- [ ] **Authentication provider selection** (guest → Azure AD)
- [ ] **Database connection planning** (included PostgreSQL → Aurora)
- [ ] **Backup and recovery procedures**
- [ ] **Scaling and resource limits**
- [ ] **Security policies and network rules**

---

## 🎯 **Recommended Next Steps**

### **1. Verify Prerequisites:**
```bash
# Check if Helm is installed
helm version

# Check AKS cluster access
kubectl cluster-info

# Check available storage classes
kubectl get storageclass
```

### **2. Plan Configuration:**
- **Design values.yaml** for MSDP-specific settings
- **Plan ingress and domain strategy**
- **Design authentication approach**
- **Plan database integration** (local → AWS Aurora)

### **3. Prepare Deployment:**
- **Create namespace and RBAC**
- **Prepare secrets and configmaps**
- **Plan rollback strategy**
- **Design testing and validation procedures**

---

## 💡 **Strategic Benefits**

### **✅ Using Official Helm Chart:**
- **🏗️ Production-ready** out of the box
- **🔧 Easy maintenance** with chart updates
- **📚 Community support** and documentation
- **🔒 Security best practices** built-in
- **⚙️ Configurable** for MSDP requirements
- **🚀 Scalable** for enterprise deployment

### **✅ Perfect for Your Hybrid Strategy:**
- **Azure AKS**: Professional web portal hosting
- **AWS Backend**: Serverless API integration ready
- **Aurora Database**: Easy external database configuration
- **Global Scale**: Multi-region deployment capable

**This official Helm chart approach is the proper enterprise way to deploy Backstage to your AKS cluster!**

**Should we proceed with the detailed implementation planning using the official Helm charts?** 🚀
