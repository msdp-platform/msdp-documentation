# 🔧 Port.io Blueprints & Actions - JSON Configurations

**Purpose**: Ready-to-use JSON configurations for MSDP AI-driven service generation platform  
**Your Port.io Org**: org_MeLFgYavZxHmHkVz  
**Client ID**: 0YjRYO6YwPX7F4Forx9e8luL5wJCdDGj

---

## 📋 **BLUEPRINT 1: Service**

### **Copy & Paste this JSON into Port.io Builder:**

```json
{
  "identifier": "service",
  "title": "MSDP Service",
  "icon": "Microservice",
  "schema": {
    "properties": {
      "name": {
        "type": "string",
        "title": "Service Name",
        "description": "Name of the service (e.g., user-service, payment-api)"
      },
      "type": {
        "type": "string",
        "title": "Service Type",
        "enum": ["microservice", "frontend", "mobile", "shared-library"],
        "enumColors": {
          "microservice": "blue",
          "frontend": "green", 
          "mobile": "purple",
          "shared-library": "orange"
        },
        "description": "Type of service to generate"
      },
      "description": {
        "type": "string",
        "title": "Business Requirements",
        "description": "Describe what this service should do in plain English"
      },
      "team": {
        "type": "string",
        "title": "Owning Team",
        "description": "Team responsible for this service"
      },
      "environment": {
        "type": "string",
        "title": "Target Environment",
        "enum": ["dev", "staging", "prod"],
        "enumColors": {
          "dev": "yellow",
          "staging": "orange",
          "prod": "red"
        },
        "default": "dev"
      },
      "status": {
        "type": "string",
        "title": "Generation Status",
        "enum": ["requested", "generating", "deploying", "deployed", "failed"],
        "enumColors": {
          "requested": "yellow",
          "generating": "blue", 
          "deploying": "purple",
          "deployed": "green",
          "failed": "red"
        },
        "default": "requested"
      },
      "repository_url": {
        "type": "string",
        "title": "Repository URL",
        "format": "url",
        "description": "GitHub repository URL (auto-generated)"
      },
      "deployment_url": {
        "type": "string", 
        "title": "Deployment URL",
        "format": "url",
        "description": "Live service URL (auto-generated)"
      },
      "generated_at": {
        "type": "string",
        "title": "Generated At",
        "format": "date-time",
        "description": "When the service was generated"
      },
      "generation_time": {
        "type": "number",
        "title": "Generation Time (minutes)",
        "description": "How long it took to generate and deploy"
      }
    },
    "required": ["name", "type", "description", "team"]
  }
}
```

---

## 🌍 **BLUEPRINT 2: Environment**

### **Copy & Paste this JSON into Port.io Builder:**

```json
{
  "identifier": "environment",
  "title": "Environment",
  "icon": "Environment",
  "schema": {
    "properties": {
      "name": {
        "type": "string",
        "title": "Environment Name",
        "description": "Environment identifier (dev, staging, prod)"
      },
      "cluster": {
        "type": "string", 
        "title": "Kubernetes Cluster",
        "description": "Target Kubernetes cluster"
      },
      "namespace": {
        "type": "string",
        "title": "Namespace",
        "description": "Kubernetes namespace for deployments"
      },
      "domain": {
        "type": "string",
        "title": "Base Domain",
        "description": "Base domain for services (e.g., dev.aztech-msdp.com)"
      },
      "region": {
        "type": "string",
        "title": "Cloud Region",
        "description": "Cloud provider region"
      }
    },
    "required": ["name", "cluster", "namespace"]
  }
}
```

---

## 👥 **BLUEPRINT 3: Team**

### **Copy & Paste this JSON into Port.io Builder:**

```json
{
  "identifier": "team",
  "title": "Team", 
  "icon": "Team",
  "schema": {
    "properties": {
      "name": {
        "type": "string",
        "title": "Team Name",
        "description": "Name of the development team"
      },
      "slack_channel": {
        "type": "string",
        "title": "Slack Channel",
        "description": "Team's Slack channel for notifications"
      },
      "github_team": {
        "type": "string",
        "title": "GitHub Team",
        "description": "GitHub team identifier"
      },
      "email": {
        "type": "string",
        "title": "Team Email",
        "format": "email",
        "description": "Team contact email"
      },
      "lead": {
        "type": "string",
        "title": "Team Lead",
        "description": "Team lead or manager"
      }
    },
    "required": ["name"]
  }
}
```

---

## 🤖 **ACTION 1: Generate Service**

### **Copy & Paste this JSON into Port.io Actions:**

```json
{
  "identifier": "generate_service",
  "title": "🤖 Generate Service with AI",
  "icon": "Microservice",
  "description": "Generate a complete service from business requirements using AI",
  "trigger": "CREATE",
  "userInputs": {
    "properties": {
      "service_name": {
        "type": "string",
        "title": "Service Name",
        "description": "Name for the new service (e.g., user-auth-service)",
        "pattern": "^[a-z][a-z0-9-]*[a-z0-9]$"
      },
      "service_type": {
        "type": "string",
        "title": "Service Type",
        "enum": ["microservice", "frontend", "mobile", "shared-library"],
        "enumColors": {
          "microservice": "blue",
          "frontend": "green",
          "mobile": "purple", 
          "shared-library": "orange"
        }
      },
      "business_requirements": {
        "type": "string",
        "title": "Business Requirements",
        "description": "Describe what this service should do in plain English. Be as detailed as possible.",
        "format": "textarea"
      },
      "team": {
        "type": "string",
        "title": "Owning Team",
        "description": "Team that will own and maintain this service"
      },
      "environment": {
        "type": "string",
        "title": "Target Environment", 
        "enum": ["dev", "staging", "prod"],
        "default": "dev",
        "description": "Environment to deploy the service to"
      },
      "priority": {
        "type": "string",
        "title": "Priority",
        "enum": ["low", "medium", "high", "urgent"],
        "enumColors": {
          "low": "green",
          "medium": "yellow",
          "high": "orange",
          "urgent": "red"
        },
        "default": "medium"
      }
    },
    "required": ["service_name", "service_type", "business_requirements", "team"]
  },
  "invocationMethod": {
    "type": "WEBHOOK",
    "url": "https://YOUR_N8N_WEBHOOK_URL/generate-service",
    "agent": false,
    "synchronized": false,
    "method": "POST"
  }
}
```

