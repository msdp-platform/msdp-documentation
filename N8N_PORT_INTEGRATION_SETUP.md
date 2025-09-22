# 🔗 N8N ↔ Port.io Integration Manual Setup Guide

**Version**: 1.0.0  
**Created**: September 22, 2025  
**Purpose**: One-time manual setup for N8N and Port.io integration for MSDP AI-driven service generation

> **💡 Note**: This is a **one-time setup**. Once configured, it will automate all future service generations in 7 minutes!

---

## 🎯 **Setup Overview**

### **What We're Building**
```yaml
Integration Flow:
  Port.io (Service Catalog) → N8N (Workflow Automation) → AI Agents → GitHub → Kubernetes → Port.io (Updated)

One-Time Setup → Infinite Automated Service Generation
```

### **Expected Outcome**
- **Port.io**: Service catalog with MSDP blueprints and actions
- **N8N**: Automated workflows for service generation
- **Integration**: Seamless communication between platforms
- **Result**: 7-minute service generation from business requirements

---

## 🏢 **STEP 1: Port.io SaaS Setup**

### **1.1 Create Port.io Account**
```yaml
Action Required:
  1. Go to: https://app.getport.io/
  2. Sign up with your email
  3. Choose organization name: "MSDP Platform"
  4. Select plan: Start with Free tier (upgrade later if needed)
```

### **1.2 Create MSDP Workspace**
```yaml
Workspace Configuration:
  - Name: "MSDP AI Platform"
  - Description: "AI-driven service generation platform"
  - Domain: Choose your preferred subdomain
```

### **1.3 Configure MSDP Blueprints**
Create these blueprints in Port.io:

#### **Blueprint 1: Service**
```json
{
  "identifier": "service",
  "title": "MSDP Service",
  "icon": "Microservice",
  "schema": {
    "properties": {
      "name": {
        "type": "string",
        "title": "Service Name"
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
        }
      },
      "description": {
        "type": "string",
        "title": "Business Requirements"
      },
      "team": {
        "type": "string",
        "title": "Owning Team"
      },
      "environment": {
        "type": "string",
        "title": "Target Environment",
        "enum": ["dev", "staging", "prod"]
      },
      "status": {
        "type": "string",
        "title": "Status",
        "enum": ["requested", "generating", "deploying", "deployed", "failed"],
        "enumColors": {
          "requested": "yellow",
          "generating": "blue",
          "deploying": "purple",
          "deployed": "green",
          "failed": "red"
        }
      },
      "repository_url": {
        "type": "string",
        "title": "Repository URL",
        "format": "url"
      },
      "deployment_url": {
        "type": "string",
        "title": "Deployment URL",
        "format": "url"
      }
    },
    "required": ["name", "type", "description", "team"]
  }
}
```

#### **Blueprint 2: Environment**
```json
{
  "identifier": "environment",
  "title": "Environment",
  "icon": "Environment",
  "schema": {
    "properties": {
      "name": {
        "type": "string",
        "title": "Environment Name"
      },
      "cluster": {
        "type": "string",
        "title": "Kubernetes Cluster"
      },
      "namespace": {
        "type": "string",
        "title": "Namespace"
      }
    }
  }
}
```

#### **Blueprint 3: Team**
```json
{
  "identifier": "team",
  "title": "Team",
  "icon": "Team",
  "schema": {
    "properties": {
      "name": {
        "type": "string",
        "title": "Team Name"
      },
      "slack_channel": {
        "type": "string",
        "title": "Slack Channel"
      },
      "github_team": {
        "type": "string",
        "title": "GitHub Team"
      }
    }
  }
}
```

### **1.4 Create Port.io Actions**
Create these actions to trigger N8N workflows:

