# Democratic CSI - Manual Deployment

This directory contains the configuration for the Democratic CSI driver that provides NFS-based persistent storage from TrueNAS to the Kubernetes cluster.

**Note:** This application is managed **manually** outside of ArgoCD to avoid issues with secret management and API key rotation.

## Architecture

- **Driver**: `freenas-api-nfs` (TrueNAS SCALE API-based, no SSH required)
- **Storage Backend**: TrueNAS SCALE at `truenas.ghart.space`
- **Parent Dataset**: `tank/k8s-pvs`
- **Snapshots Dataset**: `tank/k8s-pvs-snapshots`
- **Storage Class**: `truenas-nfs` (NFSv4)
- **Reclaim Policy**: Retain (volumes are kept on TrueNAS after PVC deletion)

## Prerequisites

### 1. Kubernetes Cluster
Ensure all nodes have NFS client tools installed:

```bash
# On each node (assuming Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y nfs-common
```

### 2. TrueNAS Configuration

The following should already be configured on TrueNAS:

- **NFS Service**: Enabled with NFSv4 support
- **Datasets**:
  - `tank/k8s-pvs` - Parent dataset for volumes
  - `tank/k8s-pvs-snapshots` - Parent dataset for snapshots
- **API Key**: Valid API key with appropriate permissions
- **User/Group**: UID 4000, GID 4000 (configured in the values file)

### 3. Helm

Install Helm 3 if not already installed:

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Installation

### 1. Add Democratic CSI Helm Repository

```bash
helm repo add democratic-csi https://democratic-csi.github.io/charts/
helm repo update
```

### 2. Verify Configuration

The deployment configuration is in `democratic-csi-nfs-secret.yaml` (not committed to git). 

**Important settings to verify:**
- TrueNAS API endpoint and API key
- Dataset parent names match your TrueNAS configuration
- UID/GID match your TrueNAS user configuration

### 3. Deploy Democratic CSI

```bash
# From this directory
helm upgrade --install \
  --values democratic-csi-nfs-secret.yaml \
  --namespace democratic-csi \
  --create-namespace \
  democratic-csi-nfs \
  democratic-csi/democratic-csi
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods -n democratic-csi

# Check storage class
kubectl get storageclass truenas-nfs

# Check CSI driver
kubectl get csidriver org.democratic-csi.nfs

# Check volume snapshot class (if snapshots enabled)
kubectl get volumesnapshotclass truenas-nfs
```

Expected output:
- Controller pod should be running (1/1 READY)
- Node pods should be running on each node (4/4 READY)
- Storage class `truenas-nfs` should exist
- CSI driver `org.democratic-csi.nfs` should be registered

## Testing

### Create a Test PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs-claim
  namespace: default
spec:
  storageClassName: truenas-nfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
```

Apply and verify:

```bash
kubectl apply -f test-pvc.yaml
kubectl get pvc test-nfs-claim

# Should show STATUS: Bound
```

Check TrueNAS to verify:
- A new dataset was created under `tank/k8s-pvs`
- An NFS share was created for the dataset

### Create a Test Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-nfs-pod
  namespace: default
spec:
  containers:
  - name: test
    image: nginx:alpine
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: test-nfs-claim
```

Test writing to the volume:

```bash
kubectl apply -f test-pod.yaml
kubectl exec -it test-nfs-pod -- sh -c "echo 'Hello from NFS' > /data/test.txt"
kubectl exec -it test-nfs-pod -- cat /data/test.txt
```

Clean up:

```bash
kubectl delete pod test-nfs-pod
kubectl delete pvc test-nfs-claim
```

## Maintenance

### Upgrading Democratic CSI

```bash
# Update helm repository
helm repo update

# Check for new versions
helm search repo democratic-csi/democratic-csi

# Upgrade (from this directory)
helm upgrade \
  --values democratic-csi-nfs-secret.yaml \
  --namespace democratic-csi \
  democratic-csi-nfs \
  democratic-csi/democratic-csi
```

### Viewing Logs

```bash
# Controller logs
kubectl logs -n democratic-csi -l app.kubernetes.io/component=controller -c csi-driver

# Node logs (pick a specific node pod)
kubectl logs -n democratic-csi -l app.kubernetes.io/component=node -c csi-driver
```

### Checking Configuration

```bash
# View current Helm values
helm get values democratic-csi-nfs -n democratic-csi

# View all values (including defaults)
helm get values democratic-csi-nfs -n democratic-csi --all
```

### Rotating API Key

If you need to rotate the TrueNAS API key:

1. Generate a new API key in TrueNAS
2. Update `democratic-csi-nfs-secret.yaml` with the new key
3. Redeploy:

```bash
helm upgrade \
  --values democratic-csi-nfs-secret.yaml \
  --namespace democratic-csi \
  democratic-csi-nfs \
  democratic-csi/democratic-csi
```

## Uninstalling

**Warning:** Uninstalling will make existing PVs inaccessible. Make sure to backup data first!

```bash
# Delete the Helm release
helm uninstall democratic-csi-nfs -n democratic-csi

# Delete the namespace (if no longer needed)
kubectl delete namespace democratic-csi

# Manually clean up storage class and CSI driver if needed
kubectl delete storageclass truenas-nfs
kubectl delete csidriver org.democratic-csi.nfs
kubectl delete volumesnapshotclass truenas-nfs
```

**Note:** Due to the `Retain` reclaim policy, datasets on TrueNAS will NOT be automatically deleted. Clean them up manually if needed.

## Troubleshooting

### Pods Not Starting

Check events:
```bash
kubectl describe pod -n democratic-csi <pod-name>
```

Common issues:
- NFS client tools not installed on nodes
- API key invalid or expired
- Network connectivity to TrueNAS
- TrueNAS NFS service not running

### PVC Stuck in Pending

```bash
kubectl describe pvc <pvc-name>
```

Check:
- Controller pod is running
- Controller logs for errors
- TrueNAS API accessibility
- Dataset parent path exists in TrueNAS
- Sufficient space in the pool

### Mount Errors

```bash
kubectl describe pod <pod-name>
```

Check:
- Node pods are running on the affected node
- NFS service is running on TrueNAS
- Share was created correctly
- Firewall rules allow NFS traffic
- NFSv4 is enabled on TrueNAS

### API Connection Issues

Test API connectivity:
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -k -H "Authorization: Bearer YOUR_API_KEY" \
  https://truenas.ghart.space/api/v2.0/system/info
```

## Files in this Directory

- `Chart.yaml` - Helm chart dependencies (not used for manual deployment)
- `values.yaml` - Example/template values (not used, kept for reference)
- `truenas-api-key-secret.yaml` - Old secret file (not used, kept for reference)
- `democratic-csi-nfs-secret.yaml` - **Active configuration** (not in git, contains sensitive data)
- `README.md` - This file

## References

- [Democratic CSI GitHub](https://github.com/democratic-csi/democratic-csi)
- [Democratic CSI Helm Chart](https://github.com/democratic-csi/charts)
- [TrueNAS SCALE Documentation](https://www.truenas.com/docs/scale/)
- [Kubernetes CSI Documentation](https://kubernetes-csi.github.io/docs/)
