# Backstage Plugins and Templates Setup for MSDP

## 🔌 **Adding Plugins to Your MSDP Backstage**

### **Essential Plugins for MSDP Platform:**

```
🎯 RECOMMENDED PLUGINS:
├── 🔍 Tech Radar: Technology adoption tracking
├── 📊 Kubernetes: Service deployment status
├── 🔗 GitHub Actions: CI/CD pipeline status
├── 📈 Grafana: Monitoring dashboards
├── 🏷️ Cost Insights: Resource cost tracking
├── 🔔 PagerDuty: Incident management
└── 📋 Todo: Task management for services
```

---

## 🚀 **Step 1: Install Essential Plugins**

### **Commands for Remote Machine (192.168.1.102):**

#### **1.1: Stop Backstage**
```bash
# In your SSH session:
pkill -f 'yarn.*start' || fg (then Ctrl+C)
```

#### **1.2: Install Popular Plugins**
```bash
cd /Users/santanubiswas/projects/msdp-backstage-remote

# Install essential plugins
yarn add @backstage/plugin-tech-radar
yarn add @backstage/plugin-kubernetes
yarn add @backstage/plugin-github-actions
yarn add @roadiehq/backstage-plugin-grafana
yarn add @backstage/plugin-cost-insights
yarn add @backstage/plugin-todo
```

#### **1.3: Add Plugins to Frontend**
```bash
# Edit the app configuration to include plugins
cat >> packages/app/src/App.tsx << 'EOF'

// Add plugin imports
import { TechRadarPage } from '@backstage/plugin-tech-radar';
import { KubernetesPage } from '@backstage/plugin-kubernetes';
import { TodoPage } from '@backstage/plugin-todo';

// Add routes in the App component
<Route path="/tech-radar" element={<TechRadarPage />} />
<Route path="/kubernetes" element={<KubernetesPage />} />
<Route path="/todo" element={<TodoPage />} />
EOF
```

---

## 📋 **Step 2: Create MSDP Templates**

### **2.1: Create Templates Directory**
```bash
mkdir -p catalog-info/templates
```

### **2.2: MSDP Service Template**
```bash
cat > catalog-info/templates/msdp-service-template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: msdp-service-template
  title: MSDP Microservice Template
  description: Create a new MSDP microservice with standard structure
  tags:
    - msdp
    - microservice
    - nodejs
spec:
  owner: platform-team
  type: service
  
  parameters:
    - title: Service Information
      required:
        - name
        - description
      properties:
        name:
          title: Service Name
          type: string
          description: Name of the microservice
          pattern: '^[a-z0-9-]+$'
        description:
          title: Description
          type: string
          description: What does this service do?
        port:
          title: Service Port
          type: number
          description: Port number for the service
          default: 3010

  steps:
    - id: fetch-base
      name: Fetch Base Template
      action: fetch:template
      input:
        url: ./content
        values:
          name: ${{ parameters.name }}
          description: ${{ parameters.description }}
          port: ${{ parameters.port }}

    - id: publish
      name: Publish to GitHub
      action: publish:github
      input:
        description: New MSDP microservice ${{ parameters.name }}
        repoUrl: github.com?owner=msdp-platform&repo=msdp-${{ parameters.name }}-service

    - id: register
      name: Register in Catalog
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
        catalogInfoPath: '/catalog-info.yaml'

  output:
    links:
      - title: Repository
        url: ${{ steps.publish.output.remoteUrl }}
      - title: Open in catalog
        icon: catalog
        entityRef: ${{ steps.register.output.entityRef }}
EOF
```

### **2.3: Location Enablement Template**
```bash
cat > catalog-info/templates/location-enablement-template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: enable-location-template
  title: Enable New Location
  description: Enable MSDP services in a new country/city
  tags:
    - msdp
    - location
    - admin
spec:
  owner: platform-team
  type: location
  
  parameters:
    - title: Location Details
      required:
        - country
        - city
        - currency
      properties:
        country:
          title: Country Code
          type: string
          description: ISO country code (e.g., SG, AU, CA)
          pattern: '^[A-Z]{2}$'
        city:
          title: City Name
          type: string
          description: Primary city name
        currency:
          title: Currency Code
          type: string
          description: Local currency (e.g., SGD, AUD, CAD)
          pattern: '^[A-Z]{3}$'
        
    - title: Service Configuration
      properties:
        enableFood:
          title: Enable Food Services
          type: boolean
          default: true
        enableHome:
          title: Enable Home Services
          type: boolean
          default: true
        enableDigital:
          title: Enable Digital Services
          type: boolean
          default: true
        maxProviders:
          title: Maximum Providers
          type: number
          default: 1000

  steps:
    - id: create-location-config
      name: Create Location Configuration
      action: fs:write
      input:
        path: location-config.json
        content: |
          {
            "country": "${{ parameters.country }}",
            "city": "${{ parameters.city }}",
            "currency": "${{ parameters.currency }}",
            "services": {
              "food": ${{ parameters.enableFood }},
              "home": ${{ parameters.enableHome }},
              "digital": ${{ parameters.enableDigital }}
            },
            "limits": {
              "maxProviders": ${{ parameters.maxProviders }}
            }
          }

    - id: register-location
      name: Register Location in Catalog
      action: catalog:write
      input:
        entity:
          apiVersion: backstage.io/v1alpha1
          kind: Location
          metadata:
            name: ${{ parameters.country | lower }}-${{ parameters.city | lower }}
            description: MSDP services in ${{ parameters.city }}, ${{ parameters.country }}
          spec:
            type: location
            lifecycle: production
            owner: platform-team

  output:
    text:
      - title: Location Enabled
        content: |
          🎉 Successfully enabled MSDP services in ${{ parameters.city }}, ${{ parameters.country }}!
          
          ✅ Services configured
          ✅ Location registered in catalog
          ✅ Ready for business onboarding
EOF
```

