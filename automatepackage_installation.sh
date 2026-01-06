#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="/var/log/package_install.log"
PACKAGES=("curl" "git" "vim" "htop" "net-tools")

echo "[$(date)] Starting package installation" | tee -a "$LOG_FILE"

# Must run as root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Run as root or with sudo" | tee -a "$LOG_FILE"
  exit 1
fi

# Update package index once
echo "Updating package index..." | tee -a "$LOG_FILE"
apt update -y >>"$LOG_FILE" 2>&1

for pkg in "${PACKAGES[@]}"; do
  if dpkg -s "$pkg" &>/dev/null; then
    echo "✅ $pkg already installed" | tee -a "$LOG_FILE"
  else
    echo "⬇️ Installing $pkg..." | tee -a "$LOG_FILE"
    apt install -y "$pkg" >>"$LOG_FILE" 2>&1
    echo "✔️ $pkg installed" | tee -a "$LOG_FILE"
  fi
done

echo "[$(date)] All packages processed successfully" | tee -a "$LOG_FILE"
