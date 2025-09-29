# Kubernetes GitOps Setup

This directory contains the Kubernetes manifests and ArgoCD applications for the homelab cluster.

## Directory Structure

```
kubernetes/
├── infrastructure/          # Core infrastructure services
│   ├── cert-manager/       # Let's Encrypt certificates
│   └── monitoring/         # Prometheus, Grafana, AlertManager
├── applications/           # Homelab applications
│   └── media-server/       # Plex media server example
└── argocd-apps/           # ArgoCD Application definitions
    ├── root-app.yaml      # Root app (App of Apps pattern)
    └── infrastructure-apps.yaml  # Infrastructure applications
```

## Deployment Order

1. **Run Ansible playbooks** to set up K3s, Longhorn, ArgoCD, and cert-manager
2. **Apply the root application** to bootstrap ArgoCD:
   ```bash
   kubectl apply -f kubernetes/argocd-apps/root-app.yaml
   ```
3. **Configure DNS** for your services (*.ghart.space pointing to your cluster)
4. **Access services**:
   - ArgoCD: https://argocd.ghart.space
   - Grafana: https://grafana.ghart.space
   - Prometheus: https://prometheus.ghart.space

## Adding New Applications

1. Create a new directory under `applications/` or `infrastructure/`
2. Add `Chart.yaml` (for Helm-based apps) or raw YAML manifests
3. Add `values.yaml` for Helm chart customization
4. ArgoCD will automatically sync new applications

## Configuration Notes

- **Storage**: All persistent volumes use Longhorn storage class
- **SSL**: Automatic Let's Encrypt certificates via cert-manager
- **Ingress**: Traefik (built into K3s) with automatic HTTPS
- **DNS**: Configure *.ghart.space to point to your cluster IP
- **Media Storage**: Large media files should use TrueNAS NFS/iSCSI mounts

## Customization

- Update email addresses in `cert-manager/cluster-issuers.yaml`
- Change domain from `ghart.space` to your own domain
- Adjust resource limits in `values.yaml` files
- Modify node selectors for applications that need specific nodes
