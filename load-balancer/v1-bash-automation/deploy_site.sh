#!/bin/bash
# ==============================================================================
# Script Name   : deploy_site.sh
# Description   : Deploys a new Nginx Vhost with SSL for a specific domain
# Usage         : sudo bash deploy_site.sh <DOMAIN> <EMAIL>
# Example       : sudo bash deploy_site.sh nginx.luo.io.vn admin@luo.io.vn
# ==============================================================================

set -e

# --- [GLOBAL VARIABLES] ---
DOMAIN=$1
EMAIL=$2
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

# --- [FUNCTION 1: INPUT VALIDATION] ---
validate_input() {
    if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
        log_error "Missing arguments."
        echo "Usage: $0 <domain_name> <email_address>"
        exit 1
    fi
    log_info "Starting deployment for domain: $DOMAIN"
}

# --- [FUNCTION 2: GENERATE CONFIG] ---
create_vhost_config() {
    log_info "Generating Nginx Configuration from Template..."
    
    # Sanitize domain for log filename (replace dots with underscores)
    LOG_NAME=${DOMAIN//./_} 
    
    cat > "/etc/nginx/sites-available/$DOMAIN.conf" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    # Using the Global JSON format defined in Infrastructure Setup
    access_log /var/log/nginx/${LOG_NAME}_access.json json_analytics;
    error_log /var/log/nginx/${LOG_NAME}_error.log;

    location / {
        # Mock Response (Replace with proxy_pass in production)
        default_type application/json;
        return 200 '{"status":"success", "domain":"$DOMAIN", "message":"Deployed via Enterprise Script"}';
        
        # proxy_pass http://localhost:8080;
    }
}
EOF
}

# --- [FUNCTION 3: ENABLE SITE] ---
enable_site() {
    log_info "Activating site..."
    ln -sf "/etc/nginx/sites-available/$DOMAIN.conf" "/etc/nginx/sites-enabled/"
    
    # Validate Nginx Syntax
    if nginx -t; then
        systemctl reload nginx
    else
        log_error "Nginx Config Syntax Error. Rolling back..."
        rm "/etc/nginx/sites-enabled/$DOMAIN.conf"
        exit 1
    fi
}

# --- [FUNCTION 4: SSL AUTO-PROVISION] ---
setup_ssl() {
    log_info "Requesting Let's Encrypt SSL Certificate..."
    
    if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect; then
        log_info "SSL Certificate Installed Successfully."
    else
        log_error "Certbot failed. Please check your DNS settings or Cloudflare SSL Mode."
        exit 1
    fi
}

# --- [MAIN EXECUTION FLOW] ---
main() {
    if [[ $EUID -ne 0 ]]; then log_error "Run as root."; exit 1; fi
    
    validate_input
    create_vhost_config
    enable_site
    setup_ssl
    
    log_info "=== DEPLOYMENT SUCCESSFUL ==="
    log_info "Site is live at: https://$DOMAIN"
}

main