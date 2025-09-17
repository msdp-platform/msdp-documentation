# VendaBuddy Technical Architecture

## 🏗️ **System Architecture Overview**

VendaBuddy is built on the MSDP (Microservice Delivery Platform) infrastructure, providing a robust, scalable foundation for merchant operations.

```
┌─────────────────────────────────────────────────────────────┐
│                    VendaBuddy Frontend                      │
│                  (Merchant Portal)                         │
└─────────────────────────┬───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│                   MSDP API Gateway                         │
│                   (Port 3000)                              │
└─────────────┬───────────┬───────────┬───────────┬───────────┘
              │           │           │           │
    ┌─────────▼──┐ ┌─────▼──┐ ┌─────▼──┐ ┌─────▼──┐
    │ Merchant   │ │ User   │ │ Order  │ │Payment │
    │ Service    │ │Service │ │Service │ │Service │
    │ (3002)     │ │(3003)  │ │(3006)  │ │(3007)  │
    └─────────┬──┘ └─────┬──┘ └─────┬──┘ └─────┬──┘
              │          │          │          │
    ┌─────────▼──┐ ┌─────▼──┐ ┌─────▼──┐ ┌─────▼──┐
    │PostgreSQL  │ │PostgreSQL│PostgreSQL│PostgreSQL│
    │ (5434)     │ │ (5435)   │ (5436)   │ (5439)   │
    └────────────┘ └──────────┘ └──────────┘ └──────────┘
```

## 🔧 **Backend Services Integration**

### **1. Merchant Service (Port 3002)**
**Purpose**: Core business logic for VendaBuddy merchants

**VendaBuddy Integration:**
- Business profile management
- Menu/product catalog
- Business type configuration
- Multi-country settings
- Vendor onboarding workflow

**API Endpoints:**
```javascript
// Business Management
GET    /api/merchants/profile
PUT    /api/merchants/profile
POST   /api/merchants/setup

// Product/Menu Management  
GET    /api/menu
POST   /api/menu
PUT    /api/menu/:id
DELETE /api/menu/:id

// Business Analytics
GET    /api/merchants/analytics
GET    /api/merchants/reports
```

### **2. Order Service (Port 3006)**
**Purpose**: Order processing and tracking

**VendaBuddy Integration:**
- Real-time order notifications
- Order status workflow
- Customer order history
- Delivery coordination
- Order analytics

**API Endpoints:**
```javascript
// Order Management
GET    /api/orders/merchant/:merchantId
PUT    /api/orders/:id/status
GET    /api/orders/:id
POST   /api/orders/bulk-update

// Order Analytics
GET    /api/orders/analytics/summary
GET    /api/orders/analytics/trends
```

### **3. Payment Service (Port 3007)**
**Purpose**: Payment processing and financial tracking

**VendaBuddy Integration:**
- Payment method configuration
- Transaction processing
- Payout management
- Financial reporting
- Tax calculations (VAT/GST)

**API Endpoints:**
```javascript
// Payment Processing
POST   /api/payments/process
GET    /api/payments/methods
PUT    /api/payments/methods/:id

// Financial Tracking
GET    /api/payments/transactions
GET    /api/payments/payouts
GET    /api/payments/reports
```

### **4. User Service (Port 3003)**
**Purpose**: Authentication and user management

**VendaBuddy Integration:**
- Merchant authentication
- Role-based permissions
- Multi-tenant support
- Session management
- Password reset

### **5. Location Service (Port 3001)**
**Purpose**: Multi-country and location support

**VendaBuddy Integration:**
- Country-specific configurations
- Currency conversion
- Local payment methods
- Regional compliance
- Delivery zones

## 💾 **Database Design**

### **Merchant Service Database:**
```sql
-- Business Profiles
CREATE TABLE merchant_profiles (
    id UUID PRIMARY KEY,
    business_name VARCHAR(255) NOT NULL,
    business_type ENUM('restaurant', 'street_food', 'retail', 'services'),
    country_code VARCHAR(3) NOT NULL,
    currency_code VARCHAR(3) NOT NULL,
    onboarded_by UUID REFERENCES admin_users(id),
    status ENUM('pending', 'active', 'suspended'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Business Configuration
CREATE TABLE business_configs (
    merchant_id UUID REFERENCES merchant_profiles(id),
    config_key VARCHAR(100),
    config_value JSONB,
    country_specific BOOLEAN DEFAULT false
);
```

### **Multi-Country Support:**
```sql
-- Country-specific settings
CREATE TABLE country_configs (
    country_code VARCHAR(3) PRIMARY KEY,
    currency_code VARCHAR(3),
    tax_rate DECIMAL(5,2),
    payment_methods JSONB,
    regulations JSONB
);
```

