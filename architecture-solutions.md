# Homelab Architecture Solutions

## Option 2: Virtualized Storage with Proxmox on Both Servers

### Core Architecture

**Server 1 (Ryzen 5 7600X/B650):**
- Proxmox VE as hypervisor
- Critical VMs (finance tracking, home automation)
- Windows VM with P2000 passthrough for PCB design
- Container host VMs with Portainer

**Server 2 (i7-10700F/B460M):**
- Proxmox VE as hypervisor
- TrueNAS Scale VM with PCI passthrough of storage controller
- 4x12TB drives in RAIDZ2 (~20TB usable) for media and general storage
- 14TB drive passed through separately for backups/critical data
- Docker/LXC containers for Plex/Jellyfin with 3070 passthrough for transcoding

**Mini PCs:**
- Lenovo: Proxmox cluster member for small management VMs
- Dell: Dedicated backup controller/management services

### Networking Improvements
- Add 10Gb direct connection between servers:
  - PCIe 10Gb NICs (~$50-100 used on eBay)
  - Direct connection (no switch needed)
  - Configure as separate network in Proxmox for VM migrations and storage traffic

### TrueNAS VM Configuration
- Minimum 16GB RAM allocated
- 4-8 vCPUs
- Pass through the entire storage controller (not individual drives)
- Dedicated virtio network adapter for storage traffic

### Backup and Recovery Solution

1. **VM Backup Strategy:**
   - Use Proxmox Backup Server (PBS) on Dell mini PC
   - 14TB drive either in Server 2 (passed directly to PBS VM) or external USB to Dell mini PC
   - Schedule regular backups of all critical VMs (including TrueNAS VM)

2. **TrueNAS Data Backup:**
   - Create separate backup dataset in TrueNAS
   - Use TrueNAS replication to second storage (either 14TB drive or external NAS)
   - For critical data only (configurations, personal files, not media)

3. **Recovery Process:**
   - If TrueNAS VM is lost: Restore from Proxmox backup
   - If TrueNAS config only is lost: Import existing ZFS pool, restore config from backup
   - If entire server fails: Import ZFS pool on new hardware (ZFS pools are portable)

4. **Budget-Friendly External Backup Option:**
   - Use 4x2TB drives in mini PC with TrueNAS Core as dedicated backup target
   - Configure periodic replication from main TrueNAS

### Pros
- Highly efficient resource utilization
- Direct PCI passthrough preserves most TrueNAS performance
- Proxmox clustering enables live migration for updates
- Separation of backup storage from primary storage
- More flexible GPU allocation (can move between VMs if needed)

### Cons
- Recovery complexity if hypervisor fails
- Risk of data corruption if improper shutdown occurs
- VM overhead (though minimal with direct passthrough)

---

## Option 3: TrueNAS Scale + Kubernetes Integration

### Core Architecture

**Server 1 (Ryzen 5 7600X/B650):**
- Proxmox VE
- Windows VM with P2000 passthrough
- K3s control plane nodes (3 VMs for proper HA)
- Critical application VMs that shouldn't be containerized

**Server 2 (i7-10700F/B460M):**
- TrueNAS SCALE bare metal
- 4x12TB in RAIDZ2
- 14TB as separate pool for backups
- Built-in Kubernetes (TrueNAS SCALE includes k3s)
- RTX 3070 for Plex/Jellyfin transcoding (via built-in apps)

**Mini PCs:**
- Both configured as additional k3s worker nodes
- Join the same cluster as TrueNAS SCALE's built-in k3s

### Integration Strategy

TrueNAS SCALE has built-in Kubernetes capabilities:
1. It runs k3s natively (no need for separate worker node setup)
2. Configure it to join your k3s cluster from Server 1
3. Use built-in TrueNAS apps for Plex/Jellyfin with GPU acceleration
4. For other apps, deploy them as k8s pods that can use:
   - TrueNAS democratic CIFS/SMB for standard volumes
   - TrueNAS Scale's built-in Longhorn integration for persistent volumes

### Storage Integration for Kubernetes

1. **TrueNAS as CSI Provider:**
   - TrueNAS SCALE exposes its storage to k8s via built-in CSI driver
   - Define StorageClass in k8s pointing to TrueNAS datasets
   - Pods request storage via PVCs

