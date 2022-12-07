#!/usr/bin/env bash

# ---------------------------------------------------------------------------------
# Purpose - Script to get started with a new user and basic docker stuff on a fresh
#           debian based distro
# Author  - @darchap
# ---------------------------------------------------------------------------------

useradded=0
userscript="./1-user.sh"

# Exit on error
set -e

function error() {
    echo -e "\n\e[91m$1\e[97m"
}

function success() {
    echo -e "\n\e[92m$1\e[97m"
}

function timeout_reboot() {
    echo -e "\nRebooting in 20 seconds for the changes to take effect."
    echo -e "You may press Ctrl+C now to abort this script."
    sleep 20
    reboot
}

function check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        error "This installer needs to be run with superuser privileges."
        exit 1
    fi
}

function check_ssh_root() {
    echo -e 'Checking if you have root access trhough SSH...'
    if grep -q '^PermitRootLogin.yes' /etc/ssh/sshd_config; then
        read -rp 'You have enabled root login through SSH, do you wish to disable it now?[y/n]: ' yn
        case $yn in
        [Yy]*) sudo sed -i '/PermitRootLogin/c\#PermitRootLogin no' /etc/ssh/sshd_config ;;
        [Nn]*) echo -e "\e[5mIs strongly advised to disable root login! \e[25m\n" ;;
        *) echo "Please answer yes or no." ;;
        esac
    else
        echo 'All OK!'
    fi
}

function check_ssh_port() {
    echo -e 'Checking your SSH port...'
    if grep -q '#Port 22' /etc/ssh/sshd_config; then
        read -rp 'It seems that your SSH port is the default one, do you wish to change it now?[y/n]: ' yn
        case $yn in
        [Yy]*)
            read -rp 'Enter your desired SSH port: ' port
            sudo sed -i "/#Port 22/c\Port $port" /etc/ssh/sshd_config
            ;;
        [Nn]*) echo -e "\e[5mIs strongly advised to change your SSH default port! \e[25m\n" ;;
        *) echo "Please answer yes or no." ;;
        esac
    else
        echo 'All OK!'
    fi
}

function check_distro() {
    case $(lsb_release -i | awk '{print $3}') in
    *[Dd]ebian*) ;;
    *[Uu]buntu*) ;;
    *[Rr]aspbian*) ;;
    *)
        error "Not supported distro."
        exit 1
        ;;
    esac
}

function add_user() {
    echo -e "\n======================================="
    while true; do
        read -rp "Do you wish to add a non-root user?[y/n]: " yn
        case $yn in
        [Yy]*)
            while true; do
                read -rp "Please enter username: " username
                if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]; then
                    break
                fi
                error "Not a valid username."
            done
            while true; do
                read -rps "Please enter password: " password
                echo
                read -rps "Repeat password: " password2
                if [[ $password = "$password2" ]]; then
                    break
                else
                    error "Passwords dont match."
                fi
            done
            if id "$username" &>/dev/null; then
                error "$username already exists!"
            else
                pass=$(perl -e 'print crypt($ARGV[0], "password")' "$password")
                if useradd -s /bin/bash -d /home/"$username"/ -m -G sudo -p "$pass" "$username"; then
                    success -e "\nUser has been added to system!"
                    useradded=1
                else
                    error "Failed to add a user!"
                    exit 1
                fi
            fi
            break
            ;;
        [Nn]*)
            while true; do
                read -rp "Please enter a non-root username: " username
                if [[ $username = root ]]; then
                    error "Not a valid username."
                fi
                if ! id "$username" &>/dev/null; then
                    error "$username does not exist!"
                else
                    useradded=1
                    break
                fi
            done
            break
            ;;
        *) echo "Please answer yes or no." ;;
        esac
    done
    echo -e "=======================================\n"
}

# 0 Check root user and os
check_root
check_distro

# 1 Prompt to add new user
add_user

# 2 Install docker, watchtower and portainer as user and then reboot
if [[ $useradded -eq 1 ]]; then
    if [[ $(grep "^$username.*ALL=(ALL).*NOPASSWD:.*ALL" /etc/sudoers) ]]; then
        sudo -u "$username" bash $userscript
    elif [[ $(grep "^$username.*ALL=(ALL)" /etc/sudoers) ]]; then
        sed -i "/^$username ALL=(ALL)/d" /etc/sudoers
        echo "$username ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers >/dev/null
        sudo -u "$username" bash $userscript
        sed -i "s/^$username ALL=(ALL).*/$username ALL=(ALL)/" /etc/sudoers
    else
        echo "$username ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers >/dev/null
        sudo -u "$username" bash $userscript
    fi
    if [[ $? -eq 0 ]]; then
        echo '\e[4mSSH (changes will take effect on next boot).\e[24m'
        check_ssh_root
        check_ssh_port
        timeout_reboot
    else
        echo "Cant finish the install."
    fi
fi