#### **Action 1: Generate Service**
```json
{
  "identifier": "generate_service",
  "title": "🤖 Generate Service with AI",
  "icon": "Microservice",
  "userInputs": {
    "properties": {
      "service_name": {
        "type": "string",
        "title": "Service Name"
      },
      "service_type": {
        "type": "string",
        "title": "Service Type",
        "enum": ["microservice", "frontend", "mobile", "shared-library"]
      },
      "business_requirements": {
        "type": "string",
        "title": "Business Requirements",
        "description": "Describe what this service should do"
      },
      "team": {
        "type": "string",
        "title": "Owning Team"
      },
      "environment": {
        "type": "string",
        "title": "Target Environment",
        "enum": ["dev", "staging", "prod"],
        "default": "dev"
      }
    },
    "required": ["service_name", "service_type", "business_requirements", "team"]
  },
  "invocationMethod": {
    "type": "WEBHOOK",
    "url": "https://YOUR_N8N_WEBHOOK_URL/generate-service"
  }
}
```

### **1.5 Get Port.io API Credentials**
```yaml
Required Information:
  1. Go to Port.io Settings → API Tokens
  2. Create new token: "MSDP N8N Integration"
  3. Copy: CLIENT_ID and CLIENT_SECRET
  4. Note: API Base URL (usually https://api.getport.io/v1)
```

---

## 🔄 **STEP 2: N8N Cloud Setup**

### **2.1 Create N8N Cloud Account**
```yaml
Action Required:
  1. Go to: https://n8n.cloud/
  2. Sign up with your email
  3. Choose plan: Start with Starter plan
  4. Create workspace: "MSDP Platform"
```

### **2.2 Setup N8N Credentials**
Add these credentials in N8N:

#### **Port.io API Credentials**
```yaml
Credential Type: HTTP Header Auth
Name: "Port.io API"
Header Name: "Authorization"
Header Value: "Bearer YOUR_PORT_IO_TOKEN"
```

#### **GitHub API Credentials**
```yaml
Credential Type: GitHub API
Name: "MSDP GitHub"
Access Token: YOUR_GITHUB_TOKEN (with repo permissions)
```

#### **OpenAI API Credentials** (for AI agents)
```yaml
Credential Type: OpenAI API
Name: "MSDP AI Agent"
API Key: YOUR_OPENAI_API_KEY
```

### **2.3 Create Core N8N Workflows**

#### **Workflow 1: AI Service Generator**
```yaml
Workflow Name: "MSDP AI Service Generator"
Trigger: Webhook (from Port.io action)
Description: "Generates complete service from business requirements"

Nodes:
  1. Webhook Trigger
  2. Port.io - Update Status (generating)
  3. OpenAI - Analyze Requirements
  4. GitHub - Create Repository
  5. OpenAI - Generate Code
  6. GitHub - Commit Code
  7. GitHub - Trigger CI/CD
  8. Port.io - Create Service Entity
  9. Port.io - Update Status (deployed)
```

#### **Workflow 2: Service Health Monitor**
```yaml
Workflow Name: "MSDP Service Health Monitor"
Trigger: Schedule (every 5 minutes)
Description: "Monitors service health and updates Port.io"

Nodes:
  1. Schedule Trigger
  2. Port.io - Get All Services
  3. HTTP Request - Health Check
  4. Port.io - Update Health Status
```

---

## 🔧 **STEP 3: Integration Configuration**

### **3.1 N8N Webhook URLs**
After creating N8N workflows, get webhook URLs:
```yaml
Required URLs:
  - Service Generator: https://YOUR_N8N_INSTANCE.app.n8n.cloud/webhook/generate-service
  - Health Monitor: https://YOUR_N8N_INSTANCE.app.n8n.cloud/webhook/health-update
```

### **3.2 Update Port.io Actions**
Update Port.io actions with actual N8N webhook URLs:
```yaml
Action: "Generate Service"
Webhook URL: https://YOUR_N8N_INSTANCE.app.n8n.cloud/webhook/generate-service
```

