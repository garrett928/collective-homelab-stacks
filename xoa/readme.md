# XOA (Xen Orchestra)
XOA is the primary way to manage the xcp-ng hypervisor, which is the hypervisor powering my homelab. I'm running XOA in docker using portainer, which runs in a VM inside of xcp-ng. 

I'm using [this docker hub](https://hub.docker.com/r/ronivay/xen-orchestra) repo for the docker container and instructions. It is community mantained. The [project github](https://github.com/ronivay/XenOrchestraInstallerUpdater) is linked as well. 

# XOA from source
By default the version of XOA that comes installed with xcp-ng is slightly limited and intended for support to be purchased for enterprise users. For homelab or small / non-ctrical business needs you can build XOA from source following their [offical docs](https://xen-orchestra.com/docs/installation.html#from-the-sources). The repo I linked above is a community project to make the manual install simplier (and in docker!). I used to install it directly in a VM but I now run it in docker compose. 
