#!/usr/bin/env bash
set -euo pipefail
usage() {
    echo "Usage: $0 [output_dir]" >&2
    echo "Downloads kubelet and kubectl deb packages for offline installation." >&2
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    usage
    exit 0
fi


# This script downloads kubelet and kubectl packages for GPU-enabled
# clusters running on Ubuntu 22.04. It automatically selects the
# latest accessible Kubernetes repository and does not include kubeadm.

OUTPUT_DIR="${1:-k8s_offline_pkgs}"
mkdir -p "$OUTPUT_DIR"

# Determine latest accessible Kubernetes repository for Ubuntu 22.04.
# Start with the current stable version and fall back to older ones if needed.
STABLE_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt | cut -d. -f1,2)
VERSIONS=("$STABLE_VER" v1.30 v1.29 v1.28 v1.27)
KUBE_REPO=""
for ver in "${VERSIONS[@]}"; do
    if curl -fsI "https://pkgs.k8s.io/core:/stable:/${ver}/deb/Release" >/dev/null; then
        KUBE_REPO="https://pkgs.k8s.io/core:/stable:/${ver}/deb/"
        echo "Using Kubernetes repo: $KUBE_REPO"
        break
    fi
done

if [ -z "$KUBE_REPO" ]; then
    echo "No available Kubernetes repository found" >&2
    exit 1
fi

sudo mkdir -p /etc/apt/keyrings
curl -fsSL "${KUBE_REPO}Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] ${KUBE_REPO} /" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

sudo apt-get -y update

PACKAGES=(kubelet kubectl)

for pkg in "${PACKAGES[@]}"; do
    echo "Downloading $pkg ..."
    apt-get download "$pkg"
done

mv ./*.deb "$OUTPUT_DIR/"
echo "Offline packages saved to $OUTPUT_DIR"