### **3.3 Configure Environment Variables**
In N8N, set these environment variables:
```yaml
PORT_IO_API_URL: https://api.getport.io/v1
PORT_IO_CLIENT_ID: your_port_client_id
PORT_IO_CLIENT_SECRET: your_port_client_secret
GITHUB_ORG: msdp-platform
OPENAI_API_KEY: your_openai_key
```

---

## 🧪 **STEP 4: Testing the Integration**

### **4.1 Test Port.io → N8N Flow**
```yaml
Test Steps:
  1. Go to Port.io catalog
  2. Click "Generate Service" action
  3. Fill in test service details:
     - Name: "test-service"
     - Type: "microservice"
     - Requirements: "Simple REST API for user management"
     - Team: "platform-team"
  4. Submit and watch N8N workflow execute
  5. Verify service appears in Port.io catalog
```

### **4.2 Verify Generated Service**
```yaml
Check Points:
  ✅ GitHub repository created
  ✅ Code generated and committed
  ✅ CI/CD pipeline triggered
  ✅ Service entity in Port.io
  ✅ Status updated to "deployed"
```

---

## 📋 **STEP 5: Production Configuration**

### **5.1 Security Hardening**
```yaml
Security Checklist:
  ✅ Use strong API tokens
  ✅ Enable webhook signature validation
  ✅ Set up proper RBAC in Port.io
  ✅ Configure N8N access controls
  ✅ Enable audit logging
```

### **5.2 Monitoring Setup**
```yaml
Monitoring Points:
  - N8N workflow execution success rate
  - Port.io API response times
  - Service generation completion time
  - Error rates and failure notifications
```

### **5.3 Backup and Recovery**
```yaml
Backup Strategy:
  - Export N8N workflows regularly
  - Backup Port.io blueprints and actions
  - Document all configuration settings
  - Test recovery procedures
```

---

## 🎯 **Expected Results After Setup**

### **✅ Automated Service Generation**
```yaml
User Experience:
  1. User opens Port.io catalog
  2. Clicks "Generate Service" 
  3. Describes business requirements in plain English
  4. Submits request
  5. Watches real-time progress
  6. Service deployed in ~7 minutes
  7. Service appears in catalog with all metadata
```

### **📊 Success Metrics**
```yaml
Target KPIs:
  - Service Generation Time: ≤ 7 minutes
  - Success Rate: ≥ 95%
  - User Satisfaction: ≥ 90%
  - Code Quality: Passes all automated checks
```

---

## 🚀 **Next Steps After Integration**

### **Phase 1: Basic Service Generation**
- [x] Port.io and N8N setup
- [ ] Test with simple microservice
- [ ] Validate end-to-end flow
- [ ] Document any issues

### **Phase 2: Advanced Features**
- [ ] Add more service templates
- [ ] Implement dependency detection
- [ ] Add automated testing
- [ ] Setup monitoring dashboards

### **Phase 3: Scale and Optimize**
- [ ] Performance optimization
- [ ] Multi-environment support
- [ ] Advanced AI capabilities
- [ ] Team onboarding

---

## 💡 **Tips for Success**

### **🎯 Start Simple**
- Begin with one service type (microservice)
- Use basic templates initially
- Add complexity gradually

### **🔍 Monitor Everything**
- Watch N8N execution logs
- Monitor Port.io API calls
- Track service generation metrics
- Set up alerts for failures

### **📚 Document Everything**
- Keep configuration notes
- Document troubleshooting steps
- Maintain workflow diagrams
- Update team procedures

---

## 🎉 **Completion Checklist**

- [ ] Port.io account created and configured
- [ ] MSDP blueprints created in Port.io
- [ ] Port.io actions configured with webhooks
- [ ] N8N Cloud account created
- [ ] N8N credentials configured
- [ ] Core N8N workflows created
- [ ] Integration tested end-to-end
- [ ] First service generated successfully
- [ ] Monitoring and alerts configured
- [ ] Documentation completed

**🎯 Goal**: One-time setup enabling infinite automated service generation in 7 minutes!
