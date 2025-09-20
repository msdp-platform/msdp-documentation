# Backstage Kubernetes Deployment for MSDP

## 🎯 **Why Kubernetes for Backstage?**

### **✅ Perfect Solution for Your Concerns:**

```
🐳 KUBERNETES BENEFITS:
├── ✅ No hardcoded IPs: Service discovery via DNS
├── ✅ Environment variables: ConfigMaps and Secrets
├── ✅ Modular configuration: Environment-specific deployments
├── ✅ Auto-scaling: Handle load automatically
├── ✅ High availability: Multiple replicas
├── ✅ Production-ready: Enterprise-grade deployment
└── ✅ GitOps ready: Perfect for ArgoCD integration later
```

---

## 🏗️ **Kubernetes Deployment Architecture**

### **MSDP + Backstage in Kubernetes:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MSDP KUBERNETES CLUSTER                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  🎛️ BACKSTAGE NAMESPACE                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ 🏠 Backstage Frontend (Service)                                    │   │
│  │ ├── Deployment: backstage-frontend                                 │   │
│  │ ├── Service: backstage-frontend-svc                                │   │
│  │ ├── Port: 3000                                                     │   │
│  │ └── Ingress: backstage.msdp.local                                  │   │
│  │                                                                     │   │
│  │ 🔧 Backstage Backend (Service)                                     │   │
│  │ ├── Deployment: backstage-backend                                  │   │
│  │ ├── Service: backstage-backend-svc                                 │   │
│  │ ├── Port: 7007                                                     │   │
│  │ └── ConfigMap: backstage-config                                    │   │
│  │                                                                     │   │
│  │ 🗄️ PostgreSQL Database                                             │   │
│  │ ├── StatefulSet: backstage-postgres                                │   │
│  │ ├── Service: backstage-postgres-svc                                │   │
│  │ ├── PVC: backstage-postgres-data                                   │   │
│  │ └── Secret: backstage-postgres-secret                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  🚀 MSDP SERVICES NAMESPACE                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ 🌍 Location Service    🏪 Merchant Service    👥 User Service       │   │
│  │ 📦 Order Service      💳 Payment Service     🔗 API Gateway        │   │
│  │ 🎨 Customer App       🏪 VendaBuddy          🎛️ Admin Dashboard     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  🔍 Service Discovery: DNS-based (no hardcoded IPs)                       │
│  📊 Configuration: ConfigMaps and Secrets                                  │
│  🌐 Networking: Kubernetes Services and Ingress                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🐳 **Step 1: Containerize Backstage**

### **1.1: Create Backstage Dockerfile**

```dockerfile
# Dockerfile.backstage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json yarn.lock ./
COPY packages/app/package.json ./packages/app/
COPY packages/backend/package.json ./packages/backend/

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN yarn build:backend

# Production stage
FROM node:20-alpine AS runtime

# Create app user
RUN addgroup --gid 1001 --system backstage && \
    adduser --uid 1001 --system --ingroup backstage backstage

WORKDIR /app

# Copy built application
COPY --from=builder --chown=backstage:backstage /app/packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# Copy configuration template
COPY --chown=backstage:backstage app-config.kubernetes.yaml ./app-config.production.yaml

USER backstage

EXPOSE 7007

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:7007/api/catalog/health || exit 1

CMD ["node", "packages/backend", "--config", "app-config.production.yaml"]
```

### **1.2: Kubernetes Configuration Template**

```yaml
# app-config.kubernetes.yaml
app:
  title: MSDP Service Catalog
  baseUrl: ${BACKSTAGE_BASE_URL}

backend:
  baseUrl: ${BACKSTAGE_BACKEND_URL}
  listen:
    port: 7007
    host: 0.0.0.0
  
  database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
      database: ${POSTGRES_DB}

auth:
  environment: ${AUTH_ENVIRONMENT}
  providers:
    guest: {}
    github:
      production:
        clientId: ${GITHUB_CLIENT_ID}
        clientSecret: ${GITHUB_CLIENT_SECRET}

catalog:
  rules:
    - allow: [Component, System, API, Resource, Location, User, Group, Template]
  
  providers:
    msdp:
      production:
        baseUrl: ${MSDP_GATEWAY_URL}
        schedule:
          frequency: { minutes: 5 }

# Dynamic service discovery
proxy:
  '/api/msdp':
    target: ${MSDP_GATEWAY_URL}
    changeOrigin: true
  '/api/location':
    target: http://location-service.msdp:3001
    changeOrigin: true
  '/api/merchant':
    target: http://merchant-service.msdp:3002
    changeOrigin: true
  '/api/user':
    target: http://user-service.msdp:3003
    changeOrigin: true
  '/api/order':
    target: http://order-service.msdp:3006
    changeOrigin: true
  '/api/payment':
    target: http://payment-service.msdp:3007
    changeOrigin: true
```

