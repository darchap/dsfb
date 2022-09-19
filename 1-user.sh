#!/bin/bash

# ---------------------------------------------------------------------------------
# Purpose - Script to get started with a new user and basic docker stuff on a fresh
#           debian based distro
# Author  - @darchap
# ---------------------------------------------------------------------------------

function error() {
    echo -e "\n\\e[91m$1\\e[39m"
}

function check_internet() {
    printf "Checking if you are online..."
    wget -q --spider http://github.com
    if [ $? -eq 0 ]; then
        echo "Online. Continuing."
    else
        error "Offline. Go connect to the internet then run the script again."
    fi
}

function docker_install() {
    curl -sSL https://get.docker.com | sh || error "Failed to install Docker."
    sudo usermod -aG docker $USER || error "Failed to add user to the Docker usergroup."
}

function watchtower_install() {
    watchtower_pid=$(docker ps | grep watchtower | awk '{print $1}')
    watchtower_name=$(docker ps | grep watchtower | awk '{print $2}')

    if [[ containrrr/watchtower = $watchtower_name ]]; then
        sudo docker stop $watchtower_pid || error "Failed to stop Watchtower!"
        sudo docker rm $watchtower_pid || error "Failed to remove Watchtower container!"
        sudo docker rmi $watchtower_name || error "Failed to remove/untag images from the container!"
    fi
    sudo docker pull containrrr/watchtower || error "Failed to pull latest Watchtower docker image!"
    sudo docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock --restart unless-stopped containrrr/watchtower --schedule "0 0 4 * * *" --debug || error "Failed to run Watchtower docker image!"
}

function portainer_install() {

    portainer_pid=$(docker ps | grep portainer-ce | awk '{print $1}')
    portainer_name=$(docker ps | grep portainer-ce | awk '{print $2}')

    if [[ portainer/portainer-ce = $portainer_name ]]; then
        sudo docker stop $portainer_pid || error "Failed to stop Portainer!"
        sudo docker rm $portainer_pid || error "Failed to remove Portainer container!"
        sudo docker rmi $portainer_name || error "Failed to remove/untag images from the container!"
    fi
    sudo docker volume create portainer_data || error "Failed to create Portainer volume!"
    sudo docker pull portainer/portainer-ce || error "Failed to pull latest Portainer docker image!"
    sudo docker run -d -p 9000:9000 -p 9443:9443 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce || error "Failed to execute newer version of Portainer!"

}

# 0 Check internet connection
check_internet
# 1 Install Docker
docker_install
# 2 Install Watchtower
watchtower_install
# 3 Install Portainer
portainer_install
