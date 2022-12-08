#!/usr/bin/env bash

# ---------------------------------------------------------------------------------
# Purpose - Script to get started with a new user and basic docker stuff on a fresh
#           debian based distro
# Author  - @darchap
# ---------------------------------------------------------------------------------

function error() {
    echo -e "\n\e[91m$1\e[97m"
}

function success() {
    echo -e "\n\e[92m$1\e[97m"
}

function check_internet() {
    echo "Checking if you are online..."
    if wget -q --spider http://github.com; then
        echo "Online. Continuing."
    else
        error "Offline. Go connect to the internet then run the script again."
    fi
}

function docker_install() {
    curl -sSL https://get.docker.com | sh || error "Failed to install Docker."
    sudo usermod -aG docker "$USER" || error "Failed to add user to the Docker usergroup."
}

function watchtower_install() {
    watchtower_id=$(docker ps -a | grep watchtower | awk '{print $1}')
    watchtower_name=$(docker ps -a | grep watchtower | awk '{print $2}')

    if [[ containrrr/watchtower = "$watchtower_name" ]]; then
        echo -e 'Stopping Watchtower container...\n'
        docker stop "$watchtower_id" >/dev/null || error "Failed to stop Watchtower!"
        echo -e 'Removing Watchtower container...\n'
        docker rm "$watchtower_id" >/dev/null || error "Failed to remove Watchtower container!"
        echo -e 'Removing Watchtower image...\n'
        docker rmi "$watchtower_name" >/dev/null || error "Failed to remove/untag images from the container!"
    fi
    docker pull containrrr/watchtower >/dev/null || error "Failed to pull latest Watchtower docker image!"
    echo -e 'Downloading Watchtower image...\n'
    if docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock --restart unless-stopped containrrr/watchtower --schedule "0 0 4 * * *" --debug --cleanup; then
        success 'Watchtower container deployed\n'
    else
        error 'Failed to run Watchtower docker image!'
    fi
}

function portainer_install() {

    portainer_id=$(docker ps -a | grep portainer-ce | awk '{print $1}')
    portainer_name=$(docker ps -a | grep portainer-ce | awk '{print $2}')

    if [[ portainer/portainer-ce = "$portainer_name" ]]; then
        echo -e 'Stopping Portainer container...\n'
        docker stop "$portainer_id" >/dev/null || error "Failed to stop Portainer!"
        echo -e 'Removing Portainer container...\n'
        docker rm "$portainer_id" >/dev/null || error "Failed to remove Portainer container!"
        echo -e 'Removing Portainer image...\n'
        docker rmi "$portainer_name" >/dev/null || error "Failed to remove/untag images from the container!"
    fi
    echo -e 'Creating Portainer volume...\n'
    docker volume create portainer_data >/dev/null || error "Failed to create Portainer volume!"
    echo -e 'Downloading Portainer image...\n'
    docker pull portainer/portainer-ce >/dev/null || error "Failed to pull latest Portainer docker image!"
    if docker run -d -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce; then
        success 'Portainer container deployed\n'
    else
        error 'Failed to run Portainer docker image!'
    fi
}

# 0 Check internet connection
check_internet
# 1 Install Docker
if [ "$(command -v docker)" ]; then
    echo -e '\n'
    read -rp 'Docker already installed, do you wish to update Docker?[y/n]: ' yn
    case $yn in
    [Yy]*)
        docker_install
        ;;
    [Nn]*)
        sudo usermod -aG docker "$USER" || error "Failed to add user to the Docker usergroup."
        ;;
    *) echo 'Please answer yes or no.' ;;
    esac
    echo -e '\n'
else
    docker_install
fi
# 2 Install Watchtower
watchtower_install
# 3 Install Portainer
portainer_install