2. **Stateful Applications:**
   - Deploy using StatefulSets with PVCs
   - Storage remains on TrueNAS but is accessible cluster-wide
   - Example config:
   ```yaml
   kind: StorageClass
   apiVersion: storage.k8s.io/v1
   metadata:
     name: truenas-iscsi
   provisioner: truenas.csi.driver
   parameters:
     dataset: tank/k8s
     fsType: zfs
   ```

3. **High Performance Option:**
   - For performance-critical apps, use node affinity to schedule pods on TrueNAS node
   - For resilience, allow them to run elsewhere with reduced performance

### Backup Solution

1. **ZFS Snapshots:**
   - Automated, frequent snapshots of datasets containing k8s PVs
   - Retention policy based on importance (hourly/daily/weekly)

2. **Remote Replication:**
   - Secondary storage system (could be mini PC with 4x2TB drives)
   - Scheduled ZFS send/receive for critical datasets
   - Could use cloud backup for most critical data (Backblaze B2, etc.)

3. **Kubernetes State:**
   - GitOps approach with all manifests in Git
   - Use Flux or ArgoCD for declarative deployments
   - Velero for k8s cluster state backups

### Pros
- Native integration between storage and container orchestration
- Better isolation of storage service (bare metal)
- Built-in GPU support for applications
- True HA for containerized applications
- Storage redundancy at ZFS level
- Reproducible deployments via GitOps

### Cons
- Limited flexibility for storage hardware changes
- Network bottleneck between k8s nodes and storage
- More complex initial setup
- TrueNAS SCALE's k3s implementation is still maturing

---

## Final Recommendation

Given your emphasis on reliability for financial tracking and home automation, plus your interest in Infrastructure as Code, **I recommend Option 3 with some modifications**:

### Recommended Architecture
- Use TrueNAS SCALE bare metal on Server 2 for maximum storage reliability
- Implement full GitOps workflow for all containerized applications
- Add a direct 10Gb connection between servers (~$100 investment that dramatically improves performance)
- Use one mini PC as dedicated backup target with 4x2TB drives
- Keep the 14TB drive separate from your main array for backups of critical data

### Why This Approach
This gives you:
1. **Rock-solid storage foundation** - Bare metal TrueNAS SCALE eliminates virtualization layer risks
2. **Full reproducibility through code** - GitOps ensures all configurations are version controlled
3. **Better network performance** - Direct 10Gb connection between servers improves storage access
4. **Complete backup solution** - Multiple backup targets for different data criticality levels
5. **Kubernetes for container orchestration** - Proper HA for your critical services

### Implementation Priority
1. Set up TrueNAS SCALE on Server 2 with storage array
2. Install Proxmox on Server 1 and configure Windows VM
3. Add 10Gb networking between servers
4. Deploy k3s cluster across all nodes
5. Implement GitOps workflow with Flux/ArgoCD
6. Configure backup systems on mini PC

---

## Option 3B: Virtualized TrueNAS with Vanilla K3s

### Core Architecture

**Server 2 (i7-10700F/B460M):**
- Proxmox VE as hypervisor
- TrueNAS SCALE VM with full PCI passthrough of storage controller
- 4x12TB drives in RAIDZ2 (~20TB usable) for media and general storage
- 14TB as separate pool for backups
- Vanilla k3s node VM (worker or second control plane)
- RTX 3070 shared between VMs via GPU partitioning or passed to specific VM

**Server 1 (Ryzen 5 7600X/B650):**
- Proxmox VE hypervisor
- Primary k3s control plane node (1-3 VMs for HA)
- Windows VM with P2000 passthrough
- Additional service VMs as needed

**Mini PCs:**
- Additional k3s worker nodes
- Monitoring and backup services

### Storage Integration Options

