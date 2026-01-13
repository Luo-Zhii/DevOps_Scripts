#!/bin/bash
# ==============================================================================
# Script Name   : setup_infrastructure.sh
# Description   : Prepares the Nginx Host (Install packages, Global Log, Security)
# Usage         : sudo bash setup_infrastructure.sh
# ==============================================================================

set -e  # Exit on error

# --- [GLOBAL VARIABLES & LOGGING] ---
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

# --- [FUNCTION 1: PRE-FLIGHT CHECKS] ---
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Please run as root (sudo)."
        exit 1
    fi
}

# --- [FUNCTION 2: INSTALLATION] ---
install_dependencies() {
    log_info "Updating system and installing dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq 
    apt-get install -y nginx certbot python3-certbot-nginx ufw curl -qq > /dev/null
    
    systemctl enable nginx
    systemctl start nginx
    log_info "Nginx & Certbot installed."
}

# --- [FUNCTION 3: GLOBAL CONFIGURATION] ---
configure_logging() {
    log_info "Configuring Global JSON Logging Format..."
    cat > /etc/nginx/conf.d/logging.conf << 'EOF'
log_format json_analytics escape=json '{'
    '"time_local":"$time_local",'
    '"remote_addr":"$remote_addr",'
    '"request":"$request",'
    '"status": "$status",'
    '"body_bytes_sent":"$body_bytes_sent",'
    '"request_time":"$request_time",'
    '"http_user_agent":"$http_user_agent",'
    '"upstream_response_time":"$upstream_response_time"'
'}';
EOF
}

# --- [FUNCTION 4: SECURITY HARDENING] ---
harden_security() {
    log_info "Applying Security Hardening..."
    
    # Firewall Rules
    ufw allow 'Nginx Full' > /dev/null
    ufw allow 'OpenSSH' > /dev/null
    
    # Hide Nginx Version
    sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf
    
    # Clean default site
    rm -f /etc/nginx/sites-enabled/default
}

# --- [MAIN EXECUTION FLOW] ---
main() {
    check_root
    install_dependencies
    configure_logging
    harden_security
    
    log_info "=== INFRASTRUCTURE SETUP COMPLETED ==="
    log_info "Server is ready to deploy sites using deploy_site.sh"
}

main