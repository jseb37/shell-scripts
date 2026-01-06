#!/bin/sh
set -eu

SERVICE="$1"

if [ -z "$SERVICE" ]; then
  echo "Usage: $0 <service-name>"
  exit 3
fi

echo "Checking service: $SERVICE"

# 1️⃣ systemd systems
if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet "$SERVICE"; then
    echo "✅ $SERVICE is RUNNING (systemd)"
    exit 0
  else
    echo "❌ $SERVICE is NOT running (systemd)"
    exit 2
  fi
fi