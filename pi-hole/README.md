# Pi-hole
Pihole configured off of the install guide [here](https://github.com/pi-hole/docker-pi-hole). This is deployed to portainer by pointing portainer to this file. This is running as a stack in portainer with portainer polling the repo every 1m.

### Changing dashboard password
The default web password is random. After installing, do this to change it.
`docker exec -it pihole_container_name pihole -a -p`
