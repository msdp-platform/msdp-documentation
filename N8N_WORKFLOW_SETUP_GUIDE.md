# 🤖 N8N AI Service Generator Workflow - Setup Guide

**Purpose**: Complete N8N workflow that converts business requirements into deployed services  
**Integration**: Port.io → N8N → AI → GitHub → Port.io Service Catalog  
**Result**: 7-minute service generation from business idea to production code

---

## 🎯 **Workflow Overview**

### **What This Workflow Does:**
```yaml
Input: Business requirements in plain English
Process: 
  1. Parse Port.io webhook request
  2. Update service status to "generating"
  3. AI analyzes requirements → technical specification
  4. AI generates complete production code
  5. Creates GitHub repository
  6. Commits all generated files
  7. Creates service entry in Port.io catalog
  8. Returns success response
Output: Fully deployed service with repository and catalog entry
```

### **Workflow Nodes (11 Total):**
1. **Port.io Service Request** - Webhook trigger from Port.io
2. **Parse Service Request** - Extract and validate data
3. **Update Status: Generating** - Notify Port.io of progress
4. **AI: Analyze Requirements** - Convert business → technical spec
5. **Process AI Analysis** - Structure technical specification
6. **AI: Generate Code** - Create complete service code
7. **Create GitHub Repository** - New repo in msdp-platform org
8. **Prepare Code Commits** - Structure files for Git
9. **Split Commits** - Process files individually
10. **Commit Files to GitHub** - Push all generated code
11. **Create Port.io Service** - Add to service catalog

---

## 🔧 **Setup Instructions**

### **Step 1: Import Workflow to N8N**
```yaml
Action:
  1. Go to your N8N Cloud workspace
  2. Click "Import from JSON"
  3. Upload: N8N_AI_SERVICE_GENERATOR_WORKFLOW.json
  4. Save the workflow
```

### **Step 2: Configure Credentials**

#### **OpenAI Credentials**
```yaml
Credential Type: OpenAI API
Name: "MSDP AI Agent"
API Key: your_openai_api_key
Model: gpt-4 (recommended for code generation)
```

#### **GitHub Credentials**
```yaml
Credential Type: GitHub OAuth2
Name: "MSDP GitHub"
Scopes: repo, write:packages
Organization: msdp-platform
```

#### **Port.io API Token**
```yaml
Environment Variable: PORT_IO_TOKEN
Value: your_port_io_jwt_token
Location: N8N Environment Variables
```

### **Step 3: Configure Webhook URL**
```yaml
After importing:
  1. Click on "Port.io Service Request" node
  2. Copy the webhook URL (e.g., https://your-n8n.app.n8n.cloud/webhook/generate-service)
  3. Update Port.io action with this URL
```

---

## 🧠 **AI Prompts Used**

### **Requirements Analysis Prompt:**
```
You are an expert software architect for MSDP platform. Analyze business requirements and generate detailed technical specifications.

Business Requirements: {user_requirements}
Service Type: {service_type}

Generate a detailed technical specification including:
1. Service architecture
2. API endpoints needed  
3. Database schema
4. Dependencies
5. Deployment configuration
6. Testing strategy

Return as JSON with keys: architecture, endpoints, database, dependencies, deployment, testing
```

### **Code Generation Prompt:**
```
You are a senior developer for MSDP platform. Generate production-ready code based on technical specifications.

Service: {service_name}
Framework: {framework}
Language: {language}
Technical Spec: {technical_specification}
Requirements: {business_requirements}

Generate:
1. Main application files
2. Package.json/dependencies
3. Dockerfile
4. Kubernetes manifests
5. CI/CD pipeline
6. Tests
7. Documentation

Return as JSON with file paths as keys and content as values.
```

---

## 📊 **Generated Service Templates**

### **Microservice Template:**
```yaml
Framework: Express.js
Language: Node.js/TypeScript
Database: PostgreSQL
Port: 3000-3099 range
Files Generated:
  - src/index.ts (main application)
  - src/routes/ (API endpoints)
  - src/models/ (database models)
  - package.json (dependencies)
  - Dockerfile (containerization)
  - k8s/ (Kubernetes manifests)
  - .github/workflows/ (CI/CD)
  - tests/ (unit & integration tests)
  - README.md (documentation)
```

### **Frontend Template:**
```yaml
Framework: Next.js
Language: TypeScript
Port: 4000-4099 range
Files Generated:
  - pages/ (Next.js pages)
  - components/ (React components)
  - styles/ (CSS/styling)
  - package.json
  - Dockerfile
  - k8s/
  - .github/workflows/
  - tests/
  - README.md
```

