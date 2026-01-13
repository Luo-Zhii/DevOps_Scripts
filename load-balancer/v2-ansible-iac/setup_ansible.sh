#!/bin/bash
# ==============================================================================
# Script Name   : setup_ansible_controller.sh
# Description   : Sets up a lightweight Ansible Control Environment (Python venv).
# Usage         : Run this on your LAPTOP or MANAGEMENT SERVER (Control Node).
#                 DO NOT run this on the target Load Balancer server.
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status

# Color codes for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- [Step 1] Installing System Dependencies (Python, pip, sshpass) ---${NC}"
# sshpass is included to allow password-based SSH auth if keys are not set up
sudo apt update -qq && sudo apt install -y python3-pip python3-venv sshpass -qq

echo -e "${GREEN}--- [Step 2] Creating Python Virtual Environment (Isolation) ---${NC}"
# Remove existing venv to ensure a clean installation
rm -rf venv
python3 -m venv venv

# Activate the virtual environment for the next steps
source venv/bin/activate

echo -e "${GREEN}--- [Step 3] Installing Ansible Core ---${NC}"
# Install standard Ansible core inside the virtual environment
pip install ansible

echo -e "${GREEN}=== SETUP COMPLETED ===${NC}"
echo "To start using Ansible, run this command:"
echo "source venv/bin/activate"