## 🔐 **Security Architecture**

### **Authentication Flow:**
1. **Admin Onboarding**: Admin creates merchant account
2. **Invitation Email**: Merchant receives setup link
3. **Profile Setup**: Merchant completes business profile
4. **JWT Authentication**: Secure session management
5. **Role-Based Access**: Permissions by business type

### **Data Protection:**
- **Encryption**: All data encrypted at rest and in transit
- **PCI Compliance**: Payment data security
- **GDPR Compliance**: EU data protection
- **Access Controls**: Role-based permissions
- **Audit Logging**: All actions tracked

## 🌐 **Multi-Country Implementation**

### **UK Configuration:**
```json
{
  "country_code": "GB",
  "currency": "GBP",
  "tax_type": "VAT",
  "tax_rate": 20.0,
  "payment_methods": ["card", "contactless", "bank_transfer"],
  "regulations": {
    "data_protection": "UK_GDPR",
    "financial": "FCA_regulated"
  }
}
```

### **India Configuration:**
```json
{
  "country_code": "IN", 
  "currency": "INR",
  "tax_type": "GST",
  "tax_rate": 18.0,
  "payment_methods": ["upi", "card", "cash", "wallet"],
  "regulations": {
    "data_protection": "IT_Act_2000",
    "financial": "RBI_guidelines"
  }
}
```

## 📱 **Frontend Architecture**

### **Technology Stack:**
- **Framework**: Next.js 15 (React)
- **Styling**: Tailwind CSS
- **Icons**: Heroicons
- **State Management**: React Context/Zustand
- **API Client**: Axios
- **Charts**: Recharts/Chart.js

### **Component Structure:**
```
src/
├── app/
│   ├── auth/
│   │   ├── login/
│   │   └── setup/
│   ├── dashboard/
│   ├── products/
│   ├── orders/
│   ├── analytics/
│   └── settings/
├── components/
│   ├── ui/           # Reusable UI components
│   ├── charts/       # Analytics components
│   ├── forms/        # Form components
│   └── layout/       # Layout components
├── lib/
│   ├── api/          # API client
│   ├── auth/         # Authentication
│   ├── utils/        # Utilities
│   └── hooks/        # Custom hooks
└── styles/
    └── globals.css
```

## 🔄 **Data Flow Architecture**

### **Order Processing Flow:**
```
Customer Order → API Gateway → Order Service → Merchant Dashboard
                                    ↓
Payment Service ← Order Service ← Merchant Action
                                    ↓
Customer Notification ← Order Service → Delivery Coordination
```

### **Business Analytics Flow:**
```
Transaction Data → Order Service → Analytics Engine → Dashboard
                                        ↓
Payment Data → Payment Service → Financial Reports → Merchant
                                        ↓
Customer Data → User Service → Customer Insights → Marketing
```

## 🚀 **Deployment Strategy**

### **Docker Containerization:**
```yaml
# VendaBuddy Frontend
vendabuddy-frontend:
  ports: ["4003:4003"]
  environment:
    - NEXT_PUBLIC_API_URL=http://localhost:3000
    - NEXT_PUBLIC_BRAND_NAME=VendaBuddy
```

### **Environment Configuration:**
- **Development**: Local Docker containers
- **Staging**: Cloud deployment with test data
- **Production**: Multi-region deployment (UK/India)

## 📈 **Scalability Plan**

### **Horizontal Scaling:**
- **Load Balancers**: Distribute traffic
- **Database Sharding**: Split by country/region
- **CDN**: Static asset delivery
- **Caching**: Redis for session/data caching

### **Performance Optimization:**
- **Code Splitting**: Lazy load components
- **Image Optimization**: Next.js image optimization
- **API Caching**: Response caching strategies
- **Database Indexing**: Optimized queries

## 🔍 **Monitoring & Analytics**

### **Business Metrics:**
- Merchant acquisition rate
- Order volume per merchant
- Revenue growth
- Feature adoption
- User engagement

### **Technical Metrics:**
- Response times
- Error rates
- Uptime
- Database performance
- Memory/CPU usage

## 🎯 **Success Criteria**

### **Business Goals:**
- **100 merchants** in first 6 months
- **1000 orders/day** processed
- **95% merchant satisfaction**
- **99.9% uptime**

### **Technical Goals:**
- **< 2 second** page load times
- **< 500ms** API responses
- **Zero data loss**
- **PCI compliance**

---

**This architecture provides the foundation for VendaBuddy to become the "Shopify for local businesses" - empowering street food vendors and POS systems with enterprise-grade tools in a friendly, accessible package.**