### **Mobile Template:**
```yaml
Framework: React Native/Expo
Language: TypeScript
Platform: Cross-platform
Files Generated:
  - App.tsx (main app)
  - screens/ (app screens)
  - components/ (reusable components)
  - package.json
  - app.json (Expo config)
  - README.md
```

---

## 🔄 **Workflow Data Flow**

### **Input (Port.io Webhook):**
```json
{
  "inputs": {
    "service_name": "user-auth-service",
    "service_type": "microservice",
    "business_requirements": "User authentication with JWT tokens, password reset, email verification",
    "team": "backend-team",
    "environment": "dev"
  },
  "entity": {
    "identifier": "service-123"
  },
  "user": {
    "email": "developer@msdp.com"
  }
}
```

### **AI Analysis Output:**
```json
{
  "architecture": "RESTful API with JWT authentication",
  "endpoints": [
    "POST /auth/login",
    "POST /auth/register", 
    "POST /auth/reset-password",
    "GET /auth/verify-email"
  ],
  "database": {
    "tables": ["users", "auth_tokens", "password_resets"],
    "relationships": "users -> auth_tokens (1:many)"
  },
  "dependencies": ["express", "jsonwebtoken", "bcrypt", "nodemailer"],
  "deployment": {
    "port": 3001,
    "environment": "NODE_ENV=production"
  }
}
```

### **Generated Repository Structure:**
```
msdp-user-auth-service/
├── src/
│   ├── index.ts
│   ├── routes/auth.ts
│   ├── models/User.ts
│   ├── middleware/auth.ts
│   └── utils/email.ts
├── tests/
│   ├── auth.test.ts
│   └── integration.test.ts
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── .github/workflows/
│   └── deploy.yml
├── package.json
├── Dockerfile
└── README.md
```

---

## 🎯 **Success Metrics**

### **Performance Targets:**
```yaml
Generation Time: ≤ 7 minutes total
Success Rate: ≥ 95%
Code Quality: Passes automated tests
Repository Creation: 100% success
Port.io Integration: Real-time status updates
```

### **Generated Service Quality:**
```yaml
✅ Production-ready code
✅ Complete test suite
✅ Docker containerization
✅ Kubernetes manifests
✅ CI/CD pipeline
✅ Comprehensive documentation
✅ Security best practices
✅ MSDP platform integration
```

---

## 🔧 **Troubleshooting**

### **Common Issues:**

#### **AI Token Limits**
```yaml
Problem: OpenAI API rate limits
Solution: Add retry logic, use GPT-3.5 for analysis, GPT-4 for code
```

#### **GitHub Repository Conflicts**
```yaml
Problem: Repository name already exists
Solution: Add timestamp suffix or increment counter
```

#### **Port.io API Errors**
```yaml
Problem: Authentication or API failures
Solution: Refresh JWT token, validate payload structure
```

### **Monitoring Points:**
```yaml
- Webhook trigger success rate
- AI response time and quality
- GitHub API success rate
- Port.io catalog updates
- End-to-end generation time
```

---

## 🚀 **Deployment Checklist**

- [ ] N8N workflow imported and activated
- [ ] OpenAI credentials configured
- [ ] GitHub OAuth2 setup with repo permissions
- [ ] Port.io JWT token in environment variables
- [ ] Webhook URL updated in Port.io action
- [ ] Test workflow with simple service request
- [ ] Monitor execution logs for errors
- [ ] Validate generated repository structure
- [ ] Confirm service appears in Port.io catalog

---

## 🎉 **Expected Results**

### **User Experience:**
```yaml
1. User opens Port.io catalog
2. Clicks "Generate Service" action
3. Fills form: name, type, requirements
4. Submits request
5. Watches real-time status updates
6. Receives notification: "Service deployed in 6.5 minutes"
7. New service appears in catalog with:
   - Repository link
   - Deployment URL
   - Technical documentation
   - Team ownership
```

### **Generated Assets:**
```yaml
✅ GitHub Repository: Complete codebase
✅ Port.io Service: Catalog entry with metadata
✅ Documentation: README, API docs, deployment guide
✅ Infrastructure: Docker, Kubernetes, CI/CD
✅ Tests: Unit, integration, e2e tests
✅ Monitoring: Health checks, metrics endpoints
```

**This workflow transforms business ideas into production services in minutes!** 🚀
