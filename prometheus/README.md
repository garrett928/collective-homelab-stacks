# Prometheus Monitoring Stack

This stack includes Prometheus, Node Exporter, and cAdvisor for comprehensive monitoring.

## Network Architecture

- **Internal Network**: `prometheus-internal` - isolates monitoring components
- **External Access**: Only via Traefik reverse proxy
- **Metrics Endpoints**:
  - Prometheus UI: `https://prometheus.ghart.space`
  - Node Exporter metrics: `https://metrics.ghart.space/nodeexporter/metrics`  
  - cAdvisor metrics: `https://metrics.ghart.space/cadvisor/metrics`

## Security

- No direct port publishing - all traffic goes through Traefik
- Internal network prevents lateral movement between containers
- Metrics endpoints can be secured with Traefik middleware (auth, IP restrictions, etc.)


