#!/usr/bin/env bash
set -euo pipefail

# Install Kubernetes components for a GPU node using offline packages.
# Only kubelet and kubectl are installed. kubeadm support has been removed.

PKG_DIR="${1:-k8s_offline_pkgs}"
if [[ ! -d "$PKG_DIR" ]]; then
    echo "Package directory $PKG_DIR not found" >&2
    exit 1
fi

sudo apt-get install -y "$PKG_DIR"/kubelet_* "$PKG_DIR"/kubectl_*

sudo systemctl enable --now kubelet
