# collective-homelab-stacks

A collection of homelab docker files, k8s manifest, and anisble playbooks.

## Organization

Each grouping of software is in its own folder under the this root folder. Some of these projects, like finance are only one applicaiton. Most of these folders are only just a simple docker compose.

## Monitoring

All of the monitoring services (things which I want to talk to promethesus or grafana) get added to `monitoring-network`.

## Portainer

Portainer has this nice feature to define ENVs when you make a stack that are outside of your compose file but can still be used by your services. I am trying to use a gitops still workflow as much as possible, so I want everything to be tracked by git. I don't want to manually put things into portainer. The only thing portainer should do it pull from my github. However, in regards to passwords, many services which are "dockerized" want you to supply a password or other critical information via ENV. If these are tracked with git then I have two options: make the repo private or publish my password to the internet. I don't like either of those. 

The problem was the ENV feature in portainer was not documented and I could not get it to work. I [finally found the portainer ENV docs](https://www.portainer.io/blog/using-env-files-in-stacks-with-portainer).

`NOTE: The stack.env file feature from the above docs still does note work. But the individual variables do.`

## TODO

- no todo :)
