# Backstage Database Deployment Options

## 🎯 **Database Creation: Helm Chart vs External**

The official Backstage Helm chart provides **flexible database options** to suit different deployment needs.

---

## 🔧 **Option 1: Helm Chart Creates Database (Default)**

### **✅ Included PostgreSQL Deployment:**

```yaml
# values.yaml - Helm creates database automatically
postgresql:
  enabled: true  # ← Helm deploys PostgreSQL for you
  auth:
    username: backstage
    password: "secure-password"
    database: backstage
  primary:
    persistence:
      enabled: true
      size: 8Gi
      storageClass: "managed-csi"  # Azure managed storage
  
# Backstage automatically connects to this database
backstage:
  appConfig:
    backend:
      database:
        client: pg
        connection:
          host: "{{ include \"backstage.postgresql.host\" . }}"  # Auto-generated
          port: 5432
          user: "{{ .Values.postgresql.auth.username }}"
          password: "{{ .Values.postgresql.auth.password }}"
          database: "{{ .Values.postgresql.auth.database }}"
```

### **🏗️ What Helm Creates:**
```
🐳 KUBERNETES RESOURCES:
├── 📊 StatefulSet: PostgreSQL database pods
├── 🗄️ PersistentVolumeClaim: 8Gi storage
├── 🔒 Secret: Database credentials
├── 🌐 Service: Database network access
├── 🔧 ConfigMap: PostgreSQL configuration
└── 🔄 Init scripts: Database schema setup
```

### **✅ Benefits:**
- **🚀 Simple**: One Helm command deploys everything
- **🔧 Managed**: Helm handles database lifecycle
- **📦 Integrated**: Database and Backstage deployed together
- **🔒 Secure**: Credentials automatically generated
- **📊 Monitoring**: Database metrics included

### **❌ Limitations:**
- **💰 Cost**: Database runs continuously (not serverless)
- **🔧 Management**: You manage PostgreSQL maintenance
- **📈 Scaling**: Manual scaling configuration
- **🌍 Single AZ**: Not multi-region by default

---

## 🌐 **Option 2: External Database (Recommended for Production)**

### **✅ External Database Configuration:**

```yaml
# values.yaml - Use external database
postgresql:
  enabled: false  # ← Disable included PostgreSQL

# External database connection
backstage:
  appConfig:
    backend:
      database:
        client: pg
        connection:
          host: "your-external-db.com"
          port: 5432
          user: "backstage_user"
          password: "secure-password"
          database: "backstage"
          ssl:
            require: true
            rejectUnauthorized: false
```

### **🗄️ External Database Options:**

#### **Azure Database for PostgreSQL:**
```yaml
# Azure PostgreSQL Flexible Server
connection:
  host: "msdp-backstage.postgres.database.azure.com"
  port: 5432
  user: "backstage@msdp-backstage"
  password: "${AZURE_POSTGRES_PASSWORD}"
  database: "backstage"
  ssl:
    require: true
```

#### **AWS Aurora Serverless (Your Preference):**
```yaml
# AWS Aurora PostgreSQL Serverless v2
connection:
  host: "msdp-backstage-cluster.cluster-xyz.us-east-1.rds.amazonaws.com"
  port: 5432
  user: "backstage_admin"
  password: "${AURORA_PASSWORD}"
  database: "backstage"
  ssl:
    require: true
```

#### **Azure Cosmos DB (PostgreSQL API):**
```yaml
# Azure Cosmos DB with PostgreSQL compatibility
connection:
  host: "msdp-backstage-cosmos.postgres.cosmos.azure.com"
  port: 5432
  user: "backstage"
  password: "${COSMOS_PASSWORD}"
  database: "backstage"
  ssl:
    require: true
```

---

## 🎯 **Database Creation Methods Comparison**

