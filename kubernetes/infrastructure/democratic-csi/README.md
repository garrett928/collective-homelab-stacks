# Democratic CSI - TrueNAS SCALE NFS

## Overview

This directory contains the configuration for deploying [Democratic CSI](https://github.com/democratic-csi/democratic-csi)
to provide persistent storage for Kubernetes from TrueNAS SCALE using NFS.

**Based on**: [TrueNAS backed PVCs on Talos Kubernetes using Democratic CSI](https://wazaari.dev/blog/truenas-talos-democratic-csi)

### How it works

1. **Driver configuration** is stored in a Kubernetes secret (`truenas-nfs-driver-config`) that contains TrueNAS API credentials
2. **Helm chart** is deployed via ArgoCD and references the pre-created secret
3. **ArgoCD syncs automatically** when you push changes to the git repository
4. **Secret is managed manually** and kept out of git for security

## Files

| File | Purpose | In Git? |
|------|---------|---------|
| `Chart.yaml` | Helm chart wrapper (pins democratic-csi version) | ✅ Yes |
| `values.yaml` | Helm values (references external secret) | ✅ Yes |
| `truenas-nfs-driver-config.yaml` | Secret with API key and driver config | ❌ No (gitignored) |
| `deploy-secret.sh` | Helper script to deploy the secret | ✅ Yes |
| `test-pvc-pod.yaml` | Test manifest to verify CSI functionality | ✅ Yes |
| `.gitignore` | Prevents secrets from being committed | ✅ Yes |

## Prerequisites

### TrueNAS SCALE Setup

1. **NFS Service**
   - Enable NFSv3 in System → Services → NFS
   - Configure to start on boot
   - Bind to appropriate network interface

2. **Datasets**
   - Create `tank/k8s-pvs` for volumes
   - Create `tank/k8s-pvs-snapshots` for snapshots
   - Do NOT share these manually (democratic-csi will manage child datasets)

3. **API Key**
   - Create user with Local Administrator privileges
   - Generate API key in Credentials → API Keys
   - Update `truenas-nfs-driver-config.yaml` with the key

### Kubernetes Setup

1. **Snapshot Controller** (already installed via ArgoCD)
   - Required for volume snapshot support
   - Check: `kubectl get deploy -n kube-system snapshot-controller`

2. **Namespace labels** (if using pod security policies)

   ```bash
   kubectl label namespace democratic-csi pod-security.kubernetes.io/enforce=privileged
   ```

## Deployment

### Step 1: Apply the Secret

The secret file `truenas-nfs-driver-config.yaml` exists locally but is gitignored.
It contains your TrueNAS API key and configuration.

```bash
# Navigate to this directory
cd kubernetes/infrastructure/democratic-csi

# Apply the secret
./deploy-secret.sh

# Or manually:
kubectl apply -f truenas-nfs-driver-config.yaml

```

Verify the secret was created:

```bash
kubectl get secret truenas-nfs-driver-config -n democratic-csi

```


### Step 2: Sync ArgoCD

The ArgoCD application is already configured in `kubernetes/argocd-apps/infrastructure-apps.yaml`
and will automatically sync when you push to git.

Trigger an immediate sync:

```bash
# Sync the root app (which includes democratic-csi-nfs)
argocd app sync root-app

# Or sync just the democratic-csi app
argocd app sync democratic-csi-nfs

```

### Step 3: Verify Deployment

Wait for pods to be ready:

```bash
kubectl get pods -n democratic-csi -w

```

Expected output:

```text
NAME                                            READY   STATUS    RESTARTS   AGE
democratic-csi-nfs-controller-xxxxxxxxxx-xxxxx  6/6     Running   0          2m
democratic-csi-nfs-node-xxxxx                   4/4     Running   0          2m
democratic-csi-nfs-node-xxxxx                   4/4     Running   0          2m
democratic-csi-nfs-node-xxxxx                   4/4     Running   0          2m

```

Check storage class:

```bash
kubectl get sc truenas-nfs

```

Check volume snapshot class:

```bash
kubectl get volumesnapshotclass truenas-nfs

```

## Testing

Deploy a test PVC and pod:

```bash
kubectl apply -f test-pvc-pod.yaml

```

Watch the PVC bind:

```bash
kubectl get pvc -n democratic-csi-test -w

```

Exec into the test pod and create a file:

```bash
kubectl exec -it storage-test-pod -n democratic-csi-test -- sh
/ # echo "Hello from Kubernetes!" > /data/test.txt
/ # cat /data/test.txt
/ # exit

```

**Verify on TrueNAS**:

- Navigate to Datasets → you should see `tank/k8s-pvs/pvc-xxxxx`
- Navigate to Shares → NFS → you should see an NFS share for the PVC
- The share comment should show `democratic-csi-test-test-pvc`

Cleanup:

```bash
kubectl delete -f test-pvc-pod.yaml

```

## Configuration Details

### Driver Settings

From `truenas-nfs-driver-config.yaml`:

| Setting | Value | Notes |
|---------|-------|-------|
| `driver` | `freenas-api-nfs` | TrueNAS SCALE API driver (no SSH) |
| `host` | `truenas.ghart.space` | TrueNAS hostname/IP |
| `protocol` | `https` | API protocol |
| `port` | `443` | HTTPS port |
| `allowInsecure` | `true` | Allow self-signed certificates |
| `datasetParentName` | `tank/k8s-pvs` | Parent dataset for volumes |
| `detachedSnapshotsDatasetParentName` | `tank/k8s-pvs-snapshots` | Parent for snapshots |
| `datasetPermissionsUser` | `4000` | UID for dataset ownership |
| `datasetPermissionsGroup` | `4000` | GID for dataset ownership |
| `shareHost` | `truenas.ghart.space` | NFS server hostname for mounts |

### Storage Class Settings

From `values.yaml`:

| Setting | Value | Notes |
|---------|-------|-------|
| `name` | `truenas-nfs` | Storage class name |
| `reclaimPolicy` | `Delete` | Delete volumes when PVC is deleted |
| `volumeBindingMode` | `Immediate` | Bind immediately when PVC is created |
| `allowVolumeExpansion` | `true` | Allow resizing volumes |
| `mountOptions` | `noatime,nfsvers=3,nolock` | NFS mount options |

### Important Notes

1. **NFSv3 vs NFSv4**: The guide recommends NFSv3 (`nfsvers=3`) for compatibility
2. **`next` image tag**: Uses latest democratic-csi image with TrueNAS 24.04+ fixes
3. **`nolock` option**: Required for proper NFS operation with democratic-csi
4. **Detached snapshots**: Enabled to avoid dependency on parent volume

## Updating

### Update API Key

1. Edit `truenas-nfs-driver-config.yaml` (local file)
2. Apply the secret: `kubectl apply -f truenas-nfs-driver-config.yaml`
3. Restart the controller: `kubectl rollout restart deployment democratic-csi-nfs-controller -n democratic-csi`

### Update Chart Version

1. Edit `Chart.yaml` and bump the `version` under `dependencies`
2. Commit and push to git
3. ArgoCD will auto-sync the changes

### Update Helm Values

1. Edit `values.yaml`
2. Commit and push to git
3. ArgoCD will auto-sync the changes

## Troubleshooting

### Controller CrashLoopBackOff

Check logs:

```bash
kubectl logs -n democratic-csi deployment/democratic-csi-nfs-controller -c csi-driver

```

Common issues:

- Secret not created or misconfigured
- TrueNAS API unreachable
- Invalid API key
- Datasets don't exist on TrueNAS

### PVC Stuck in Pending

Check events:

```bash
kubectl describe pvc <pvc-name> -n <namespace>

```

Check provisioner logs:

```bash
kubectl logs -n democratic-csi deployment/democratic-csi-nfs-controller -c csi-provisioner

```

### Mount Failures

Check node logs:

```bash
kubectl logs -n democratic-csi daemonset/democratic-csi-nfs-node -c csi-driver

```

Verify NFS service is running on TrueNAS and shares are created.

## Resources

- [Democratic CSI Documentation](https://github.com/democratic-csi/democratic-csi)
- [Wazaari Guide (basis for this setup)](https://wazaari.dev/blog/truenas-talos-democratic-csi)
- [TrueNAS SCALE Documentation](https://www.truenas.com/docs/scale/)
- [Kubernetes CSI Documentation](https://kubernetes-csi.github.io/docs/)
