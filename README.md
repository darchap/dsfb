# Debian server first boot

This repository is a collection of scripts to automate my personal setup on any debian server instance at first boot. All of this is based on my needs so feel free to fit to yours.

### Usage
You just need to execute `0-runasroot.sh`
```
cd /home
git clone https://github.com/darchap/dsfb.git
cd dsfb
bash 0-runasroot.sh
```
This script will check if it's executed as root and if it's running on a debian based distro, otherwise it will exit. Then it will ask you to create a non-root user or pick an existing one to run the second script.

The second script will run with created/picked user id in order to install [Docker](https://www.docker.com/), [Portainer](https://github.com/portainer/portainer) and [Watchtower](https://github.com/containrrr/watchtower). If any of those are already installed, it will reinstall them without losing any data.
