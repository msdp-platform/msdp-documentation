# Backstage Backend Explanation

## 🎯 **What is "Backstage Backend"?**

### **🔍 Backstage Architecture Components:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        BACKSTAGE APPLICATION                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  🎨 BACKSTAGE FRONTEND (React App):                                        │
│  ├── Port: 3000                                                            │
│  ├── Technology: React, TypeScript                                         │
│  ├── Purpose: User interface (web pages, forms, dashboards)                │
│  ├── Contains: Service catalog UI, search, navigation                      │
│  └── Serves: HTML, CSS, JavaScript to browsers                             │
│                                                                             │
│                                    │                                       │
│                                    ▼ API Calls                            │
│                                                                             │
│  🔧 BACKSTAGE BACKEND (Node.js API Server):                               │
│  ├── Port: 7007                                                            │
│  ├── Technology: Node.js, Express, TypeScript                              │
│  ├── Purpose: API server for Backstage functionality                       │
│  ├── Contains: Service catalog API, authentication, plugin APIs            │
│  └── Provides: REST APIs for frontend to consume                           │
│                                                                             │
│                                    │                                       │
│                                    ▼ Connects to                          │
│                                                                             │
│  🗄️ BACKSTAGE DATABASE:                                                    │
│  ├── Technology: PostgreSQL or SQLite                                      │
│  ├── Purpose: Store Backstage metadata                                     │
│  ├── Contains: Service catalog, users, templates, workflows                │
│  └── NOT your MSDP business data                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔍 **Backstage Backend vs MSDP Backend Services**

### **🎛️ BACKSTAGE BACKEND (Internal to Backstage):**

```
🔧 BACKSTAGE BACKEND RESPONSIBILITIES:
├── 📊 Service Catalog API (/api/catalog/*)
├── 🔐 Authentication API (/api/auth/*)
├── 🔍 Search API (/api/search/*)
├── 📋 Scaffolder API (/api/scaffolder/*)
├── 📚 TechDocs API (/api/techdocs/*)
├── 🔌 Plugin APIs (various endpoints)
└── 🗄️ Backstage metadata storage

🎯 PURPOSE:
├── Serve the Backstage web interface
├── Manage service catalog data
├── Handle user authentication
├── Provide plugin functionality
└── Store Backstage configuration
```

### **🚀 MSDP BACKEND SERVICES (Your Business Logic):**

```
🏗️ MSDP BACKEND SERVICES:
├── 🌍 Location Service (Port 3001)
├── 🏪 Merchant Service (Port 3002)
├── 👥 User Service (Port 3003)
├── 📦 Order Service (Port 3006)
├── 💳 Payment Service (Port 3007)
└── 🔗 API Gateway (Port 3000)

🎯 PURPOSE:
├── Handle business logic
├── Serve customer applications
├── Process orders and payments
├── Manage user accounts
└── Store business data
```

---

## 🔗 **How They Work Together**

### **Integration Architecture:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    BACKSTAGE + MSDP INTEGRATION                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  🎨 BACKSTAGE FRONTEND (Browser):                                          │
│  └── User sees service catalog, clicks on "Location Service"               │
│                                    │                                       │
│                                    ▼                                       │
│  🔧 BACKSTAGE BACKEND (Port 7007):                                         │
│  ├── Serves service catalog data                                           │
│  ├── Handles authentication                                                │
│  ├── Proxies API calls to MSDP services                                    │
│  └── Returns service information to frontend                               │
│                                    │                                       │
│                                    ▼ Proxy Requests                       │
│                                                                             │
│  🚀 MSDP SERVICES (Your Business Logic):                                  │
│  ├── 🌍 Location Service API (192.168.1.189:3001)                         │
│  ├── 🏪 Merchant Service API (192.168.1.189:3002)                         │
│  ├── 👥 User Service API (192.168.1.189:3003)                             │
│  └── ... other MSDP services                                               │
│                                    │                                       │
│                                    ▼                                       │
│  🗄️ MSDP DATABASES:                                                        │
│  ├── Location data, merchant data, user data                               │
│  ├── Business logic and customer information                               │
│  └── Your actual application data                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🎯 **Backstage Backend Functionality**