---

## ⚙️ **Step 2: Kubernetes Manifests**

### **2.1: Namespace and ConfigMap**

```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: backstage
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: backstage-config
  namespace: backstage
data:
  BACKSTAGE_BASE_URL: "http://backstage.msdp.local"
  BACKSTAGE_BACKEND_URL: "http://backstage-api.msdp.local"
  MSDP_GATEWAY_URL: "http://api-gateway.msdp:3000"
  AUTH_ENVIRONMENT: "production"
  POSTGRES_HOST: "backstage-postgres-svc"
  POSTGRES_PORT: "5432"
  POSTGRES_DB: "backstage"
  POSTGRES_USER: "backstage"
```

### **2.2: Secrets**

```yaml
# k8s/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: backstage-secrets
  namespace: backstage
type: Opaque
stringData:
  POSTGRES_PASSWORD: "secure_password_here"
  GITHUB_CLIENT_ID: "your_github_client_id"
  GITHUB_CLIENT_SECRET: "your_github_client_secret"
  GITHUB_TOKEN: "your_github_token"
```

### **2.3: PostgreSQL Database**

```yaml
# k8s/postgres.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: backstage-postgres
  namespace: backstage
spec:
  serviceName: backstage-postgres-svc
  replicas: 1
  selector:
    matchLabels:
      app: backstage-postgres
  template:
    metadata:
      labels:
        app: backstage-postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: backstage-config
              key: POSTGRES_DB
        - name: POSTGRES_USER
          valueFrom:
            configMapKeyRef:
              name: backstage-config
              key: POSTGRES_USER
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: backstage-secrets
              key: POSTGRES_PASSWORD
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: backstage-postgres-svc
  namespace: backstage
spec:
  selector:
    app: backstage-postgres
  ports:
  - port: 5432
    targetPort: 5432
```

### **2.4: Backstage Backend Deployment**

```yaml
# k8s/backstage-backend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backstage-backend
  namespace: backstage
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backstage-backend
  template:
    metadata:
      labels:
        app: backstage-backend
    spec:
      containers:
      - name: backstage
        image: msdp/backstage:latest
        ports:
        - containerPort: 7007
        env:
        - name: NODE_ENV
          value: "production"
        envFrom:
        - configMapRef:
            name: backstage-config
        - secretRef:
            name: backstage-secrets
        livenessProbe:
          httpGet:
            path: /api/catalog/health
            port: 7007
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/catalog/health
            port: 7007
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: backstage-backend-svc
  namespace: backstage
spec:
  selector:
    app: backstage-backend
  ports:
  - port: 7007
    targetPort: 7007
```

### **2.5: Backstage Frontend Deployment**

```yaml
# k8s/backstage-frontend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backstage-frontend
  namespace: backstage
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backstage-frontend
  template:
    metadata:
      labels:
        app: backstage-frontend
    spec:
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 3000
        volumeMounts:
        - name: frontend-assets
          mountPath: /usr/share/nginx/html
      volumes:
      - name: frontend-assets
        configMap:
          name: backstage-frontend-assets
---
apiVersion: v1
kind: Service
metadata:
  name: backstage-frontend-svc
  namespace: backstage
spec:
  selector:
    app: backstage-frontend
  ports:
  - port: 3000
    targetPort: 3000
```

### **2.6: Ingress for External Access**

```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backstage-ingress
  namespace: backstage
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: backstage.msdp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backstage-frontend-svc
            port:
              number: 3000
  - host: backstage-api.msdp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backstage-backend-svc
            port:
              number: 7007
```

---

## 🚀 **Step-by-Step Kubernetes Deployment**

### **Prerequisites:**
```bash
# You need a Kubernetes cluster
# Options:
# 1. Local: minikube, k3s, Docker Desktop Kubernetes
# 2. Cloud: EKS, GKE, AKS
# 3. Managed: DigitalOcean, Linode Kubernetes
```

### **Step 1: Prepare Local Kubernetes**

