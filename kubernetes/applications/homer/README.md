# Homer Dashboard

Homer is a simple, static homepage for your homelab services.

## Services Tracked

This Homer dashboard provides quick access to all homelab services:

### Infrastructure
- **ArgoCD** - GitOps continuous delivery platform
- **Longhorn** - Distributed storage management

### Media Stack
- **Radarr** - Movie collection manager
- **Sonarr** - TV show collection manager
- **Prowlarr** - Indexer manager for Radarr/Sonarr
- **Bazarr** - Subtitle management for movies and TV shows
- **Transmission** - BitTorrent download client (via VPN)

### Applications
- **YourSpotify** - Personal Spotify statistics and analytics

## Access

The dashboard is available at: https://homer.ghart.space

## Configuration

The dashboard configuration is stored in `configmap.yaml`. To add new services:

1. Edit `configmap.yaml`
2. Add the service under the appropriate category
3. Commit and push changes
4. ArgoCD will automatically sync the changes

## Service Format

```yaml
- name: "Service Name"
  logo: "https://url-to-logo.png"
  subtitle: "Service Description"
  tag: "category"
  url: "https://service.ghart.space"
  target: "_blank"
```

## Deployment

This application is deployed via ArgoCD using the `homer-app.yaml` application manifest.

## Resources

- Official Homer: https://github.com/bastienwirtz/homer
- Docker Image: b4bz/homer
