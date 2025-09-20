# 🚀 MSDP CSI Storage Migration Plan

## 📋 **Current Storage Issues**
- PostgreSQL pods failing due to Azure Disk `lost+found` directory
- Volume scheduling limits (16 disks per node)
- Location service pods pending due to volume constraints
- N8N deployment PVCs taking excessive time to provision

## 🎯 **CSI Migration Strategy**

### **1. Azure Disk CSI Driver Configuration**

```yaml
# Enhanced StorageClass for MSDP
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: msdp-premium-ssd
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: disk.csi.azure.com
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
  cachingmode: ReadOnly
  fsType: ext4
  # Avoid lost+found issues
  mountOptions: "noatime,nodiratime"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Retain

---
# Standard SSD for non-critical workloads
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: msdp-standard-ssd
provisioner: disk.csi.azure.com
parameters:
  storageaccounttype: StandardSSD_LRS
  kind: Managed
  cachingmode: ReadOnly
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
```

### **2. Updated PostgreSQL PVC Template**

```yaml
# CSI-based PostgreSQL PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc-csi
  namespace: local-msdp-user
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: msdp-premium-ssd
  resources:
    requests:
      storage: 10Gi
  # CSI-specific annotations
  annotations:
    volume.beta.kubernetes.io/storage-provisioner: disk.csi.azure.com
```

### **3. PostgreSQL Deployment with CSI**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-csi
  namespace: local-msdp-user
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-csi
  template:
    metadata:
      labels:
        app: postgres-csi
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          value: "msdp_users"
        - name: POSTGRES_USER
          value: "msdp_user"
        - name: POSTGRES_PASSWORD
          value: "msdp_password"
        - name: POSTGRES_INITDB_ARGS
          value: "--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
        # CSI volumes don't need PGDATA subdirectory workaround
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - msdp_user
            - -d
            - msdp_users
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - msdp_user
            - -d
            - msdp_users
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc-csi
```

## 🔄 **Migration Steps**

### **Phase 1: Deploy CSI StorageClasses**
```bash
# 1. Create enhanced storage classes
kubectl apply -f csi-storage-classes.yaml

# 2. Verify CSI driver is available
kubectl get csidriver disk.csi.azure.com

# 3. Check storage classes
kubectl get storageclass
```

### **Phase 2: Migrate PostgreSQL Databases**
```bash
# For each service namespace
NAMESPACES=("local-msdp-user" "local-msdp-admin" "local-msdp-merchant" "local-msdp-order" "local-msdp-payment")

for ns in "${NAMESPACES[@]}"; do
  echo "Migrating PostgreSQL in namespace: $ns"
  
  # 1. Create backup of existing data
  kubectl exec -n $ns deployment/postgres -- pg_dump -U msdp_user -d msdp_db > backup-$ns.sql
  
  # 2. Create new CSI-based PVC
  kubectl apply -n $ns -f postgres-csi-pvc.yaml
  
  # 3. Deploy new PostgreSQL with CSI
  kubectl apply -n $ns -f postgres-csi-deployment.yaml
  
  # 4. Restore data
  kubectl exec -n $ns deployment/postgres-csi -- psql -U msdp_user -d msdp_db < backup-$ns.sql
  
  # 5. Update service to point to new deployment
  kubectl patch service postgres -n $ns -p '{"spec":{"selector":{"app":"postgres-csi"}}}'
  
  # 6. Remove old deployment after verification
  # kubectl delete deployment postgres -n $ns