```bash
# Option A: Docker Desktop Kubernetes (Easiest)
# Enable Kubernetes in Docker Desktop settings

# Option B: Minikube
brew install minikube
minikube start --memory=4096 --cpus=2

# Option C: k3s (Lightweight)
curl -sfL https://get.k3s.io | sh -
```

### **Step 2: Build Backstage Container**

```bash
# On your laptop
cd /Users/santanu/github/msdp-platform-core/backstage-platform

# Create production Dockerfile
cat > Dockerfile << 'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
RUN yarn build:backend

FROM node:20-alpine AS runtime
RUN addgroup --gid 1001 --system backstage && \
    adduser --uid 1001 --system --ingroup backstage backstage
WORKDIR /app
COPY --from=builder --chown=backstage:backstage /app/packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz
USER backstage
EXPOSE 7007
CMD ["node", "packages/backend"]
EOF

# Build container
docker build -t msdp/backstage:latest .
```

### **Step 3: Deploy to Kubernetes**

```bash
# Create namespace
kubectl create namespace backstage

# Apply configurations
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/backstage-backend.yaml
kubectl apply -f k8s/ingress.yaml
```

### **Step 4: Configure Service Discovery**

```yaml
# No more hardcoded IPs!
proxy:
  '/api/location':
    target: http://location-service.msdp-services:3001
    changeOrigin: true
  '/api/merchant':
    target: http://merchant-service.msdp-services:3002
    changeOrigin: true
  # Kubernetes DNS resolution automatically
```

---

## 🎯 **Benefits of Kubernetes Deployment**

### **✅ Solves All Your Concerns:**

```
🔧 MODULARITY:
├── ✅ Environment variables via ConfigMaps
├── ✅ Secrets management via Kubernetes Secrets
├── ✅ Service discovery via DNS
├── ✅ No hardcoded IPs or ports
└── ✅ Environment-specific configurations

🚀 SCALABILITY:
├── ✅ Auto-scaling based on load
├── ✅ Multiple replicas for high availability
├── ✅ Rolling updates with zero downtime
├── ✅ Resource limits and requests
└── ✅ Multi-environment deployments

🔒 SECURITY:
├── ✅ Network policies for service isolation
├── ✅ RBAC for access control
├── ✅ Secrets encryption at rest
├── ✅ Pod security policies
└── ✅ TLS termination at ingress
```

### **🌐 Access After Kubernetes Deployment:**

```
✅ LOCAL ACCESS:
├── Backstage UI: http://backstage.msdp.local
├── Backstage API: http://backstage-api.msdp.local
├── No port conflicts or IP issues
└── Professional domain-based access

✅ SERVICE DISCOVERY:
├── location-service.msdp-services:3001
├── merchant-service.msdp-services:3002
├── user-service.msdp-services:3003
└── Automatic DNS resolution
```

---

## 🎯 **Implementation Options**

### **Option 1: Local Kubernetes (Recommended Start)**
- **Docker Desktop Kubernetes** - Easiest setup
- **Test everything locally** first
- **No cloud costs** for development
- **Easy to iterate** and debug

### **Option 2: Cloud Kubernetes (Production)**
- **AWS EKS, Google GKE, Azure AKS** - Production-ready
- **Managed infrastructure** - Less maintenance
- **Global accessibility** - Access from anywhere
- **Enterprise features** - Monitoring, logging, etc.

### **Option 3: Hybrid Approach**
- **Local development** - Docker Desktop K8s
- **Production cloud** - Managed Kubernetes
- **Same manifests** - Portable across environments

---

## 💡 **Recommendation**

### **🎯 Suggested Approach:**

1. **Fix current Backstage** with simple config first
2. **Set up local Kubernetes** (Docker Desktop)
3. **Containerize Backstage** with modular config
4. **Deploy to local K8s** and test
5. **Plan cloud deployment** when ready

**This gives you:**
- ✅ **Immediate fix** for current issues
- ✅ **Modular configuration** (no hardcoding)
- ✅ **Production-ready architecture**
- ✅ **Scalable foundation** for MSDP growth

**Would you like to:**
- **A) Fix current Backstage first, then plan Kubernetes**
- **B) Jump straight to Kubernetes deployment**
- **C) Set up local Kubernetes cluster first**

**What's your preference?** 🚀

**Kubernetes is definitely the right direction for enterprise-grade MSDP platform!**
