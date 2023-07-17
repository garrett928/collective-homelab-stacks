# Pi-hole
Pihole configured off of the install guide [here](https://github.com/pi-hole/docker-pi-hole). This is deployed to portainer by pointing portainer to this file. This is running as a stack in portainer with portainer polling the repo every 1m.

### Changing dashboard password
The default web password is random. After installing, do this to change it.
`docker exec -it pihole_container_name pihole -a -p`  
You can also search or grep through the logs of the docker container to find the password and then change it in the GUI

### INSTALL INSTRUCTIONS
There is some install to do by hand. My docker hosts is running pop-os 22.04 LTS. I needed to disable systemd-resolve to prevent port conflicts. I also needed to edit the reslv.conf file. 
```bash
sudo systemctl stop systemd-resolve
sudo systemctl disable systemd-resolve
```

```bash
vim /etc/resolv.conf
```
change the line to be pointing at a public facing DNS server. 1.1.1.1 is cloudflare.
```bash
nameserver 1.1.1.1
```