done
```

### **Phase 3: Update N8N and Future Deployments**
```bash
# Update N8N Terraform to use CSI
# Modify infrastructure/platform-engineering/n8n/main.tf
```

## 📊 **Benefits of CSI Migration**

### **Performance Improvements**
- **Faster provisioning**: CSI volumes provision in seconds vs minutes
- **Better I/O performance**: Premium SSD with optimized caching
- **Dynamic expansion**: Grow volumes without downtime

### **Operational Benefits**
- **Higher volume limits**: 64+ volumes per node vs 16
- **Better scheduling**: WaitForFirstConsumer binding
- **Standardized interface**: Same API across cloud providers
- **Advanced features**: Snapshots, cloning, encryption

### **Reliability Improvements**
- **No lost+found issues**: CSI handles filesystem initialization properly
- **Better error handling**: More descriptive error messages
- **Automatic retries**: Built-in resilience mechanisms

## 🎯 **MSDP-Specific CSI Configuration**

### **Service-Specific Storage Classes**

```yaml
# Database workloads - Premium SSD
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: msdp-database-premium
provisioner: disk.csi.azure.com
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
  cachingmode: ReadOnly
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true

---
# Application data - Standard SSD
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: msdp-app-standard
provisioner: disk.csi.azure.com
parameters:
  storageaccounttype: StandardSSD_LRS
  kind: Managed
  cachingmode: ReadWrite
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true

---
# Logs and temporary data - Standard HDD
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: msdp-logs-standard
provisioner: disk.csi.azure.com
parameters:
  storageaccounttype: Standard_LRS
  kind: Managed
  cachingmode: None
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

### **Resource Allocation Strategy**

| Service | Storage Class | Size | Rationale |
|---------|---------------|------|-----------|
| **PostgreSQL DBs** | msdp-database-premium | 20Gi | High IOPS for database operations |
| **N8N Data** | msdp-app-standard | 10Gi | Moderate I/O for workflow data |
| **Redis** | msdp-database-premium | 5Gi | High-speed cache operations |
| **Logs** | msdp-logs-standard | 5Gi | Cost-effective log storage |

## 🚀 **Implementation Timeline**

### **Week 1: CSI Foundation**
- [ ] Deploy CSI storage classes
- [ ] Test CSI provisioning with sample workload
- [ ] Update documentation

### **Week 2: Database Migration**
- [ ] Migrate PostgreSQL databases to CSI
- [ ] Verify data integrity
- [ ] Update monitoring

### **Week 3: Application Migration**
- [ ] Update N8N deployment to use CSI
- [ ] Migrate remaining workloads
- [ ] Performance testing

### **Week 4: Optimization**
- [ ] Fine-tune storage performance
- [ ] Implement backup strategies
- [ ] Complete documentation

## 🔍 **Monitoring & Validation**

### **CSI Health Checks**
```bash
# Check CSI driver status
kubectl get csidriver

# Monitor volume provisioning
kubectl get pv,pvc --all-namespaces

# Check storage class usage
kubectl get sc -o wide

# Monitor volume metrics
kubectl top pv
```

### **Performance Validation**
```bash
# Test database performance
kubectl exec -n local-msdp-user deployment/postgres-csi -- pgbench -i -s 10 msdp_users
kubectl exec -n local-msdp-user deployment/postgres-csi -- pgbench -c 10 -j 2 -t 1000 msdp_users

# Monitor I/O performance
kubectl exec -n local-msdp-user deployment/postgres-csi -- iostat -x 1 5
```

## 🎯 **Expected Outcomes**

### **Immediate Benefits**
- ✅ **Resolve volume scheduling issues** for location service
- ✅ **Eliminate lost+found PostgreSQL problems**
- ✅ **Faster N8N deployment** (PVC provisioning)
- ✅ **Higher node volume capacity**

### **Long-term Benefits**
- ✅ **Better performance** across all database workloads
- ✅ **Simplified operations** with standardized storage
- ✅ **Cost optimization** through tiered storage
- ✅ **Future-proof architecture** for multi-cloud

## 🚨 **Risk Mitigation**

### **Data Safety**
- Complete backup before migration
- Parallel deployment approach
- Rollback procedures documented
- Data integrity verification

### **Downtime Minimization**
- Blue-green deployment strategy
- Service-by-service migration
- Health check validation
- Automated rollback triggers

This CSI migration will solve our current volume issues and provide a much more robust storage foundation for the MSDP platform! 🚀