### **📊 Comparison Matrix:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DATABASE DEPLOYMENT COMPARISON                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  🔧 HELM INCLUDED POSTGRESQL:                                              │
│  ├── ✅ Setup: Automatic with Helm install                                │
│  ├── ✅ Management: Helm handles lifecycle                                │
│  ├── ✅ Integration: Seamless with Backstage                              │
│  ├── ❌ Cost: Runs continuously (~$50/month)                              │
│  ├── ❌ Scaling: Manual configuration                                     │
│  └── ❌ Maintenance: You handle PostgreSQL updates                        │
│                                                                             │
│  ☁️ AZURE DATABASE FOR POSTGRESQL:                                        │
│  ├── ✅ Setup: Create separately, pass connection string                  │
│  ├── ✅ Management: Azure handles maintenance                             │
│  ├── ✅ Scaling: Automatic scaling options                                │
│  ├── ✅ Backup: Automated backups included                                │
│  ├── ❌ Cost: Fixed cost (~$100/month)                                    │
│  └── ✅ Integration: Good with Azure services                             │
│                                                                             │
│  🚀 AWS AURORA SERVERLESS V2:                                             │
│  ├── ✅ Setup: Create separately, pass connection string                  │
│  ├── ✅ Management: AWS handles everything                                │
│  ├── ✅ Scaling: True serverless (0.5-128 ACUs)                          │
│  ├── ✅ Cost: Pay-per-use (~$20-100/month)                               │
│  ├── ✅ Performance: Excellent for variable workloads                     │
│  └── ❌ Complexity: Cross-cloud networking                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 **Recommended Approach for MSDP**

### **🎯 Phased Database Strategy:**

#### **Phase 1: Start Simple (Helm Included)**
```yaml
# Initial deployment with included PostgreSQL
postgresql:
  enabled: true
  auth:
    username: backstage
    database: backstage
  primary:
    persistence:
      enabled: true
      size: 8Gi
```

**Benefits:**
- ✅ **Quick start**: Deploy in minutes
- ✅ **Simple**: No external setup needed
- ✅ **Testing**: Perfect for validation
- ✅ **Learning**: Understand Backstage first

#### **Phase 2: Move to External (Production)**
```yaml
# Later: Switch to external Aurora Serverless
postgresql:
  enabled: false

backstage:
  appConfig:
    backend:
      database:
        connection:
          host: "${AURORA_HOST}"
          # Connection via Kubernetes secret
```

**Benefits:**
- ✅ **Serverless**: Cost-effective scaling
- ✅ **Managed**: AWS handles maintenance
- ✅ **Performance**: Production-grade
- ✅ **Hybrid**: Fits your architecture

---

## 🔧 **Implementation Planning**

### **Immediate Approach (Helm Included DB):**
```bash
# Simple deployment with included database
helm repo add backstage https://backstage.github.io/charts
helm install msdp-backstage backstage/backstage \
  --namespace msdp-backstage \
  --create-namespace \
  --set postgresql.enabled=true
```

### **Future Migration (External Aurora):**
```bash
# 1. Create Aurora Serverless cluster
aws rds create-db-cluster --serverless-v2-scaling-configuration

# 2. Update Helm values
helm upgrade msdp-backstage backstage/backstage \
  --set postgresql.enabled=false \
  --set-string backstage.appConfig.backend.database.connection.host=aurora-endpoint

# 3. Migrate data from included PostgreSQL to Aurora
```

---

## 💡 **Recommendation for Your Setup**

### **🎯 Start with Helm Included, Migrate Later:**

1. **Phase 1**: Deploy with included PostgreSQL (quick start)
2. **Phase 2**: Test and validate Backstage functionality
3. **Phase 3**: Create AWS Aurora Serverless
4. **Phase 4**: Migrate to external Aurora (production-ready)

**This gives you:**
- ✅ **Immediate deployment** without external dependencies
- ✅ **Learning opportunity** to understand Backstage
- ✅ **Migration path** to your preferred Aurora Serverless
- ✅ **Cost optimization** when ready for production

**Both approaches are valid - Helm can create the database OR use your external Aurora Serverless!** 🗄️

**Which approach would you prefer to start with?** 🎯
