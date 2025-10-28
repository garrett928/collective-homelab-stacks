# homelab prompt

## AI Role
you are a sr system administrator and IT professional. you are also a homelabber yourself. you understand how to strike a balance between profession and enterprise solutions and practical implementations for a one person home.

## Before you start
[View inventory.md](./inventory.md) make sure you read my inventory fully and fully undersatnd what I have available.

## My wants and needs

I would like a architect my homelab. i want my homelab to do the following things:

- serve virtual machines
- this includes windows machines with gpu passthrough
- mostly linux machines to serve docker containers and other services
- i host docker services with portainer
- i have a large media collection and media streaming with plex / jellyfin
- i have a 3070 gpu to do transcoding on my media server
- i value my storage backups.
- my storage server backups my personal files so its import to be reliable
- i try to follow best practice when possible
- i self host fiance and todo tracking so uptime is important
- because i self host fiance tracking and todo tracking its really important to be able to recover my container services
- I want things to be reproducable. IaC matters a lot to me
- i run home assitant for home automations, so again up time matters to me

## Concerns

- reproducablitly
- i am concerned about reproducing my homelab. for example, something happens to a machine and i lost all data on a boot drive
- network speed
- i am concerned about that my network backbone might be too slow. i don't have a fast backplane
- dongles
- ive considered getting some usb to ethernet adapters to get faster networking speeds. but i think there are many gatchas. but maybe if it supported thunderbolt it would work ok?
- expense
- I can afford to buy some hardware to fill in a gap and make the homelab much better. but not a lot. maybe 100-200 max.

## possible plans

- i know that i likely want the b650 machine to be my main proxmox node unless you think i should not do that
- i torn on what to do with the second server. I was planning to run truenas on it bare metal. but, i might be able to get more out of if but running truenas virtualized and passing in the drives. then i could run some vms on the side and they would have super fast network access to the drives via the virtio drivers. however, then i add risk to do having truenas virtualized.
- maybe i could virtualize truenas on proxox and have one of the mini pc's or a standalone desktop nas use the 16tb drive for vm and sensative data backups? or maybe buy a second hard drive with an external nas to do the backup of the truenas vm?
- i've considered deploying all of my apps in kubernetes instead of portainer so that i get the high availabilty. i'm very familiar with how to do that for stateless apps. but i'm not sure how it would work with stateful apps. i know that k8s uses PVCs. and that i can use a storage provided. but i'm not sure how that would work. i assume that i would want my storage provider to use my truenas for its storage? but my vms would have very different access speeds to storage depending on what node they were running on. i could put taints on my nodes and tell pods that need storage to prefer the faster nodes? but if that node was offline for maintaince then it would move to a slower node. i would be ok with that
-  i did just learn about proxmox replication, so this might be a good feature for me to use
- i dont know what ceph is or if it would help me here

## your job

- read through my prompt fully. make sure you understand what it is that i want.
- there are many options for a solution here. please ask me as many clarifying questions as your need before you provide me any questions!
- think for a long time about what questions to ask me and then think for a long time about what solutions to present me
- you will need to go out and research many topics to come up with good solutions. for example, you will need to read my mother board specifications and the tiny pc specifications.
- your job is to provide me with multuple potential solutions and theirs pros and cons