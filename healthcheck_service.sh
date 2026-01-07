#!/bin/bash
set -eo pipefail

SERVICE="$1"

if [ -z "$SERVICE" ]; then
  echo "Usage: $0 <service-name>"
  exit 3
fi

echo "Checking service: $SERVICE"

# 1️⃣ systemd systems
if command -v systemctl >/dev/null 2>&1; then

#command -v systemctl -> Prints the path or description of  command systemctl if it exists,Returns an exit code
#0 if it exists 1 if not found , Redirects stdout (file descriptor 1) to void(discard it completely).
#check if the systemctl command exist and is it executable in this environment?”
#2>&1 - > Redirect stderr (fd 2) to wherever stdout (fd 1) is currently going

  if systemctl is-active --quiet "$SERVICE"; then
    #  systemctl is-active
    #  Returns exit codes:
    #  0 → active
    #  3 → inactive
    #  4 → not found
    #  --quiet -> Suppresses output

    echo "✅ $SERVICE is RUNNING (systemd)"
    exit 0
  else
    echo "❌ $SERVICE is NOT running (systemd)"
    exit 2
  fi
fi