#### 1. Democratic CSI Driver (Recommended)
- Deploy the [Democratic CSI driver](https://github.com/democratic-csi/democratic-csi) in your k3s cluster
- Configure it to talk to TrueNAS API (works with both CORE and SCALE)
- Provides native k8s PV/PVC storage provisioning
- Example configuration:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: truenas-nfs
provisioner: org.democratic-csi.nfs
parameters:
  fsType: nfs
  datasetParentName: tank/k8s-nfs
  datasetEnableQuotas: "true"
  datasetEnableReservation: "true"
  datasetPermissionsMode: "0777"
  datasetPermissionsUser: 0
  datasetPermissionsGroup: 0
```

#### 2. Longhorn with TrueNAS Backend
- Deploy Longhorn in your k3s cluster
- Configure Longhorn to use TrueNAS-provided storage via NFS/iSCSI
- Gives you distributed storage while leveraging TrueNAS ZFS protection
- Setup process:
  1. Create NFS shares on TrueNAS
  2. Mount these on k3s nodes
  3. Configure Longhorn to use these mounts

### Networking Requirements

- **Critical**: Add 10Gb direct connection between servers
- Configure dedicated networks in Proxmox for:
  - Storage traffic (between TrueNAS VM and k3s nodes)
  - Cluster traffic (between k3s nodes)
  - Management traffic

### TrueNAS VM Configuration
- Minimum 16GB RAM allocated (same as Option 2, since k3s pods run on separate VMs)
- 4-8 vCPUs
- Pass through the entire storage controller (not individual drives)
- Dedicated virtio network adapters for storage and cluster traffic

### Backup and Recovery Solution

1. **VM Backup Strategy:**
   - Use Proxmox Backup Server (PBS) on Dell mini PC
   - 14TB drive for PBS storage
   - Schedule regular backups of all VMs (TrueNAS and k3s nodes)

2. **ZFS Snapshots:**
   - Automated, frequent snapshots of datasets containing k8s PVs
   - Retention policy based on importance (hourly/daily/weekly)

3. **Kubernetes State Backup:**
   - GitOps approach with all manifests in Git (Flux/ArgoCD)
   - Velero for k8s cluster state backups to TrueNAS or external storage
   - etcd snapshots for control plane recovery

4. **Remote Replication:**
   - Use mini PC with 4x2TB drives as replication target
   - Scheduled ZFS send/receive for critical datasets

### Implementation Roadmap

1. **Initial Setup:**
   - Install Proxmox on both servers
   - Configure TrueNAS VM with PCI passthrough on Server 2
   - Set up ZFS pools on TrueNAS

2. **Networking:**
   - Add 10Gb cards and direct connection
   - Configure VLANs and dedicated networks in Proxmox

3. **K3s Deployment:**
   - Deploy control plane on Server 1 VMs
   - Join worker nodes (Server 2 VM and Mini PCs)
   - Configure Democratic CSI or Longhorn for storage

4. **GitOps Implementation:**
   - Deploy Flux/ArgoCD
   - Migrate compose files to k8s manifests
   - Configure CI/CD pipelines with Ansible

5. **Backup Configuration:**
   - Configure ZFS snapshots and replication
   - Set up Velero for k8s backups
   - Test recovery procedures

### Pros
- **Full control over k3s**: Use latest vanilla k3s with your preferred configurations
- **GitOps friendly**: Consistent with your approach for everything in git
- **Resource flexibility**: Can adjust resource allocation between VMs as needed
- **Migration path**: Can move to bare metal later if desired
- **Independent scaling**: Can scale compute and storage independently
- **Ansible integration**: Fits perfectly with your existing automation approach

### Cons
- **Additional complexity**: More moving parts than bare metal TrueNAS
- **Storage latency**: Slight performance penalty due to virtualization
- **Recovery complexity**: More complex recovery procedure
- **Configuration overhead**: More components to maintain and update
- **Resource overhead**: Running both TrueNAS and k3s VMs on same host

### Comparison with Other Options

| Aspect | Option 2 (Docker) | Option 3 (Bare Metal TrueNAS) | Option 3B (Virtualized) |
|--------|-------------------|-------------------------------|------------------------|
| Storage Performance | Good | Excellent | Good |
| k3s Control | N/A | Limited (TrueNAS k3s) | Full |
| GitOps Integration | Moderate | Good | Excellent |
| Recovery Complexity | Medium | Low | High |
| Resource Efficiency | High | Medium | Medium |
| Flexibility | High | Low | High |

### Recommendation for Option 3B

This approach is ideal if you:
- Want full control over your k3s cluster
- Prefer consistency in your GitOps/Ansible approach
- Are comfortable with additional complexity for flexibility
- Plan to iterate and evolve your cluster configuration frequently

The key to success with this option is:
1. Proper resource allocation between VMs
2. 10Gb networking for storage performance
3. Comprehensive backup strategy
4. Well-defined recovery procedures

---

## Specialized Implementation Plan for Current Applications

Based on your existing services and storage constraints, here's a detailed implementation plan for Option 3B with hybrid storage:

### Storage Strategy by Application

#### TrueNAS CSI (Large Data, Critical Storage)
```yaml
# Applications requiring large storage or critical data reliability
- Jellyfin media library (~15-20TB) - NFS mount to media datasets
- Plex/Jellyfin config (small but critical) - NFS for backup integration
- BookStack database (MariaDB) - iSCSI for database performance
- Monica database (MySQL) - iSCSI for database performance 
- Prometheus metrics (long-term storage) - NFS for snapshot benefits
- Grafana data (dashboards/configs) - NFS for backup integration
```

#### Longhorn (Small Configs, High Availability)
```yaml
# Applications needing HA but small storage footprint
- Radarr/Sonarr/Prowlarr configs (each ~100MB) - 2 replicas for HA
- Portainer configs - 2 replicas for management reliability  
- Dashy configs - 2 replicas for dashboard availability
- InfluxDB data - 2 replicas, can handle node failures
- Nginx configs - 2 replicas for web serving HA
- Application secrets/configs - distributed across nodes
```

### Node Assignment Strategy

#### Server 1 (Ryzen 5 7600X) - Control Plane & Critical Apps
```yaml
VMs:
  - k3s-control-plane-1: 8GB RAM, 4 vCPU, 100GB disk
  - k3s-control-plane-2: 4GB RAM, 2 vCPU, 50GB disk  
  - k3s-control-plane-3: 4GB RAM, 2 vCPU, 50GB disk
  - windows-vm: 16GB RAM, 6 vCPU, P2000 passthrough
  - monitoring-vm: 8GB RAM, 4 vCPU (Prometheus on dedicated VM)

Node Labels:
  role: control-plane
  storage: longhorn-preferred
  zone: server1
```

#### Server 2 (i7-10700F) - Storage & Media Processing
```yaml
VMs:
  - truenas-vm: 16GB RAM, 6 vCPU, storage controller passthrough
  - k3s-worker-1: 16GB RAM, 6 vCPU, RTX 3070 access, 100GB disk
  - k3s-worker-2: 8GB RAM, 4 vCPU, 100GB disk

Node Labels:
  role: worker
  storage: truenas-preferred  
  gpu: nvidia-rtx3070
  zone: server2
```

#### Mini PCs - Distributed Workers
```yaml
Lenovo ThinkCentre (Ryzen 5 Pro, 12GB RAM):
  - k3s-worker-mini-1: All resources
  - Role: Longhorn storage, lightweight apps
  - Labels: role=worker, storage=longhorn-only, zone=mini1

Dell Optiplex (i7-4785T, 16GB RAM):
  - k3s-worker-mini-2: 12GB for k3s, 4GB for backup services
  - Role: Backup controller, monitoring
  - Labels: role=worker, storage=longhorn-only, zone=mini2, backup=primary
```

### Application Deployment Configuration

#### High Priority (Control Plane Preferred)
```yaml
# Financial tracking, Home automation, Critical configs
nodeSelector:
  zone: server1
storage: longhorn (2 replicas)
resources:
  requests: { cpu: 100m, memory: 256Mi }
  limits: { cpu: 500m, memory: 512Mi }
```

#### Media Applications (Storage Node Preferred)
```yaml
# Jellyfin, Plex, Radarr, Sonarr
nodeSelector:
  zone: server2
  gpu: nvidia-rtx3070  # For transcoding
storage: truenas-csi (media datasets)
resources:
  requests: { cpu: 500m, memory: 1Gi }
  limits: { cpu: 2000m, memory: 4Gi }
```

#### Distributed Applications (Any Node)
```yaml
# Grafana, Dashy, Nginx, InfluxDB
affinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app: distributed-app
        topologyKey: kubernetes.io/hostname
storage: longhorn (2 replicas across zones)
```

### Network Configuration
```yaml
# 10Gb between servers for storage traffic
server1-server2-storage: 10.0.100.0/30
# 1Gb for cluster management and mini PC connectivity  
cluster-management: 192.168.1.0/24
# Isolated storage network for TrueNAS access
truenas-storage: 10.0.101.0/24
```

### StorageClass Definitions

#### TrueNAS Classes
```yaml
# For large media storage
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: truenas-media-nfs
provisioner: org.democratic-csi.nfs
parameters:
  fsType: nfs
  datasetParentName: tank/k8s-media
  datasetEnableQuotas: "false"  # No quotas for media
  
# For databases requiring performance
apiVersion: storage.k8s.io/v1  
kind: StorageClass
metadata:
  name: truenas-db-iscsi
provisioner: org.democratic-csi.iscsi
parameters:
  fsType: ext4
  datasetParentName: tank/k8s-databases
  datasetEnableQuotas: "true"
  datasetQuotaBytes: "10737418240"  # 10GB default
```

#### Longhorn Classes
```yaml
# For HA configs (2 replicas due to limited nodes)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn-ha-config
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "2"
  locality: "best-effort"
  
# For backup storage on mini PCs
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn-backup
provisioner: driver.longhorn.io
parameters:
  numberOfReplicas: "1"
  dataLocality: "best-effort"
```

### Backup Implementation

#### Level 1: VM Backups (Dell Mini PC)
```yaml
# Proxmox Backup Server on Dell Mini PC
Schedule:
  - Daily: Control plane VMs
  - Weekly: Worker VMs  
  - Daily: TrueNAS VM
Storage: 120GB M.2 + 240GB SATA (360GB total)
Retention: 7 daily, 4 weekly, 3 monthly
```

#### Level 2: Application Data (4x2TB Backup Array)
```yaml
# On backup NAS or second mini PC
ZFS Replication:
  - Source: TrueNAS tank/k8s-* datasets
  - Target: backup-pool/replicated/k8s-*
  - Schedule: Every 4 hours for critical, daily for media
  
Longhorn Backups:
  - Target: NFS share on backup array
  - Schedule: Daily for all PVCs
  - Retention: 14 daily, 8 weekly
```

#### Level 3: GitOps Configuration
```yaml
# Everything in Git
- K8s manifests: Git repository
- Helm charts: Git repository  
- Ansible playbooks: Git repository
- Backup verification: Automated testing scripts
```

### Migration Timeline

#### Phase 1: Foundation (Week 1-2)
1. Install 10Gb NICs and configure networking
2. Deploy Proxmox on both servers
3. Create TrueNAS VM with storage passthrough
4. Set up ZFS pools and basic datasets

#### Phase 2: Kubernetes (Week 3-4)  
1. Deploy k3s control plane on Server 1
2. Join worker nodes (Server 2 VM + Mini PCs)
3. Install Democratic CSI and Longhorn
4. Configure storage classes and test

#### Phase 3: Application Migration (Week 5-8)
1. Start with monitoring stack (Prometheus, Grafana)
2. Migrate databases (BookStack, Monica)
3. Deploy media stack (Jellyfin, Radarr, Sonarr)
4. Migrate remaining applications

#### Phase 4: Backup & Hardening (Week 9-10)
1. Configure backup systems
2. Test disaster recovery procedures
3. Implement monitoring and alerting
4. Document procedures and runbooks

### Expected Resource Utilization
```yaml
Server 1 (65GB RAM total):
  - VMs: ~40GB RAM allocated
  - Proxmox: ~8GB RAM
  - Buffer: ~17GB RAM

Server 2 (16GB RAM total):  
  - TrueNAS VM: 16GB allocated initially
  - Worker VMs: Will need RAM upgrade to 32GB
  - Recommendation: Add 16GB RAM (~$100)

Mini PCs:
  - Lenovo: 10GB for k3s, 2GB buffer
  - Dell: 12GB for k3s + backup services
```

This plan maximizes your current hardware while providing clear upgrade paths and maintaining the GitOps workflow you prefer.