---

## 📊 **ACTION 2: Update Service Status**

### **Copy & Paste this JSON into Port.io Actions:**

```json
{
  "identifier": "update_service_status",
  "title": "🔄 Update Service Status",
  "icon": "Reload",
  "description": "Update the status of a service (used by N8N workflows)",
  "trigger": "DAY-2",
  "userInputs": {
    "properties": {
      "status": {
        "type": "string",
        "title": "New Status",
        "enum": ["requested", "generating", "deploying", "deployed", "failed"],
        "enumColors": {
          "requested": "yellow",
          "generating": "blue",
          "deploying": "purple", 
          "deployed": "green",
          "failed": "red"
        }
      },
      "message": {
        "type": "string",
        "title": "Status Message",
        "description": "Additional information about the status update"
      }
    },
    "required": ["status"]
  },
  "invocationMethod": {
    "type": "WEBHOOK",
    "url": "https://YOUR_N8N_WEBHOOK_URL/update-status",
    "agent": false,
    "synchronized": false,
    "method": "POST"
  }
}
```

---

## 🔍 **ACTION 3: Health Check Service**

### **Copy & Paste this JSON into Port.io Actions:**

```json
{
  "identifier": "health_check_service",
  "title": "🏥 Health Check Service",
  "icon": "Health",
  "description": "Check the health status of a deployed service",
  "trigger": "DAY-2",
  "userInputs": {
    "properties": {
      "check_type": {
        "type": "string",
        "title": "Check Type",
        "enum": ["basic", "detailed", "performance"],
        "enumColors": {
          "basic": "green",
          "detailed": "blue",
          "performance": "purple"
        },
        "default": "basic"
      }
    },
    "required": []
  },
  "invocationMethod": {
    "type": "WEBHOOK",
    "url": "https://YOUR_N8N_WEBHOOK_URL/health-check",
    "agent": false,
    "synchronized": false,
    "method": "POST"
  }
}
```

---

## 🏗️ **BLUEPRINT RELATIONSHIPS**

### **Add these relationships between blueprints:**

```json
{
  "service_to_team": {
    "title": "Service belongs to Team",
    "source": "service",
    "target": "team",
    "many": true,
    "required": false
  },
  "service_to_environment": {
    "title": "Service deployed in Environment", 
    "source": "service",
    "target": "environment",
    "many": false,
    "required": true
  }
}
```

---

## 📝 **INITIAL DATA TO CREATE**

### **Create these initial entities in Port.io:**

#### **Teams:**
```json
[
  {
    "identifier": "platform-team",
    "title": "Platform Team",
    "properties": {
      "name": "Platform Team",
      "slack_channel": "#platform",
      "github_team": "msdp-platform",
      "email": "platform@msdp.com",
      "lead": "Platform Lead"
    }
  },
  {
    "identifier": "backend-team", 
    "title": "Backend Team",
    "properties": {
      "name": "Backend Team",
      "slack_channel": "#backend",
      "github_team": "msdp-backend",
      "email": "backend@msdp.com",
      "lead": "Backend Lead"
    }
  }
]
```

#### **Environments:**
```json
[
  {
    "identifier": "dev",
    "title": "Development",
    "properties": {
      "name": "dev",
      "cluster": "aks-msdp-dev-01",
      "namespace": "msdp-services",
      "domain": "dev.aztech-msdp.com",
      "region": "uksouth"
    }
  },
  {
    "identifier": "staging",
    "title": "Staging", 
    "properties": {
      "name": "staging",
      "cluster": "aks-msdp-staging-01",
      "namespace": "msdp-services",
      "domain": "staging.aztech-msdp.com",
      "region": "uksouth"
    }
  }
]
```

---

## 🎯 **SETUP INSTRUCTIONS**

### **Step 1: Create Blueprints**
1. Go to Port.io Builder
2. Click "Create Blueprint"
3. Paste each blueprint JSON above
4. Save each blueprint

### **Step 2: Create Actions**
1. Go to Port.io Actions
2. Click "Create Action"
3. Paste each action JSON above
4. **Update webhook URLs** with your N8N URLs
5. Save each action

### **Step 3: Create Initial Data**
1. Go to Port.io Catalog
2. Create teams using the team JSON
3. Create environments using the environment JSON

### **Step 4: Test**
1. Try creating a service using "Generate Service" action
2. Verify the JSON structure matches your N8N webhook expectations

---

## 🔗 **N8N Integration Notes**

### **Webhook Payload Structure:**
When Port.io triggers N8N, you'll receive:
```json
{
  "action": "generate_service",
  "entity": {
    "identifier": "service-123",
    "title": "My New Service",
    "properties": {
      "service_name": "user-auth-service",
      "service_type": "microservice", 
      "business_requirements": "User authentication with JWT...",
      "team": "backend-team",
      "environment": "dev"
    }
  },
  "user": {
    "email": "user@example.com"
  }
}
```

This JSON structure is ready to use with your Port.io credentials! 🚀
