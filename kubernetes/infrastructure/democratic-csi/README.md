# Democratic CSI - ArgoCD Manual Management

## Overview

Democratic CSI ArgoCD Application for NFS storage from TrueNAS.
Managed manually (not automated) with sensitive values embedded.

## Files

- `democratic-csi-app-secret.yaml` - ArgoCD Application (NOT in git)
- Other files are legacy/not used

## Usage

```bash
# Deploy
kubectl apply -f democratic-csi-app-secret.yaml

# Sync via ArgoCD
argocd app sync democratic-csi-nfs

# Verify
kubectl get pods -n democratic-csi
kubectl get storageclass truenas-nfs
```

## Update Process

1. Edit `democratic-csi-app-secret.yaml`
2. `kubectl apply -f democratic-csi-app-secret.yaml`
3. Sync in ArgoCD

## Application Template

See `democratic-csi-app-secret.yaml` for actual file.
Key sections to customize:
- `targetRevision` - Chart version
- `apiKey` - TrueNAS API key  
- `host` / `shareHost` - TrueNAS hostname
- `datasetParentName` - ZFS parent dataset
- `detachedSnapshotsDatasetParentName` - Snapshots dataset
- `datasetPermissionsUser/Group` - UID/GID