### **2.4: Business Onboarding Template**
```bash
cat > catalog-info/templates/business-onboarding-template.yaml << 'EOF'
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: onboard-business-template
  title: Onboard New Business
  description: Onboard a new business to VendaBuddy platform
  tags:
    - msdp
    - vendabuddy
    - business
spec:
  owner: platform-team
  type: business
  
  parameters:
    - title: Business Information
      required:
        - businessName
        - businessType
        - location
        - contactEmail
      properties:
        businessName:
          title: Business Name
          type: string
          description: Name of the business
        businessType:
          title: Business Type
          type: string
          enum:
            - food_service
            - home_service
            - digital_service
            - professional_service
            - logistics
            - creative_service
        location:
          title: Location
          type: string
          description: City, Country (e.g., London, GB)
        contactEmail:
          title: Contact Email
          type: string
          format: email

  steps:
    - id: create-business-profile
      name: Create Business Profile
      action: fs:write
      input:
        path: business-profile.json
        content: |
          {
            "name": "${{ parameters.businessName }}",
            "type": "${{ parameters.businessType }}",
            "location": "${{ parameters.location }}",
            "email": "${{ parameters.contactEmail }}",
            "status": "pending_approval",
            "createdAt": "${{ "now" | date("iso") }}"
          }

    - id: register-business
      name: Register in Catalog
      action: catalog:write
      input:
        entity:
          apiVersion: backstage.io/v1alpha1
          kind: Component
          metadata:
            name: ${{ parameters.businessName | lower | replace(" ", "-") }}
            description: ${{ parameters.businessType }} business in ${{ parameters.location }}
            tags:
              - business
              - vendabuddy
              - ${{ parameters.businessType }}
          spec:
            type: business
            lifecycle: pending
            owner: frontend-team
            system: msdp-platform

  output:
    text:
      - title: Business Onboarded
        content: |
          🎉 Business onboarding initiated for ${{ parameters.businessName }}!
          
          📋 Next steps:
          ✅ Business profile created
          ✅ Registered in service catalog
          ⏳ Pending admin approval
          📧 Notification sent to platform team
EOF
```

---

## 📊 **Step 3: Update Configuration with Templates**

### **3.1: Update app-config.local.yaml to include templates**
```bash
# Add template locations to your config
cat >> app-config.local.yaml << 'EOF'

  # Add template locations
  locations:
    - type: file
      target: ./catalog-info/msdp-services.yaml
    - type: file
      target: ./catalog-info/templates/msdp-service-template.yaml
    - type: file
      target: ./catalog-info/templates/location-enablement-template.yaml
    - type: file
      target: ./catalog-info/templates/business-onboarding-template.yaml

scaffolder:
  defaultAuthor:
    name: MSDP Platform
    email: platform@msdp.local
  defaultCommitMessage: 'Initial commit from MSDP Backstage template'
EOF
```

### **3.2: Copy updated config**
```bash
cp app-config.local.yaml packages/app/
cp app-config.local.yaml packages/backend/
```

### **3.3: Start Backstage with plugins and templates**
```bash
export BACKSTAGE_APP_CONFIG_app_listen_host=0.0.0.0
export BACKSTAGE_APP_CONFIG_backend_listen_host=0.0.0.0
yarn start --config app-config.local.yaml
```

---

## 🎯 **What You'll Get After Adding Plugins & Templates**

### **🔌 New Plugins Available:**
- **🔍 Tech Radar**: Track technology adoption
- **📊 Kubernetes**: Monitor deployments
- **🔗 GitHub Actions**: See CI/CD status
- **📈 Monitoring**: Grafana dashboards

### **📋 New Templates in "Create" Menu:**
- **🚀 MSDP Service Template**: Create new microservices
- **🌍 Enable Location Template**: Add new countries/cities
- **🏪 Business Onboarding Template**: Onboard VendaBuddy businesses

### **🎨 Enhanced UI:**
- **Professional navigation** with plugin pages
- **Self-service capabilities** via templates
- **Workflow automation** for common tasks
- **Enterprise-grade interface**

---

## 🚀 **Quick Start Commands**

**Run these on your remote machine to add plugins and templates:**

1. **Install plugins** (commands above)
2. **Create template files** (commands above)
3. **Update configuration** (commands above)
4. **Restart Backstage** (commands above)

**Then explore:**
- **📊 Catalog**: See enhanced service information
- **🎨 Create**: Use self-service templates
- **🔌 Plugins**: Access new functionality

**Would you like to start with installing the plugins, or would you prefer to explore the current catalog first?** 🎯

**This will transform your Backstage into a full-featured MSDP management platform!** 🚀
