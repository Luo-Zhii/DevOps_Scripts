#!/bin/bash
# Description: Prepare the control node with Ansible and Kubespray dependencies

set -e

log_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }

log_info "Installing Python3 and Pip..."
sudo apt update -qq && sudo apt install -y python3-pip python3-venv git -qq

log_info "Creating Virtual Environment for Kubespray..."
python3 -m venv venv
source venv/bin/activate

log_info "Cloning Kubespray repository..."
if [ ! -d "kubespray" ]; then
    git clone https://github.com/kubernetes-sigs/kubespray.git
fi

log_info "Installing Kubespray dependencies (Ansible included)..."
cd kubespray
pip install -r requirements.txt

log_info "Ansible and Kubespray environment ready!"