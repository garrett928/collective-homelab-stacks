# Setup monitoring network
Everything which wants to talk to promethesus needs to be added to the `monitoring-network` network in docker. This network needs to be created outside of docker compose. 

# XCP-NG Prometheus Exporter
I'm using an exporter for XCP-NG from this repo, https://github.com/MikeDombo/xen-exporter.
