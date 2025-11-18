#!/bin/zsh

start_pwd=$(pwd)

# check if user is root, only then continue
if [ "$EUID" -ne 0 ]; then
  echo "[*] Please run as root"
  exit
fi

# GENERIC ALIASES
read -p "[*] Do you want to add aliases for impacket tools? (y/n): " add_aliases

if [[ "$add_aliases" == "y" ]]; then
    # Impacket aliases > add to .zshrc

    echo '
# Impacket tool aliases
for script in /usr/share/doc/python3-impacket/examples/*.py; do
    alias "$(basename $script)"="$script"
done' >> ~/.zshrc

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
    read -p "Do you want to add Bloodhound aliases? (y/n): " install_bloodhound
    if [[ "$install_bloodhound" == "y" ]]; then

        # create an alias 'bloodhound-ce' for starting the containers command
        echo "alias bloodhound-ce='docker-compose -f $start_pwd/assets/bloodhound/docker-compose.yml up'" >> ~/.zshrc
        echo "alias bloodhound-ce-stop='docker-compose -f $start_pwd/assets/bloodhound/docker-compose.yml stop'" >> ~/.zshrc
        echo "alias bloodhound-ce-reset='docker-compose -f $start_pwd/assets/bloodhound/docker-compose.yml down && docker-compose -f $start_pwd/assets/bloodhound/docker-compose.yml up'" >> ~/.zshrc
        echo "[*] Added bloodhound-docker aliases."

    else
        echo "[*] Skipping BloodHound Docker aliases."
    fi


else
    echo "[*] Skipping Docker installation."
fi
echo $start_pwd
# RESOURCES
read -p "Do you want to retrieve all neccessary resources? (y/n): " clone_resources
if [[ "$clone_resources" == "y" ]]; then
     mkdir -p /opt/resources
     cp assets/tools/* /opt/resources
     echo "[*] Resources copied to /opt/resources, now starting to clone..."

     # Clone various repositories
     cd /opt/resources
     bash /opt/resources/update-resources.sh
     cd $start_pwd
     echo "[*] All resources cloned."

else
    echo "[*] Skipping resource retrieval."
fi

# add ALIAS for the 'killall prldnd' command
echo "alias click='killall prldnd'" >> ~/.zshrc

# add tmux.conf to current user
cp assets/tmux/tmux.conf ~/.tmux.conf

echo "[*] FINISHED SETUP."
echo "[*] Configuration complete. Please restart your terminal or run 'source ~/.zshrc' to apply changes."

