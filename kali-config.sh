#!/bin/zsh

set -e  # Exit on error

# Store initial directory
readonly START_PWD=$(pwd)
readonly ZSHRC="$HOME/.zshrc"

# Color codes for better output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${YELLOW}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[+]${NC} $1"; }
log_error() { echo -e "${RED}[-]${NC} $1"; }

# Prompt function with validation
prompt_yes_no() {
    local prompt="$1"
    local response
    while true; do
        echo -n -e "${YELLOW}[*]${NC} $prompt (y/n): "
        read response
        case "${response:l}" in  # :l converts to lowercase
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) log_error "Please answer 'y' or 'n'" ;;
        esac
    done
}

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Add content to zshrc if not already present
add_to_zshrc() {
    local content="$1"
    local marker="$2"
    
    if ! grep -q "$marker" "$ZSHRC" 2>/dev/null; then
        echo "$content" >> "$ZSHRC"
        return 0
    else
        log_info "Configuration already exists in .zshrc, skipping..."
        return 1
    fi
}

# Setup Impacket aliases
setup_impacket_aliases() {
    if prompt_yes_no "Do you want to add aliases for impacket tools?"; then
        local impacket_path="/usr/share/doc/python3-impacket/examples"
        
        if [[ ! -d "$impacket_path" ]]; then
            log_error "Impacket directory not found at $impacket_path"
            return 1
        fi
        
        local alias_config='
# Impacket tool aliases
for script in /usr/share/doc/python3-impacket/examples/*.py; do
    alias "$(basename $script)"="$script"
done'
        
        if add_to_zshrc "$alias_config" "# Impacket tool aliases"; then
            log_success "Aliases for impacket tools added"
        fi
    else
        log_info "Skipping impacket alias addition"
    fi
}

# Setup Firefox policies
setup_firefox_policies() {
    if prompt_yes_no "Do you want to add custom policies for Firefox?"; then
        local policy_dir="/usr/lib/firefox-esr/distribution"
        local policy_source="assets/firefox/policies.json"
        
        if [[ ! -f "$policy_source" ]]; then
            log_error "Policy file not found at $policy_source"
            return 1
        fi
        
        mkdir -p "$policy_dir"
        cp "$policy_source" "$policy_dir/policies.json"
        # Copy your CA cert to the system trust store
        sudo cp /root/kali-config/assets/firefox/burp/ca.crt /usr/local/share/ca-certificates/

        # Update the system CA certificates
        sudo update-ca-certificates
        log_success "Custom policies for Firefox added"
    else
        log_info "Skipping Firefox policy addition"
    fi
}

# Setup Docker (using official Docker repository)
setup_docker() {
    if prompt_yes_no "Do you want to install Docker?"; then
        apt install docker.io docker-compose -y

        # Start and enable Docker service
        systemctl start docker
        systemctl enable docker
        
        # Add current user to docker group
        if [[ -n "$SUDO_USER" ]]; then
            usermod -aG docker "$SUDO_USER"
            log_info "Added $SUDO_USER to docker group. Log out and back in for changes to take effect."
        fi
        
        log_success "Docker installed and configured"
    else
        log_info "Skipping Docker installation"
    fi
}

# Setup BloodHound Docker aliases (independent function)
setup_bloodhound_aliases() {
    if prompt_yes_no "Do you want to add BloodHound Docker aliases?"; then
        local compose_file="$START_PWD/assets/bloodhound/docker-compose.yml"
        
        if [[ ! -f "$compose_file" ]]; then
            log_error "BloodHound docker-compose.yml not found at $compose_file"
            return 1
        fi
        
        # Check if Docker is installed
        if ! command -v docker-compose &> /dev/null; then
            log_error "docker-compose is not installed. Please install Docker first."
            return 1
        fi
        
        local bloodhound_aliases="
# BloodHound Docker aliases
alias bloodhound-ce='docker-compose -f $compose_file up'
alias bloodhound-ce-stop='docker-compose -f $compose_file stop'
alias bloodhound-ce-reset='docker-compose -f $compose_file down && docker-compose -f $compose_file up'"
        
        if add_to_zshrc "$bloodhound_aliases" "# BloodHound Docker aliases"; then
            log_success "BloodHound Docker aliases added"
        fi
    else
        log_info "Skipping BloodHound Docker aliases"
    fi
}

# Clone resources
setup_resources() {
    if prompt_yes_no "Do you want to retrieve all necessary resources?"; then
        local resource_dir="/opt/resources"
        local tools_source="assets/tools"
        local update_script="$resource_dir/update-resources.sh"
        
        if [[ ! -d "$tools_source" ]]; then
            log_error "Tools directory not found at $tools_source"
            return 1
        fi
        
        mkdir -p "$resource_dir"
        cp -r "$tools_source"/* "$resource_dir/"
        log_success "Resources copied to $resource_dir"
        
        if [[ -f "$update_script" ]]; then
            log_info "Cloning repositories..."
            cd "$resource_dir"
            bash "$update_script"
            cd "$START_PWD"
            log_success "All resources cloned"
        else
            log_error "Update script not found at $update_script"
            return 1
        fi
    else
        log_info "Skipping resource retrieval"
    fi
}

# Setup utility aliases
setup_utility_aliases() {
    log_info "Adding utility aliases..."
    add_to_zshrc "alias click='killall prldnd'" "alias click="
    add_to_zshrc "alias bat='batcat'" "alias bat="
    log_success "Utility aliases added"
}

# Setup required_software
setup_required_software() {
    if prompt_yes_no "Do you want to install required software for: autorecon, pivoting and more?"; then
        log_info "Installing required software..."

        apt install seclists ligolo-ng sshuttle autorecon curl dnsrecon enum4linux feroxbuster gobuster nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g whatweb nikto mssqlpwner bat burpsuite caido faketime rdate rlwrap bloodyad -y
        pipx install pywhisker
        pipx ensurepath

        log_success "Required software installed and configured"
    else
        log_info "Skipping Docker installation"
    fi
}

# Setup tmux configuration
setup_tmux() {
    local tmux_source="assets/tmux/tmux.conf"
    local tmux_dest="$HOME/.tmux.conf"
    
    if [[ ! -f "$tmux_source" ]]; then
        log_error "Tmux config not found at $tmux_source"
        return 1
    fi
    
    cp "$tmux_source" "$tmux_dest"
    log_success "Tmux configuration added"
}

# Main execution
main() {
    log_info "Starting setup script..."
    
    check_root

    setup_docker
    setup_required_software
    setup_resources
    setup_tmux
    setup_impacket_aliases
    setup_utility_aliases
    setup_bloodhound_aliases
    setup_firefox_policies


    log_success "FINISHED SETUP"
    log_info "Configuration complete. Please restart your terminal or run 'source ~/.zshrc' to apply changes."
}

# Run main function
main "$@"
