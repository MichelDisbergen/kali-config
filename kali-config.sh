#!/bin/zsh

start_pwd = $(pwd)

# check if user is root, only then continue
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# GENERIC ALIASES
read -p "Do you want to add aliases for impacket tools? (y/n): " add_aliases

if [[ "$add_aliases" == "y" ]]; then
    # Impacket aliases
    for script in /usr/share/doc/python3-impacket/examples/*.py; do
        alias "$(basename $script)"="$script"
    done
    source ~/.zshrc
    echo "[*] Aliases for impacket tools added."
else
    echo "[*] Skipping alias addition for impacket tools."
fi

# FIREFOX
read -p "Do you want to add custom policies for Firefox? (y/n): " add_policies
if [[ "$add_policies" == "y" ]]; then
    mkdir -p /usr/lib/firefox/distribution
    cp assets/firefox/policies.json /usr/lib/firefox/distribution/policies.json
    echo "[*] Custom policies for Firefox added."
else
    echo "[*] Skipping Firefox policy addition."
fi

# DOCKER
read -p "Do you want to install Docker? (y/n): " install_docker
if [[ "$install_docker" == "y" ]]; then
    apt-get update -y
    apt-get install -y docker.io docker-compose
    systemctl start docker
    systemctl enable docker

    echo "[*] Docker installed and configured."

    # install bloodhound-docker
    read -p "Do you want to install BloodHound using Docker? (y/n): " install_bloodhound
    if [[ "$install_bloodhound" == "y" ]]; then
        # Clone the repository
        cd /opt
        git clone https://github.com/SpecterOps/BloodHound.git
        cd start_pwd

        # create an alias 'bloodhound-ce' for starting the containers command
        echo "alias bloodhound-ce='docker-compose -f /opt/my-resources/BloodHound/examples/docker-compose/docker-compose.yml up -d'" >> ~/.zshrc
        echo "alias bloodhound-ce-stop='docker-compose -f /opt/my-resources/BloodHound/examples/docker-compose/docker-compose.yml down'" >> ~/.zshrc
        echo "alias bloodhound-ce-reset='docker-compose -f /opt/my-resources/BloodHound/examples/docker-compose/docker-compose.yml down && docker-compose -f /opt/my-resources/BloodHound/examples/docker-compose/docker-compose.yml up -d'" >> ~/.zshrc
        source ~/.zshrc
    else
        echo "[*] Skipping BloodHound Docker installation."
    fi


else
    echo "[*] Skipping Docker installation."
fi

# RESOURCES
read -p "Do you want to retrieve all neccessary resources? (y/n): " clone_resources
if [["$clone_resources" == "y"]]; then
     mkdir -p /opt/resources
     cp assets/tools/* /opt/resources
     echo "[*] Resources copied to /opt/resources, now starting to clone..."

     # Clone various repositories
     bash /opt/resources/update-resources.sh
     echo "[*] All resources cloned."

else
    echo "[*] Skipping resource retrieval."
fi

# add ALIAS for the 'killall prldnd' command
echo "alias click='killall prldnd'" >> ~/.zshrc

# add tmux.conf to current user
cp assets/tmux/tmux.conf ~/.tmux.conf