### **🔧 What Backstage Backend Does:**

#### **Service Catalog Management:**
```javascript
// Backstage backend API endpoints
GET /api/catalog/entities          // List all services
GET /api/catalog/entities/by-name  // Get specific service
POST /api/catalog/refresh          // Refresh service data
GET /api/catalog/entity-facets     // Service filtering options
```

#### **Authentication & Authorization:**
```javascript
// Backstage auth endpoints
GET /api/auth/guest/refresh        // Guest authentication
POST /api/auth/github/start        // GitHub OAuth flow
GET /api/auth/userinfo            // Current user info
```

#### **Plugin APIs:**
```javascript
// Various plugin endpoints
GET /api/scaffolder/templates      // Available templates
POST /api/scaffolder/tasks         // Create new service
GET /api/techdocs/                // Documentation
GET /api/search/query             // Search services
```

### **🗄️ Backstage Database Content:**

```
📊 BACKSTAGE DATABASE STORES:
├── 📋 Service catalog metadata (not business data)
├── 👥 User profiles and teams
├── 📝 Templates and workflows
├── 🔍 Search indexes
├── 📊 Plugin data and configurations
└── 🔑 Authentication tokens and sessions

❌ DOES NOT STORE:
├── Customer orders or payments
├── Business user accounts
├── Location or merchant data
├── Any MSDP business logic
└── Your application data
```

---

## 🔗 **Integration with Your MSDP Services**

### **Proxy Configuration:**

```yaml
# Backstage backend proxies calls to your MSDP services
proxy:
  '/api/location':
    target: 'http://192.168.1.189:3001'  # Your Location Service
    changeOrigin: true
  
  '/api/merchant':
    target: 'http://192.168.1.189:3002'  # Your Merchant Service
    changeOrigin: true

# Flow: Browser → Backstage Frontend → Backstage Backend → Your MSDP Service
```

### **Service Discovery:**

```yaml
# Backstage backend discovers your MSDP services
catalog:
  providers:
    msdp:
      production:
        baseUrl: 'http://192.168.1.189:3000'  # Your API Gateway
        services:
          - name: location-service
            url: 'http://192.168.1.189:3001'
            healthCheck: '/health'
```

---

## 🎯 **In Your Hybrid Architecture**

### **Azure AKS Deployment:**

```
🐳 BACKSTAGE IN AKS:
├── 🎨 Backstage Frontend (React app)
├── 🔧 Backstage Backend (Node.js API server)
├── 🗄️ Backstage Database (PostgreSQL for metadata)
└── 🔗 Proxy connections to your MSDP services

🚀 YOUR MSDP SERVICES:
├── Initially: Running on your laptop
├── Later: AWS Lambda functions
├── Database: AWS Aurora Serverless
└── API Gateway: AWS API Gateway
```

### **Communication Flow:**

```
User Browser → Backstage Frontend (AKS) 
             → Backstage Backend (AKS) 
             → Your MSDP Services (Laptop/AWS)
             → Your MSDP Databases (Local/Aurora)
```

---

## 💡 **Key Points**

### **✅ Understanding:**
- **Backstage Backend**: Internal API server for Backstage functionality
- **MSDP Backend**: Your business logic services (Location, Merchant, etc.)
- **Separate Concerns**: Backstage manages catalog, MSDP handles business
- **Integration**: Backstage proxies calls to MSDP services

### **🎯 In Kubernetes:**
- **Backstage Backend**: Runs in AKS as Node.js pods
- **MSDP Services**: Initially laptop, later AWS Lambda
- **Databases**: Backstage metadata in PostgreSQL, MSDP data in Aurora
- **Networking**: Backstage backend proxies to MSDP APIs

**The Backstage backend is just the API server that powers the Backstage interface - it's not your business logic!**

**Does this clarify the difference between Backstage backend and your MSDP backend services?** 🎯
