# Media Stack Deployment

This directory contains Kubernetes manifests for deploying the Arr suite (Radarr, Sonarr, Prowlarr, Bazarr) and Transmission to my k3s cluster.

## Directory Structure

```
media-stack/
├── README.md
├── namespace.yaml
├── media-storage-pvc.yaml
├── media-secrets-template.yaml
├── bazarr/
│   ├── bazarr-pvc.yaml
│   ├── bazarr-deployment.yaml
│   ├── bazarr-service.yaml
│   └── bazarr-ingress.yaml
├── prowlarr/
│   ├── prowlarr-pvc.yaml
│   ├── prowlarr-deployment.yaml
│   ├── prowlarr-service.yaml
│   └── prowlarr-ingress.yaml
├── radarr/
│   ├── radarr-pvc.yaml
│   ├── radarr-deployment.yaml
│   ├── radarr-service.yaml
│   └── radarr-ingress.yaml
├── sonarr/
│   ├── sonarr-pvc.yaml
│   ├── sonarr-deployment.yaml
│   ├── sonarr-service.yaml
│   └── sonarr-ingress.yaml
└── transmission/
    ├── transmission-pvc.yaml
    ├── transmission-deployment.yaml
    ├── transmission-service.yaml
    └── transmission-ingress.yaml
```

## Applications Included

- **Bazarr**: Subtitle management (bazarr.ghart.space)
- **Prowlarr**: Indexer management (prowlarr.ghart.space)
- **Radarr**: Movie management (radarr.ghart.space)
- **Sonarr**: TV show management (sonarr.ghart.space)
- **Transmission**: BitTorrent client (transmission.ghart.space)

## Volume Structure

Following Servarr best practices, all containers use a shared `/data` volume to enable:
- Fast moves and hard links
- Consistent paths across all applications
- Optimal performance for seeding torrents

The volume structure within `/data` should be:
```
/data/
├── downloads/
│   └── torrents/     # Transmission downloads here
├── movies/           # Radarr manages movies here
└── tv/               # Sonarr manages TV shows here
```

## Deployment Steps

### 1. Create and Apply Secrets

Create a secrets files following the structure below. This file should be excluded from git and applied manually to the cluster with `kubectl apply -f media-secrets.yaml`.
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: media-secrets
  namespace: media
type: Opaque
stringData:
  # Replace with your actual values before applying
  TRANSMISSION_USERNAME: "admin"
  TRANSMISSION_PASSWORD: "your-secure-password-here"
```

### 2. Deploy via ArgoCD

The ArgoCD application is defined in `../argocd-apps/media-stack-app.yaml`. ArgoCD will automatically deploy all manifests in this directory.

### 3. Post-Deployment Configuration

1. **Access Prowlarr** at https://prowlarr.ghart.space
   - Configure your indexers
   - Note the API key for connecting other services

2. **Access Transmission** at https://transmission.ghart.space
   - Use the credentials from your secret
   - Configure download directory to `/data/downloads/torrents`

3. **Access Bazarr** at https://bazarr.ghart.space
   - Go to Settings > Languages
   - Configure your preferred subtitle languages
   - Go to Settings > Radarr
   - Add Radarr connection using URL: `http://radarr:7878`
   - Enter Radarr API key
   - Go to Settings > Sonarr
   - Add Sonarr connection using URL: `http://sonarr:8989`
   - Enter Sonarr API key

4. **Access Radarr** at https://radarr.ghart.space
   - Go to Settings > Media Management
   - Set Root Folder to `/data/movies`
   - Go to Settings > Indexers
   - Add Prowlarr as an indexer using service name: `http://prowlarr:9696`
   - Go to Settings > Download Clients
   - Add Transmission using host: `transmission` and port: `9091`
   - Set download directory to `/data/downloads/torrents`

5. **Access Sonarr** at https://sonarr.ghart.space
   - Go to Settings > Media Management
   - Set Root Folder to `/data/tv`
   - Go to Settings > Indexers
   - Add Prowlarr as an indexer using service name: `http://prowlarr:9696`
   - Go to Settings > Download Clients
   - Add Transmission using host: `transmission` and port: `9091`
   - Set download directory to `/data/downloads/torrents`

## Storage

- **Configuration volumes**: Each service has its own Longhorn PVC with ReadWriteMany access
- **Media storage**: For testing, a shared 10GB Longhorn volume mounted as `/data` in all services

## Network Communication

All services communicate internally via Kubernetes services:
- Bazarr: `bazarr:6767`
- Prowlarr: `prowlarr:9696`
- Transmission: `transmission:9091`
- Radarr: `radarr:7878`
- Sonarr: `sonarr:8989`
