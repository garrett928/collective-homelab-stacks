# Kubernetes Infrastructure

This directory contains the core infrastructure components for my K8s homelab cluster. Everything except the initial cluster setup is managed through ArgoCD using GitOps principles.

## Cluster Overview

I run a K3s cluster deployed via Ansible. The cluster uses Traefik as the ingress controller and handles TLS termination for all services. All infrastructure apps are deployed through ArgoCD's app-of-apps pattern.

## Storage Classes

I use two storage backends depending on the workload requirements:

### Longhorn (Default for Small Volumes)

- **Classes**: `longhorn-retain` (default)
- **Use case**: Small databases, config volumes, anything needing HA
- **Features**: Replicated across nodes, highly available
- **Backup**: Longhorn backs up to TrueNAS for disaster recovery

### TrueNAS via Democratic CSI (Large Data)

- **Classes**: `truenas-nfs-retain`, `truenas-nfs-delete`
- **Use case**: Large datasets where HA isn't critical (e.g., Prometheus metrics)
- **Features**: NFS-backed, RAID-Z2 on TrueNAS for data protection
- **Notes**: Not HA - single point of failure if TrueNAS goes down

**Storage Strategy**: I put small metadata/config on Longhorn for redundancy. Each k8s node only has 60-100gb of storage. I simply don't have the storage space for large volumes (>10GB) so large data volumes go on TrueNAS volumes. Longhorn snapshots to TrueNAS, and TrueNAS will eventually backup offsite.

## ArgoCD Setup

I use ArgoCD for GitOps-based deployment. The root app (`kubernetes/argocd-apps/root-app.yaml`) watches the `argocd-apps/` directory and automatically deploys everything.

### Creating a New App

1. Add a new Application manifest in `kubernetes/argocd-apps/`
2. Point it to your app's directory in this repo
3. Commit and push - ArgoCD syncs automatically
4. Use sync waves (`argocd.argoproj.io/sync-wave`) if order matters

**Examples**: Check out `infrastructure-apps.yaml` for how I structure infrastructure apps, or individual app manifests like `homer-app.yaml` for application deployments.

## Monitoring Stack

I run the `kube-prometheus-stack` which includes:

- **Prometheus**: Metrics storage (90-day retention on TrueNAS NFS)
- **Grafana**: Dashboards and visualization
- **Alertmanager**: Alert routing and management

All three services are exposed via Traefik ingress with TLS. Prometheus uses TrueNAS storage for the large time-series database, while Grafana and Alertmanager use Longhorn for their smaller config databases.

**Monitoring URLs**:

- Prometheus: `https://prometheus.ghart.space`
- Grafana: `https://grafana.ghart.space`
- Alertmanager: `https://alertmanager.ghart.space`

## Backup Strategy

- **Longhorn volumes**: Replicated (2x) across nodes, backed up to TrueNAS
- **TrueNAS volumes**: RAID-Z2 for data protection
- **Offsite**: TrueNAS will eventually replicate to an offsite machine

## Infrastructure Components

| Component | Purpose | Storage |
|-----------|---------|---------|
| **ArgoCD** | GitOps deployment | - |
| **Longhorn** | Replicated block storage | Node disks |
| **Democratic CSI** | TrueNAS NFS provisioner | TrueNAS (tank/k8s-pvs) |
| **Snapshot Controller** | Volume snapshot support | - |
| **Prometheus Stack** | Monitoring & alerting | Mixed (see above) |

## Getting Started

The entire infrastructure stack is deployed via Ansible. The `05-k8s-post-install.yml` playbook:

1. Installs Longhorn with prerequisites
2. Deploys ArgoCD
3. Configures storage classes
4. Waits for everything to be ready

After that, ArgoCD takes over and manages all app deployments through Git.

## Notes

- Democratic CSI requires a manually-applied secret (`truenas-nfs-driver-config-secret.yaml`) with TrueNAS API credentials - this is gitignored for security
- Snapshot controller must be installed before Democratic CSI (handled via sync waves)
- All ingress uses the `.ghart.space` domain
