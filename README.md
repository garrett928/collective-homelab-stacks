# collective-homelab-stacks
A collection of homelab / selfhosted sites that run in portainer as stacks.

# Organization
Each grouping of software is in its own folder under the this root folder. Some of these projects, like finance are only one applicaiton. Most of these folders are only just a simple docker compose.

# Monitoring
All of the monitoring services (things which I want to talk to promethesus or grafana) get added to `monitoring-network`. Note that the naming of this network might be a little odd. 

# TODO:

- Make the monitoring network truly external to any one stack so the name is not `promethesus_monitoring-network` and is instead `monitoring-network`
